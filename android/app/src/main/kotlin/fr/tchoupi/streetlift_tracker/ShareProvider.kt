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
 * L12 (KT-071) : sert en lecture seule l'unique image de partage de
 * progression (cache de l'application), le temps du partage. Non exporté ;
 * accès accordé à l'application choisie par l'utilisateur via
 * FLAG_GRANT_READ_URI_PERMISSION. Aucune autre donnée n'est accessible.
 */
class ShareProvider : ContentProvider() {
    companion object {
        private const val DIR = "partage"
        private const val NAME = "kalis_progression.png"

        fun authority(context: Context) = context.packageName + ".partage"

        fun write(context: Context, bytes: ByteArray): File {
            val dir = File(context.cacheDir, DIR)
            if (!dir.isDirectory && !dir.mkdirs()) throw FileNotFoundException()
            val file = File(dir, NAME)
            file.writeBytes(bytes)
            return file
        }

        fun uriFor(context: Context, file: File): Uri =
            Uri.Builder().scheme("content").authority(authority(context))
                .appendPath(file.name).build()
    }

    private fun fileFor(uri: Uri): File? {
        val ctx = context ?: return null
        if (uri.authority != authority(ctx) || uri.lastPathSegment != NAME) return null
        val file = File(File(ctx.cacheDir, DIR), NAME)
        return if (file.isFile) file else null
    }

    override fun onCreate(): Boolean = true

    override fun getType(uri: Uri): String? = if (fileFor(uri) != null) "image/png" else null

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
