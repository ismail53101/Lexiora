package com.lexiora.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts a lightweight PDF picker over the Storage Access Framework
 * (ACTION_OPEN_DOCUMENT). This avoids any third-party file-picker plugin and,
 * because SAF grants scoped access to the chosen file, Lexiora needs **no**
 * storage permission. The picked document is copied into the app cache and its
 * path is returned to Dart, which then moves it into app-private storage.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "lexiora/file_picker"
    private val pickRequestCode = 0x1069
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickPdf" -> startPdfPick(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startPdfPick(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "A pick is already in progress.", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/pdf"
        }
        startActivityForResult(intent, pickRequestCode)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return
        val result = pendingResult ?: return
        pendingResult = null

        val uri: Uri? = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // user cancelled
            return
        }

        try {
            val displayName = queryDisplayName(uri) ?: "document.pdf"
            val cacheFile = File(cacheDir, "import_${System.currentTimeMillis()}.pdf")
            val input = contentResolver.openInputStream(uri)
            if (input == null) {
                result.error("unreadable", "Could not open the selected file.", null)
                return
            }
            input.use { stream ->
                cacheFile.outputStream().use { output -> stream.copyTo(output) }
            }
            result.success(
                mapOf("path" to cacheFile.absolutePath, "name" to displayName),
            )
        } catch (e: Exception) {
            result.error("import_failed", e.message, null)
        }
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index)
            }
        }
        return null
    }
}
