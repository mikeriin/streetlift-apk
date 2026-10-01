package fr.tchoupi.streetlift_tracker

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import java.io.File
import java.io.FileNotFoundException

/**
 * Sert en lecture seule, le temps d'un partage, un fichier JSON unique du
 * cache de l'application. Non exporté ; accès accordé à l'application
 * choisie par l'utilisateur via FLAG_GRANT_READ_URI_PERMISSION. Aucune autre
 * donnée n'est accessible.
 * G1 : export de la session de test (mode dev), supprimé avec la session.
 * G2 : copie des données d'avant la suppression des WOD et des séances perso.
 * (L'image de partage de L12 a été retirée avec L12 par G2.)
 */
class ShareProvider : ContentProvider() {
    companion object {
        private const val DIR = "partage"
        const val JSON_NAME = "kalis_session_de_test.json"
        const val COPY_NAME = "kalis_copie_avant_suppression.json"
        private val NAMES = setOf(JSON_NAME, COPY_NAME)

        fun authority(context: Context) = context.packageName + ".partage"

        fun write(context: Context, bytes: ByteArray, name: String): File {
            require(name in NAMES)
            val dir = File(context.cacheDir, DIR)
            if (!dir.isDirectory && !dir.mkdirs()) throw FileNotFoundException()
            val file = File(dir, name)
            file.writeBytes(bytes)
            return file
        }

        fun delete(context: Context, name: String) {
            if (name !in NAMES) return
            File(File(context.cacheDir, DIR), name).delete()
        }

        fun uriFor(context: Context, file: File): Uri =
            Uri.Builder().scheme("content").authority(authority(context))
                .appendPath(file.name).build()
    }

    private fun fileFor(uri: Uri): File? {
        val ctx = context ?: return null
        val name = uri.lastPathSegment
        if (uri.authority != authority(ctx) || name == null || name !in NAMES) return null
        val file = File(File(ctx.cacheDir, DIR), name)
        return if (file.isFile) file else null
    }

    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String? =
        if (fileFor(uri) == null) null else "application/json"

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw SecurityException("Lecture seule")
        val file = fileFor(uri) ?: throw FileNotFoundException()
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? {
        val file = fileFor(uri) ?: return null
        val columns = projection ?: arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val cursor = MatrixCursor(columns)
        cursor.addRow(
            columns.map<String, Any?> {
                when (it) {
                    OpenableColumns.DISPLAY_NAME -> file.name
                    OpenableColumns.SIZE -> file.length()
                    else -> null
                }
            }.toTypedArray(),
        )
        return cursor
    }

    override fun insert(uri: Uri, values: ContentValues?): Uri? = null

    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0

    override fun update(
        uri: Uri,
        values: ContentValues?,
        selection: String?,
        selectionArgs: Array<out String>?,
    ): Int = 0
}
