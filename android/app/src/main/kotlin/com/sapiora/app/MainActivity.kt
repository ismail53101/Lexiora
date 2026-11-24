package com.sapiora.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.content.pm.PackageManager
import android.provider.MediaStore
import android.provider.OpenableColumns
import android.util.Log
import android.view.WindowManager
import androidx.core.content.FileProvider
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.pdmodel.graphics.state.PDExtendedGraphicsState
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native platform bridge for Sapiora (`lexiora/platform`).
 *
 * The channel id and package are kept as-is for backward compatibility; only
 * user-visible branding changed. The bridge exposes:
 *
 * *  - getSdkInt / setKeepScreenOn: small platform helpers.
 *  - getFirstInstallTime: epoch millis of the current install (Android
 *    PackageInfo), used to corroborate fresh-install detection before any
 *    stale-chat purge from a restored backup.
 *  - isExternalStorageManager: whether all-files access is granted (always true
 *    below API 30, where the storage permission covers broad reads).
 *  - scanAllPdfs: discovers every readable *.pdf on the device by combining two
 *    sources — a recursive filesystem walk AND a MediaStore query — and returns
 *    the de-duplicated union by absolute path (auto-discovery; files opened in
 *    place). The filesystem walk alone silently returns partial results on many
 *    OEM builds (MIUI, ColorOS, FuntouchOS, …) even with all-files access
 *    granted, because scoped-storage/FUSE enforcement varies by vendor; the
 *    MediaStore query is backed by the system's own indexed media database and
 *    is unaffected by that restriction, so combining both is far more reliable
 *    than either alone.
 *  - pickPdfs: opens the system file picker (multi-select) and copies the chosen
 *    PDFs into the app's private files dir, returning {path, name, size} for each
 *    (manual import).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "lexiora/platform"
    private val pickPdfsRequest = 0x5A11
    private val notificationPermissionRequest = 0x4E31
    private val storagePermissionRequest = 0x4E32
    private val notificationPermissionPrefs = "sapiora_permission_flow"
    private val notificationPermissionPromptedKey = "notification_prompted_v1"
    private val startupPermissionPrefs = "sapiora_permission_flow"
    private val allFilesPromptedKey = "all_files_prompted_v1"
    private var startupPermissionReady = false
    private var startupPermissionFlowStarted = false
    private val pendingStartupPermissionResults = ArrayList<MethodChannel.Result>()
    private var pendingResult: MethodChannel.Result? = null
    private var platformChannel: MethodChannel? = null
    private var pendingIncomingPdf: Map<String, Any?>? = null
    private var dartChannelReady = false

    // External PDF intents carry a content:// URI. FlutterActivity can
    // expose that URI as the engine's initial route; GoRouter would then show
    // its "Page Not Found" screen before our normal PDF-import flow handles it.
    // Keep navigation rooted in the app; processIncomingIntent() handles the
    // actual PDF separately.
    override fun getInitialRoute(): String {
        return "/splash"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Keep external PDF URIs out of Flutter's navigation layer. Otherwise
        // GoRouter can interpret content://... as an initial route and render
        // "Page Not Found" before the PDF import is handled.
        val incomingIntent = intent
        if (isExternalDocumentIntent(incomingIntent)) {
            setIntent(Intent(this, MainActivity::class.java))
        }

        super.onCreate(savedInstanceState)

        // Do not block the first Flutter/Home frame with system permission
        // dialogs. Dart starts this flow after Home has rendered once.
        processIncomingIntent(incomingIntent)
    }

    private fun requestNotificationPermissionOnFreshInstall() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                notificationPermissionRequest,
            )
            return
        }

        beginAllFilesAccessFlow()
    }

    private fun hasAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return true
        return Environment.isExternalStorageManager()
    }

    private fun beginAllFilesAccessFlow() {
        val prefs = getSharedPreferences(startupPermissionPrefs, MODE_PRIVATE)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (hasAllFilesAccess()) {
                prefs.edit().putBoolean(allFilesPromptedKey, true).apply()
                completeStartupPermissionFlow()
                return
            }

            try {
                val intent = Intent(
                    android.provider.Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName"),
                )
                startActivity(intent)
            } catch (e: Exception) {
                Log.w("Lexiora", "Could not open All Files Access settings: " + e.message)
                completeStartupPermissionFlow()
            }
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(
                arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE),
                storagePermissionRequest,
            )
            return
        }

        prefs.edit().putBoolean(allFilesPromptedKey, true).apply()
        completeStartupPermissionFlow()
    }

    private fun completeStartupPermissionFlow() {
        if (startupPermissionReady) return

        // Permissions must remain on a pure black launch surface. Only after
        // the user has finished the one-time permission flow do we reveal the
        // branded launch background. Flutter's first frame is still deferred,
        // so this logo remains visible while the engine/app finishes starting.
        window.setBackgroundDrawableResource(R.drawable.launch_brand_background)

        startupPermissionReady = true
        val pending = ArrayList(pendingStartupPermissionResults)
        pendingStartupPermissionResults.clear()
        pending.forEach { it.success(true) }
    }

    override fun onResume() {
        super.onResume()
        if (!startupPermissionReady &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            hasAllFilesAccess()
        ) {
            completeStartupPermissionFlow()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == notificationPermissionRequest) {
            getSharedPreferences(notificationPermissionPrefs, MODE_PRIVATE)
                .edit()
                .putBoolean(notificationPermissionPromptedKey, true)
                .apply()
            beginAllFilesAccessFlow()
        } else if (requestCode == storagePermissionRequest) {
            getSharedPreferences(startupPermissionPrefs, MODE_PRIVATE)
                .edit()
                .putBoolean(allFilesPromptedKey, true)
                .apply()
            completeStartupPermissionFlow()
        }
    }

    override fun onNewIntent(intent: Intent) {
        // Never hand the content:// URI to FlutterActivity/GoRouter.
        // Keep the current app route intact and process the PDF ourselves.
        val incomingIntent = intent
        if (isExternalDocumentIntent(incomingIntent)) {
            setIntent(Intent(this, MainActivity::class.java))
        } else {
            setIntent(incomingIntent)
        }
        super.onNewIntent(this.intent)
        processIncomingIntent(incomingIntent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platformChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        platformChannel!!
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestStartupPermissions" -> {
                        if (startupPermissionReady) {
                            result.success(true)
                        } else {
                            pendingStartupPermissionResults.add(result)
                            if (!startupPermissionFlowStarted) {
                                startupPermissionFlowStarted = true
                                requestNotificationPermissionOnFreshInstall()
                            }
                        }
                    }
                    "takeIncomingPdf" -> {
                        dartChannelReady = true
                        val incoming = pendingIncomingPdf
                        pendingIncomingPdf = null
                        result.success(incoming)
                    }
                    "finishExternalPdf" -> {
                        result.success(null)
                        finishAndRemoveTask()
                    }
                    "openWordFile" -> {
                        val path = call.argument<String>("path")
                        val mime = call.argument<String>("mime") ?: wordMimeFor(path)
                        if (path == null) { result.error("bad_args", "Missing path", null) }
                        else openWordFile(path, mime, result)
                    }
                    "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "getFirstInstallTime" -> result.success(
                        try {
                            packageManager.getPackageInfo(packageName, 0).firstInstallTime
                        } catch (e: Exception) {
                            0L
                        },
                    )
                    "setKeepScreenOn" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    "isExternalStorageManager" -> result.success(
                        hasAllFilesAccess(),
                    )
                    "openAllFilesAccessSettings" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            try {
                                startActivity(
                                    Intent(
                                        android.provider.Settings
                                            .ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                        Uri.parse("package:$packageName"),
                                    ),
                                )
                                result.success(true)
                            } catch (e: Exception) {
                                Log.w("Lexiora", "Could not open All Files Access settings: " + e.message)
                                result.error("settings_failed", e.message, null)
                            }
                        } else {
                            result.success(true)
                        }
                    }
                    "scanAllDocuments" -> scanAllDocuments(result)
                    "pickPdfs" -> startPickPdfs(result)
                    "recognizeText" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "Missing 'path'", null)
                        } else {
                            recognizeText(path, result)
                        }
                    }
                    "embedOcrText" -> {
                        val sourcePath = call.argument<String>("sourcePath")
                        val outputPath = call.argument<String>("outputPath")
                        val pages = call.argument<List<*>>("pages")
                        if (sourcePath == null || outputPath == null || pages == null) {
                            result.error("bad_args", "Missing sourcePath/outputPath/pages", null)
                        } else {
                            embedOcrText(sourcePath, outputPath, pages, result)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isExternalDocumentIntent(incoming: Intent?): Boolean {
        if (incoming == null) return false
        val action = incoming.action
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND) return false
        val uri = incoming.data ?: if (action == Intent.ACTION_SEND) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) incoming.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            else { @Suppress("DEPRECATION") incoming.getParcelableExtra(Intent.EXTRA_STREAM) }
        } else null
        val value = (incoming.type ?: "") + " " + (uri?.toString() ?: "")
        return incoming.type == "application/pdf" || incoming.type == "application/msword" ||
            incoming.type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
            value.lowercase().contains(".pdf") || value.lowercase().contains(".doc")
    }

    private fun wordMimeFor(path: String?): String =
        if (path?.lowercase()?.endsWith(".docx") == true) "application/vnd.openxmlformats-officedocument.wordprocessingml.document" else "application/msword"

    private fun openWordFile(path: String, mime: String, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(FileProvider.getUriForFile(this@MainActivity, "$packageName.fileprovider", File(path)), mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            if (intent.resolveActivity(packageManager) == null) { result.error("no_app", "No installed app can open this Word document", null); return }
            startActivity(intent); result.success(true)
        } catch (e: Exception) { result.error("open_failed", "Could not open Word document: ${e.message}", null) }
    }

    /** Copies an incoming content URI immediately, then notifies Dart with a
     * private, stable path. The reader never receives or assumes a raw URI. */
    private fun processIncomingIntent(incoming: Intent?) {
        if (incoming == null) return
        val action = incoming.action
        if (action != Intent.ACTION_VIEW && action != Intent.ACTION_SEND) return
        val uri: Uri? = incoming.data
            ?: if (action == Intent.ACTION_SEND) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    incoming.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    incoming.getParcelableExtra(Intent.EXTRA_STREAM)
                }
            } else null
        if (uri == null) return
        val sourceUri: Uri = uri
        val mime = incoming.type
        val lower = sourceUri.toString().lowercase()
        val supported = mime == null || mime == "application/pdf" || mime == "application/msword" ||
            mime == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" ||
            lower.endsWith(".pdf") || lower.endsWith(".doc") || lower.endsWith(".docx")
        if (!supported) return

        Thread {
            try {
                val dir = File(filesDir, "imported").apply { mkdirs() }
                val copied = copyToImported(sourceUri, dir, 0, externalIntent = true)
                if (copied == null) throw IllegalStateException("Could not read the selected document")
                runOnUiThread {
                    val channel = platformChannel
                    if (channel == null || !dartChannelReady) {
                        pendingIncomingPdf = copied
                    } else {
                        channel.invokeMethod("incomingPdf", copied)
                    }
                }
            } catch (e: Exception) {
                Log.w("Lexiora", "Incoming PDF import failed for $sourceUri: ${e.message}")
            }
        }.start()
    }

    // ── Manual import (system file picker, multi-select) ───────────────────────

    private fun startPickPdfs(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A file pick is already in progress.", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/pdf"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, pickPdfsRequest)
        } catch (e: Exception) {
            pendingResult = null
            result.error("pick_failed", e.message, null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickPdfsRequest) return
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, Any?>>()) // cancelled
            return
        }

        val uris = ArrayList<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) {
                clip.getItemAt(i)?.uri?.let { uris.add(it) }
            }
        } else {
            data.data?.let { uris.add(it) }
        }

        if (uris.isEmpty()) {
            result.success(emptyList<Map<String, Any?>>())
            return
        }

        Thread {
            val imported = ArrayList<Map<String, Any?>>()
            val dir = File(filesDir, "imported").apply { mkdirs() }
            var index = 0
            for (uri in uris) {
                try {
                    val copied = copyToImported(uri, dir, index++)
                    if (copied != null) imported.add(copied)
                } catch (e: Exception) {
                    Log.w("Lexiora", "Import copy failed for $uri: ${e.message}")
                }
            }
            Log.i("Lexiora", "Imported ${imported.size}/${uris.size} PDF(s)")
            runOnUiThread { result.success(imported) }
        }.start()
    }

    private fun copyToImported(
        uri: Uri,
        dir: File,
        index: Int,
        externalIntent: Boolean = false,
    ): Map<String, Any?>? {
        val displayName = queryDisplayName(uri) ?: "document_${System.currentTimeMillis()}.${if (externalIntent) "docx" else "pdf"}"
        val safeName = displayName.substringAfterLast('/').ifBlank { "document.pdf" }
        val extension = safeName.substringAfterLast('.', "pdf").lowercase()
        val dest = File(dir, "${System.currentTimeMillis()}_$index.$extension")
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { s -> dest.outputStream().use { o -> s.copyTo(o) } }
        return mapOf(
            "path" to dest.absolutePath,
            "name" to displayName,
            "size" to dest.length(),
            "mime" to (if (externalIntent) (if (extension == "docx") "application/vnd.openxmlformats-officedocument.wordprocessingml.document" else if (extension == "doc") "application/msword" else "application/pdf") else "application/pdf"),
            "externalIntent" to externalIntent,
        )
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { c ->
                    val idx = c.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0 && c.moveToFirst()) c.getString(idx) else null
                }
        } catch (e: Exception) {
            null
        }
    }

    // ── Automatic discovery (filesystem walk + MediaStore, merged) ─────────────

    private fun scanAllDocuments(result: MethodChannel.Result) {
        Thread {
            val out = ArrayList<Map<String, Any?>>()
            val seen = HashSet<String>()
            try {
                // MediaStore is Android's indexed file database. With
                // MANAGE_EXTERNAL_STORAGE granted, it is the reliable
                // fast path for discovering device PDFs. Do not recursively
                // walk storage here: that can keep the Library spinner busy
                // for a very long time on phones with large storage.
                queryMediaStorePdfs(out, seen)
                Log.i("Lexiora", "scanAllDocuments: found=" + out.size)
                runOnUiThread { result.success(out) }
            } catch (e: Exception) {
                Log.w("Lexiora", "scanAllDocuments failed: " + e.message)
                runOnUiThread { result.error("scan_all_failed", e.message, null) }
            }
        }.start()
    }

    /// Queries [MediaStore.Files] for every indexed `application/pdf` entry and
    /// appends the ones not already found by the filesystem walk (deduped by
    /// absolute path, via [seen]). Returns how many new entries were added.
    /// Any failure here (missing column, provider error, …) is swallowed — the
    /// filesystem walk's results are still returned — since this is a
    /// best-effort supplementary source, not the only one.
    private fun queryMediaStorePdfs(
        out: ArrayList<Map<String, Any?>>,
        seen: HashSet<String>,
    ): Int {
        var added = 0
        try {
            val collection = MediaStore.Files.getContentUri("external")
            val projection = arrayOf(
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.MIME_TYPE,
            )
            val selection =
                "${MediaStore.Files.FileColumns.MIME_TYPE} IN (?, ?, ?) OR " +
                    "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ? OR " +
                    "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ? OR " +
                    "${MediaStore.Files.FileColumns.DISPLAY_NAME} LIKE ?"
            val selectionArgs = arrayOf(
                "application/pdf",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "%.pdf",
                "%.doc",
                "%.docx",
            )
            val cursor: Cursor? = contentResolver.query(
                collection, projection, selection, selectionArgs, null,
            )
            cursor?.use { cur ->
                val dataIdx = cur.getColumnIndex(MediaStore.Files.FileColumns.DATA)
                val nameIdx = cur.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val sizeIdx = cur.getColumnIndex(MediaStore.Files.FileColumns.SIZE)
                val mimeIdx = cur.getColumnIndex(MediaStore.Files.FileColumns.MIME_TYPE)
                if (dataIdx < 0) return@use
                while (cur.moveToNext()) {
                    val path = cur.getString(dataIdx) ?: continue
                    if (path.isEmpty()) continue
                    val file = File(path)
                    if (!file.exists() || !file.canRead() || !seen.add(path)) continue
                    val name = if (nameIdx >= 0) cur.getString(nameIdx) else null
                    val mime = if (mimeIdx >= 0) cur.getString(mimeIdx) else null
                    val lower = (name ?: file.name).lowercase()
                    val supported = lower.endsWith(".pdf") || lower.endsWith(".doc") ||
                        lower.endsWith(".docx") || mime == "application/pdf" ||
                        mime == "application/msword" ||
                        mime == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                    if (!supported) { seen.remove(path); continue }
                    val size = if (sizeIdx >= 0) cur.getLong(sizeIdx) else file.length()
                    out.add(mapOf(
                        "path" to path,
                        "name" to (name ?: file.name),
                        "size" to size,
                        "mime" to (mime ?: ""),
                    ))
                    added++
                }
            }
        } catch (e: Exception) {
            Log.w("Lexiora", "MediaStore document query failed: ${e.message}")
        }
        return added
    }

    private fun walkPdfs(
        dir: File,
        out: ArrayList<Map<String, Any?>>,
        seen: HashSet<String>,
        depth: Int,
    ) {
        if (depth > 25) return
        val files = try { dir.listFiles() } catch (e: Exception) { null } ?: return
        for (f in files) {
            try {
                if (f.isDirectory) {
                    if (f.parentFile?.name == "Android" && (f.name == "data" || f.name == "obb")) continue
                    walkPdfs(f, out, seen, depth + 1)
                } else {
                    val lower = f.name.lowercase()
                    val supported = lower.endsWith(".pdf") || lower.endsWith(".doc") || lower.endsWith(".docx")
                    if (supported && f.canRead() && seen.add(f.absolutePath)) {
                        val mime = when {
                            lower.endsWith(".pdf") -> "application/pdf"
                            lower.endsWith(".docx") -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                            else -> "application/msword"
                        }
                        out.add(mapOf(
                            "path" to f.absolutePath,
                            "name" to f.name,
                            "size" to f.length(),
                            "mime" to mime,
                        ))
                    }
                }
            } catch (e: Exception) {
                Log.w("Lexiora", "walk skip ${f.absolutePath}: ${e.message}")
            }
        }
    }

    // ── On-device OCR (scanned/photographed PDF pages) ─────────────────────────

    /// Runs ML Kit's on-device Latin text recognizer over the image at [path]
    /// (a rendered PDF page) and returns every recognized word with its pixel
    /// bounding box, so the Dart side can lay a selectable overlay on top of
    /// the page at exactly the right positions. Runs off the UI thread —
    /// recognition of a full page can take a few hundred ms.
    ///
    /// This never touches the network: the Latin recognition model is bundled
    /// via Google Play Services and downloaded once on first use, after which
    /// every call is fully offline, free, and has no request quota.
    private fun recognizeText(path: String, result: MethodChannel.Result) {
        Thread {
            try {
                val bitmap = BitmapFactory.decodeFile(path)
                if (bitmap == null) {
                    runOnUiThread {
                        result.error("decode_failed", "Could not decode image: $path", null)
                    }
                    return@Thread
                }
                val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                try {
                    val image = InputImage.fromBitmap(bitmap, 0)
                    val visionText = Tasks.await(recognizer.process(image))
                    val words = ArrayList<Map<String, Any?>>()
                    for ((blockIndex, block) in visionText.textBlocks.withIndex()) {
                        for ((lineIndex, line) in block.lines.withIndex()) {
                            for (element in line.elements) {
                                val box = element.boundingBox ?: continue
                                words.add(
                                    mapOf(
                                        "text" to element.text,
                                        "left" to box.left,
                                        "top" to box.top,
                                        "right" to box.right,
                                        "bottom" to box.bottom,
                                        // Groups words back into their original line/reading
                                        // order on the Dart side, for phrase selection.
                                        "lineId" to "$blockIndex-$lineIndex",
                                    ),
                                )
                            }
                        }
                    }
                    runOnUiThread {
                        result.success(
                            mapOf(
                                "imageWidth" to bitmap.width,
                                "imageHeight" to bitmap.height,
                                "words" to words,
                            ),
                        )
                    }
                } finally {
                    recognizer.close()
                    bitmap.recycle()
                }
            } catch (e: Exception) {
                Log.w("Lexiora", "recognizeText failed for $path: ${e.message}")
                runOnUiThread { result.error("ocr_failed", e.message, null) }
            }
        }.start()
    }

    /// Writes an invisible text layer into [sourcePath]'s pages and saves the
    /// result to [outputPath] (never overwrites the original file in place —
    /// a failure partway through must never corrupt the user's own PDF).
    ///
    /// [pages] is `[{pageIndex: Int, words: [{text, left, top, right, bottom}]}]`
    /// where each word's box is normalized (0..1) against that page's size,
    /// with top=0 at the *top* of the page (screen-style — matches how the
    /// Dart side derives them from the OCR image).
    ///
    /// Each word is placed at invisible render mode 3 ("neither fill nor
    /// stroke" — the standard technique behind every "searchable scanned
    /// PDF" tool): nothing is drawn, but the text becomes selectable,
    /// searchable and copyable through pdfrx's existing, already-working
    /// text-selection system — no reader UI changes needed. A Helvetica glyph
    /// is horizontally scaled to exactly span the detected word's width, so
    /// the selectable region lines up with the visible word underneath even
    /// though Helvetica's own letterforms never exactly match the original.
    private fun embedOcrText(
        sourcePath: String,
        outputPath: String,
        pages: List<*>,
        result: MethodChannel.Result,
    ) {
        Thread {
            var document: PDDocument? = null
            try {
                PDFBoxResourceLoader.init(applicationContext)
                document = PDDocument.load(File(sourcePath))
                val font = PDType1Font.HELVETICA

                for (pageArg in pages) {
                    val pageMap = pageArg as? Map<*, *> ?: continue
                    val pageIndex = (pageMap["pageIndex"] as? Number)?.toInt() ?: continue
                    if (pageIndex < 0 || pageIndex >= document.numberOfPages) continue
                    val words = pageMap["words"] as? List<*>
                    if (words.isNullOrEmpty()) continue

                    val page = document.getPage(pageIndex)
                    val pageWidth = page.mediaBox.width
                    val pageHeight = page.mediaBox.height

                    val stream = PDPageContentStream(
                        document,
                        page,
                        PDPageContentStream.AppendMode.APPEND,
                        true,
                        true,
                    )
                    try {
                        // Make everything drawn on this stream fully
                        // transparent (alpha 0) — the text is written for
                        // real, selectable and searchable, but nothing is
                        // visibly painted over the scanned page image.
                        val invisible = PDExtendedGraphicsState()
                        invisible.setNonStrokingAlphaConstant(0f)
                        invisible.setStrokingAlphaConstant(0f)
                        stream.setGraphicsStateParameters(invisible)
                        for (wordArg in words) {
                            val w = wordArg as? Map<*, *> ?: continue
                            val text = (w["text"] as? String)?.trim() ?: continue
                            if (text.isEmpty()) continue
                            val left = (w["left"] as? Number)?.toDouble() ?: continue
                            val top = (w["top"] as? Number)?.toDouble() ?: continue
                            val right = (w["right"] as? Number)?.toDouble() ?: continue
                            val bottom = (w["bottom"] as? Number)?.toDouble() ?: continue

                            val boxWidthPt = ((right - left) * pageWidth).toFloat()
                            val boxHeightPt = ((bottom - top) * pageHeight).toFloat()
                            if (boxWidthPt <= 0f || boxHeightPt <= 0f) continue

                            // PDF space has its origin at the bottom-left; our boxes
                            // are top-origin fractions, so flip the Y axis. The
                            // baseline sits near the box's bottom edge.
                            val xPt = (left * pageWidth).toFloat()
                            val yPt = ((1.0 - bottom) * pageHeight).toFloat()

                            var fontSize = boxHeightPt * 0.85f
                            if (fontSize < 1f) fontSize = 1f

                            val rawWidth = try {
                                font.getStringWidth(text) / 1000f * fontSize
                            } catch (e: Exception) {
                                boxWidthPt // font can't measure this text — fall back
                            }
                            val hScale =
                                if (rawWidth > 0f) {
                                    (boxWidthPt / rawWidth * 100f).coerceIn(1f, 1000f)
                                } else {
                                    100f
                                }

                            try {
                                stream.beginText()
                                stream.setFont(font, fontSize)
                                stream.setHorizontalScaling(hScale)
                                stream.newLineAtOffset(xPt, yPt)
                                stream.showText(text)
                                stream.endText()
                            } catch (e: Exception) {
                                // Helvetica can't encode some glyphs (rare
                                // symbols/scripts) — skip that one word only.
                                Log.w("Lexiora", "embed: skipped word '$text': ${e.message}")
                            }
                        }
                    } finally {
                        stream.close()
                    }
                }

                val outFile = File(outputPath)
                outFile.parentFile?.mkdirs()
                document.save(outFile)
                runOnUiThread { result.success(outputPath) }
            } catch (e: Exception) {
                Log.w("Lexiora", "embedOcrText failed: ${e.message}")
                runOnUiThread { result.error("embed_failed", e.message, null) }
            } finally {
                try {
                    document?.close()
                } catch (e: Exception) {
                    // already closed / never opened
                }
            }
        }.start()
    }
}
