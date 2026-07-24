package com.lexiora.app

import android.os.Build
import android.os.Environment
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Native platform bridge for Lexiora (`lexiora/platform`).
 *
 * Discovery is fully automatic and reference-in-place — there is no import or
 * folder-picker path. The bridge exposes:
 *
 *  - getSdkInt / setKeepScreenOn: small platform helpers.
 *  - isExternalStorageManager: whether all-files access is granted (always true
 *    below API 30, where the storage permission covers broad reads).
 *  - scanAllPdfs: recursively walks the shared-storage volumes and returns every
 *    readable *.pdf by absolute path (name, size). Requires all-files access on
 *    Android 11+; the reader opens each file in place, nothing is copied.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "lexiora/platform"

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
                    else -> result.notImplemented()
                }
            }
    }

    /** Recursively walks the shared-storage volumes for *.pdf files. */
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
        if (depth > 15) return // guard against pathological trees / symlink loops
        val files = dir.listFiles() ?: return
        for (f in files) {
            if (f.isDirectory) {
                // Skip app-private/system noise at the storage root.
                if (depth == 0 && f.name == "Android") continue
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
        }
    }
}
