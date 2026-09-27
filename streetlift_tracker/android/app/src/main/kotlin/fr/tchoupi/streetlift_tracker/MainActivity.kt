package fr.tchoupi.streetlift_tracker

import android.app.Activity
import android.content.ClipData
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.FileNotFoundException
import java.io.IOException
import java.security.MessageDigest
import java.util.TimeZone
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    // Sauvegardes par fichier (L2b) : sélecteur système (Storage Access
    // Framework), sans permission de stockage. Le contenu des sauvegardes
    // n'est jamais journalisé.
    private val createRequest = 7301
    private val openRequest = 7302
    @Volatile private var pendingResult: MethodChannel.Result? = null
    private var pendingBytes: ByteArray? = null
    private var pendingLimit: Int = 0
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    private fun finish(values: Map<String, Any?>) {
        val result = pendingResult ?: return
        pendingResult = null
        pendingBytes = null
        main.post {
            try {
                result.success(values)
            } catch (_: Exception) {
            }
        }
    }

    private fun failure(code: String, extra: Map<String, Any?> = emptyMap()) =
        finish(mapOf("status" to "error", "code" to code) + extra)

    private fun displayName(uri: Uri): String? = try {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
    } catch (_: Exception) {
        null
    }

    private fun declaredSize(uri: Uri): Long? = try {
        contentResolver.query(uri, arrayOf(OpenableColumns.SIZE), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst() && !cursor.isNull(0)) cursor.getLong(0) else null
        }
    } catch (_: Exception) {
        null
    }

    private fun sha256(bytes: ByteArray): ByteArray = MessageDigest.getInstance("SHA-256").digest(bytes)

    private fun readLimited(uri: Uri, limit: Int): ByteArray? {
        val input = contentResolver.openInputStream(uri) ?: throw FileNotFoundException()
        input.use { stream ->
            val out = ByteArrayOutputStream()
            val buffer = ByteArray(16 * 1024)
            var total = 0
            while (true) {
                val read = stream.read(buffer)
                if (read < 0) break
                total += read
                if (total > limit) return null
                out.write(buffer, 0, read)
            }
            return out.toByteArray()
        }
    }

    private fun writeDocument(uri: Uri, bytes: ByteArray) {
        io.execute {
            val name = displayName(uri)
            try {
                val output = contentResolver.openOutputStream(uri, "wt") ?: throw FileNotFoundException()
                output.use {
                    it.write(bytes)
                    it.flush()
                }
                // Relecture : succès annoncé seulement si le fichier relu est identique.
                val back = try {
                    readLimited(uri, bytes.size + 1)
                } catch (_: Exception) {
                    null
                }
                if (back == null) {
                    finish(mapOf("status" to "unverified", "name" to name, "bytes" to bytes.size))
                } else if (back.size == bytes.size && sha256(back).contentEquals(sha256(bytes))) {
                    finish(mapOf("status" to "saved", "name" to name, "bytes" to bytes.size))
                } else {
                    failure("partial", mapOf("deleted" to deleteQuietly(uri), "name" to name))
                }
            } catch (_: SecurityException) {
                failure("denied", mapOf("deleted" to deleteQuietly(uri), "name" to name))
            } catch (_: FileNotFoundException) {
                failure("unavailable", mapOf("deleted" to deleteQuietly(uri), "name" to name))
            } catch (_: IOException) {
                failure("io", mapOf("deleted" to deleteQuietly(uri), "name" to name))
            } catch (_: Exception) {
                failure("io", mapOf("deleted" to deleteQuietly(uri), "name" to name))
            }
        }
    }

    private fun deleteQuietly(uri: Uri): Boolean = try {
        DocumentsContract.deleteDocument(contentResolver, uri)
    } catch (_: Exception) {
        false
    }

    private fun readDocument(uri: Uri, limit: Int) {
        io.execute {
            val name = displayName(uri)
            val size = declaredSize(uri)
            try {
                val bytes = readLimited(uri, limit)
                if (bytes == null) {
                    finish(mapOf("status" to "tooLarge", "name" to name, "declaredSize" to size))
                } else {
                    finish(mapOf("status" to "opened", "name" to name, "declaredSize" to size, "bytes" to bytes))
                }
            } catch (_: SecurityException) {
                failure("denied", mapOf("name" to name))
            } catch (_: FileNotFoundException) {
                failure("unavailable", mapOf("name" to name))
            } catch (_: Exception) {
                failure("io", mapOf("name" to name))
            }
        }
    }

    @Deprecated("Activity Result API non disponible sur FlutterActivity sans AndroidX")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != createRequest && requestCode != openRequest) {
            @Suppress("DEPRECATION")
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finish(mapOf("status" to "cancelled"))
            return
        }
        if (requestCode == createRequest) {
            val bytes = pendingBytes
            if (bytes == null) failure("interrupted") else writeDocument(uri, bytes)
        } else {
            readDocument(uri, pendingLimit)
        }
    }

    override fun onDestroy() {
        failure("interrupted")
        io.shutdown()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kalis_track/backup_files")
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.success(mapOf("status" to "error", "code" to "busy"))
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "createDocument" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val name = call.argument<String>("name")
                        if (bytes == null || name == null) {
                            result.success(mapOf("status" to "error", "code" to "arguments"))
                            return@setMethodCallHandler
                        }
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("application/json")
                            .putExtra(Intent.EXTRA_TITLE, name)
                        pendingResult = result
                        pendingBytes = bytes
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, createRequest)
                        } catch (_: ActivityNotFoundException) {
                            failure("noPicker")
                        }
                    }
                    "openDocument" -> {
                        pendingLimit = call.argument<Int>("maxBytes") ?: 0
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("*/*")
                        pendingResult = result
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, openRequest)
                        } catch (_: ActivityNotFoundException) {
                            failure("noPicker")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        // L12 (KT-071) : image de progression partagée par le menu Android.
        // Fichier temporaire de l'application (cache), servi en lecture seule
        // par ShareProvider ; aucun serveur, aucune permission.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kalis_track/share")
            .setMethodCallHandler { call, result ->
                if (call.method == "shareText") {
                    // L13 (KT-078) : retour de test, texte seul, partagé
                    // volontairement par le menu Android (aucun serveur).
                    val text = call.argument<String>("text") ?: ""
                    val subject = call.argument<String>("subject") ?: ""
                    if (text.isEmpty() || text.length > 20000) {
                        result.success("error")
                        return@setMethodCallHandler
                    }
                    try {
                        val send = Intent(Intent.ACTION_SEND)
                            .setType("text/plain")
                            .putExtra(Intent.EXTRA_TEXT, text)
                            .putExtra(Intent.EXTRA_SUBJECT, subject)
                        startActivity(Intent.createChooser(send, "Envoyer mon avis"))
                        result.success("shared")
                    } catch (_: ActivityNotFoundException) {
                        result.success("unavailable")
                    } catch (_: Exception) {
                        result.success("error")
                    }
                    return@setMethodCallHandler
                }
                if (call.method != "shareImage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val text = call.argument<String>("text") ?: ""
                if (bytes == null || bytes.isEmpty() || bytes.size > 8 * 1024 * 1024) {
                    result.success("error")
                    return@setMethodCallHandler
                }
                try {
                    val file = ShareProvider.write(this, bytes)
                    val uri = ShareProvider.uriFor(this, file)
                    val send = Intent(Intent.ACTION_SEND)
                        .setType("image/png")
                        .putExtra(Intent.EXTRA_STREAM, uri)
                        .putExtra(Intent.EXTRA_TEXT, text)
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    send.clipData = ClipData.newRawUri("", uri)
                    val chooser = Intent.createChooser(send, "Partager ma progression")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    startActivity(chooser)
                    result.success("shared")
                } catch (_: ActivityNotFoundException) {
                    result.success("unavailable")
                } catch (_: Exception) {
                    result.success("error")
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kalis_track/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "timeZoneName" -> result.success(TimeZone.getDefault().id)
                    "openSettings" -> {
                        val page = call.argument<String>("page")
                        val appDetails = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:$packageName"))
                        val intent = when {
                            page == "battery" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M ->
                                Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                            page == "channel" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                                Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                                    .putExtra(Settings.EXTRA_CHANNEL_ID, "kalis_daily")
                            page == "notifications" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O ->
                                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            else -> appDetails
                        }
                        try {
                            startActivity(intent)
                            result.success(true)
                        } catch (_: ActivityNotFoundException) {
                            try {
                                startActivity(appDetails)
                                result.success(true)
                            } catch (_: Exception) { result.success(false) }
                        } catch (_: SecurityException) { result.success(false) }
                    }
                    "highRefreshRate" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            @Suppress("DEPRECATION")
                            val screen = windowManager.defaultDisplay
                            val current = screen.mode
                            val best = screen.supportedModes.filter {
                                it.physicalWidth == current.physicalWidth && it.physicalHeight == current.physicalHeight
                            }.maxByOrNull { it.refreshRate }
                            if (best != null) {
                                val params = window.attributes
                                params.preferredDisplayModeId = best.modeId
                                window.attributes = params
                            }
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
