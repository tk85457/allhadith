package com.taha.allhadithshahih

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.activity.enableEdgeToEdge
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {

    // Single background thread for heavy file I/O so the UI thread is never blocked.
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copyAsset" -> {
                        val assetPath = call.argument<String>("assetPath")
                        val targetPath = call.argument<String>("targetPath")
                        if (assetPath == null || targetPath == null) {
                            result.error("BAD_ARGS", "assetPath and targetPath are required", null)
                            return@setMethodCallHandler
                        }
                        ioExecutor.execute {
                            try {
                                val copied = copyAssetAtomically(assetPath, targetPath)
                                mainHandler.post { result.success(copied) }
                            } catch (e: InsufficientSpaceException) {
                                mainHandler.post { result.error("NO_SPACE", e.message, null) }
                            } catch (e: Throwable) {
                                mainHandler.post { result.error("COPY_FAILED", e.message, null) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        ioExecutor.shutdown()
        super.onDestroy()
    }

    /**
     * Streams a bundled Flutter asset straight from the APK to [targetPath] in 256 KB chunks
     * (constant memory), writing to a temp file first and renaming only when the copy is fully
     * flushed. This replaces rootBundle.load() for the 100 MB+ database, which pushed the whole
     * file through a platform-message response on the Dart heap (ANR / OOM on 32-bit devices)
     * and could leave a half-written DB behind if the process was killed mid-copy.
     */
    private fun copyAssetAtomically(assetPath: String, targetPath: String): Long {
        val lookupKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(assetPath)
        val target = File(targetPath)
        val parent = target.parentFile ?: throw IOException("Invalid target path")
        if (!parent.exists() && !parent.mkdirs()) {
            throw IOException("Cannot create directory ${parent.path}")
        }

        val tmp = File(parent, target.name + ".tmp")
        if (tmp.exists()) tmp.delete()

        try {
            assets.open(lookupKey).use { input ->
                val expected = try { input.available().toLong() } catch (_: Throwable) { 0L }
                // Require the asset size plus a 16 MB safety margin.
                if (expected > 0 && parent.usableSpace < expected + 16L * 1024 * 1024) {
                    throw InsufficientSpaceException(
                        "Not enough free storage: need ~${(expected / (1024 * 1024)) + 16} MB"
                    )
                }

                FileOutputStream(tmp).use { output ->
                    val buffer = ByteArray(256 * 1024)
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) break
                        output.write(buffer, 0, read)
                    }
                    output.flush()
                    output.fd.sync()
                }
            }

            if (tmp.length() == 0L) throw IOException("Copied asset is empty")

            // Remove any stale sidecar files from a previous/corrupt database.
            File(parent, target.name + "-wal").delete()
            File(parent, target.name + "-shm").delete()
            File(parent, target.name + "-journal").delete()
            if (target.exists() && !target.delete()) {
                throw IOException("Cannot replace existing ${target.path}")
            }
            if (!tmp.renameTo(target)) {
                throw IOException("Cannot move temp file into place")
            }
            return target.length()
        } catch (e: Throwable) {
            tmp.delete()
            // A write failure caused by a full disk is reported as a storage problem.
            if (e is IOException && e !is InsufficientSpaceException &&
                (e.message?.contains("ENOSPC", ignoreCase = true) == true ||
                    e.message?.contains("No space left", ignoreCase = true) == true)
            ) {
                throw InsufficientSpaceException("No space left on device")
            }
            throw e
        }
    }

    private class InsufficientSpaceException(message: String) : IOException(message)

    companion object {
        private const val CHANNEL = "com.taha.allhadithshahih/assets"
    }
}
