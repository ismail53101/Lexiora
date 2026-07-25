package com.lexiora.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.OpenableColumns
import android.util.Log
import android.view.WindowManager
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
 *  - getSdkInt / setKeepScreenOn: small platform helpers.
 *  - isExternalStorageManager: whether all-files access is granted (always true
 *    below API 30, where the storage permission covers broad reads).
 *  - scanAllPdfs: recursively walks the shared-storage volumes and returns every
 *    readable *.pdf by absolute path (auto-discovery; files opened in place).
 *  - pickPdfs: opens the system file picker (multi-select) and copies the chosen
 *    PDFs into the app's private files dir, returning {path, name, size} for each
 *    (manual import).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "lexiora/platform"
    private val pickPdfsRequest = 0x5A11
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
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
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            Environment.isExternalStorageManager()
                        } else {
                            true
                        },
                    )
                    "scanAllPdfs" -> scanAllPdfs(result)
                    "pickPdfs" -> startPickPdfs(result)
                    else -> result.notImplemented()
                }
            }
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

    private fun copyToImported(uri: Uri, dir: File, index: Int): Map<String, Any?>? {
        val displayName = queryDisplayName(uri) ?: "document_${System.currentTimeMillis()}.pdf"
        val dest = File(dir, "${System.currentTimeMillis()}_$index.pdf")
        val input = contentResolver.openInputStream(uri) ?: return null
        input.use { s -> dest.outputStream().use { o -> s.copyTo(o) } }
        return mapOf(
            "path" to dest.absolutePath,
            "name" to displayName,
            "size" to dest.length(),
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

    // ── Automatic discovery (filesystem walk) ──────────────────────────────────

    private fun scanAllPdfs(result: MethodChannel.Result) {
        Thread {
            val out = ArrayList<Map<String, Any?>>()
            val seen = HashSet<String>()
            try {
                val roots = ArrayList<File>()
                Environment.getExternalStorageDirectory()?.let { roots.add(it) }
                // Include secondary volumes (e.g. SD cards): each getExternalFilesDirs
                // entry is /storage/<VOL>/Android/data/<pkg>/files → the volume root
                // is four levels up.
                for (dir in getExternalFilesDirs(null)) {
                    val vol = dir?.parentFile?.parentFile?.parentFile?.parentFile
                    if (vol != null && vol.exists() &&
                        roots.none { it.absolutePath == vol.absolutePath }
                    ) {
                        roots.add(vol)
                    }
                }
                for (root in roots) walkPdfs(root, out, seen, 0)
                Log.i(
                    "Lexiora",
                    "scanAllPdfs found ${out.size} PDF(s) across ${roots.size} volume(s)",
                )
                runOnUiThread { result.success(out) }
            } catch (e: Exception) {
                runOnUiThread { result.error("scan_all_failed", e.message, null) }
            }
        }.start()
    }

    private fun walkPdfs(
        dir: File,
        out: ArrayList<Map<String, Any?>>,
        seen: HashSet<String>,
        depth: Int,
    ) {
        if (depth > 25) return // generous cap; guards against symlink loops
        val files = try {
            dir.listFiles()
        } catch (e: Exception) {
            null
        } ?: return
        for (f in files) {
            try {
                if (f.isDirectory) {
                    // Skip only app-private/system trees, which never hold the
                    // user's own PDFs and are slow or inaccessible even with
                    // all-files access. Android/media (WhatsApp docs, etc.) IS
                    // traversed. Hidden folders are intentionally not skipped.
                    if (f.parentFile?.name == "Android" &&
                        (f.name == "data" || f.name == "obb")
                    ) {
                        continue
                    }
                    walkPdfs(f, out, seen, depth + 1)
                } else if (f.name.lowercase().endsWith(".pdf") && f.canRead()) {
                    if (seen.add(f.absolutePath)) {
                        out.add(
                            mapOf(
                                "path" to f.absolutePath,
                                "name" to f.name,
                                "size" to f.length(),
                            ),
                        )
                    }
                }
            } catch (e: Exception) {
                // One problematic entry must never abort the whole scan.
                Log.w("Lexiora", "walk skip ${f.absolutePath}: ${e.message}")
            }
        }
    }
}
