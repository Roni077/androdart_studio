package com.androdartstudio.flutteride.androdart_studio

import android.content.Intent
import android.content.res.AssetFileDescriptor
import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.DocumentsProvider
import java.io.File
import java.io.FileNotFoundException

class AndrodartStorageProvider : DocumentsProvider() {

    companion object {
        private const val ROOT_ID = "root"
        private const val ROOT_DOC_ID = "root"
        private val DEFAULT_ROOT_PROJECTION = arrayOf(
            DocumentsContract.Root.COLUMN_ROOT_ID,
            DocumentsContract.Root.COLUMN_TITLE,
            DocumentsContract.Root.COLUMN_DOCUMENT_ID,
            DocumentsContract.Root.COLUMN_FLAGS,
            DocumentsContract.Root.COLUMN_ICON,
            DocumentsContract.Root.COLUMN_SUMMARY
        )
        private val DEFAULT_DOC_PROJECTION = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            DocumentsContract.Document.COLUMN_FLAGS,
            DocumentsContract.Document.COLUMN_SIZE
        )
    }

    private fun getRootDir(): File {
        return File(context?.filesDir, "rootfs/home/user")
    }

    override fun onCreate(): Boolean = true

    override fun queryRoots(projection: Array<out String>?): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_ROOT_PROJECTION)
        result.newRow().apply {
            add(DocumentsContract.Root.COLUMN_ROOT_ID, ROOT_ID)
            add(DocumentsContract.Root.COLUMN_TITLE, "androdart_studio")
            add(DocumentsContract.Root.COLUMN_DOCUMENT_ID, ROOT_DOC_ID)
            add(DocumentsContract.Root.COLUMN_FLAGS,
                DocumentsContract.Root.FLAG_LOCAL_ONLY or
                DocumentsContract.Root.FLAG_SUPPORTS_CREATE)
            add(DocumentsContract.Root.COLUMN_ICON, android.R.drawable.ic_menu_manage)
            add(DocumentsContract.Root.COLUMN_SUMMARY, "Flutter IDE workspace")
        }
        return result
    }

    override fun queryDocument(documentId: String, projection: Array<out String>?): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOC_PROJECTION)
        val file = getFileForDocId(documentId)
        if (file != null) {
            addFileRow(result, documentId, file)
        }
        return result
    }

    override fun queryChildDocuments(
        parentDocumentId: String,
        projection: Array<out String>?,
        sortOrder: String?
    ): Cursor {
        val result = MatrixCursor(projection ?: DEFAULT_DOC_PROJECTION)
        val parent = getFileForDocId(parentDocumentId)
        if (parent != null && parent.isDirectory) {
            val children = parent.listFiles()
            if (children != null) {
                for (child in children.sortedBy { it.name }) {
                    val childDocId = getDocIdForFile(child)
                    addFileRow(result, childDocId, child)
                }
            }
        }
        return result
    }

    override fun openDocument(
        documentId: String,
        mode: String,
        signal: CancellationSignal?
    ): ParcelFileDescriptor {
        val file = getFileForDocId(documentId)
            ?: throw FileNotFoundException("Document $documentId not found")
        val accessMode = ParcelFileDescriptor.parseMode(mode)
        return ParcelFileDescriptor.open(file, accessMode)
    }

    override fun createDocument(
        parentDocumentId: String,
        mimeType: String,
        displayName: String
    ): String {
        val parent = getFileForDocId(parentDocumentId)
            ?: throw FileNotFoundException("Parent $parentDocumentId not found")
        val child = File(parent, displayName)
        if (mimeType == DocumentsContract.Document.MIME_TYPE_DIR) {
            child.mkdirs()
        } else {
            child.createNewFile()
        }
        return getDocIdForFile(child)
    }

    override fun deleteDocument(documentId: String) {
        val file = getFileForDocId(documentId)
            ?: throw FileNotFoundException("Document $documentId not found")
        file.deleteRecursively()
    }

    override fun getDocumentType(documentId: String): String? {
        val file = getFileForDocId(documentId) ?: return null
        return if (file.isDirectory) {
            DocumentsContract.Document.MIME_TYPE_DIR
        } else {
            getMimeType(file)
        }
    }

    private fun addFileRow(cursor: MatrixCursor, docId: String, file: File) {
        cursor.newRow().apply {
            add(DocumentsContract.Document.COLUMN_DOCUMENT_ID, docId)
            add(DocumentsContract.Document.COLUMN_MIME_TYPE,
                if (file.isDirectory) DocumentsContract.Document.MIME_TYPE_DIR else getMimeType(file))
            add(DocumentsContract.Document.COLUMN_DISPLAY_NAME, file.name)
            add(DocumentsContract.Document.COLUMN_LAST_MODIFIED, file.lastModified())
            add(DocumentsContract.Document.COLUMN_FLAGS, 0)
            add(DocumentsContract.Document.COLUMN_SIZE, file.length())
        }
    }

    private fun getFileForDocId(docId: String): File? {
        if (docId == ROOT_DOC_ID) return getRootDir()
        if (!docId.startsWith(ROOT_DOC_ID)) return null
        val relativePath = docId.removePrefix("$ROOT_DOC_ID/")
        return File(getRootDir(), relativePath)
    }

    private fun getDocIdForFile(file: File): String {
        val rootDir = getRootDir()
        val relativePath = file.relativeTo(rootDir).path
        return if (file == rootDir) ROOT_DOC_ID else "$ROOT_DOC_ID/$relativePath"
    }

    private fun getMimeType(file: File): String {
        val ext = file.extension.lowercase()
        return when (ext) {
            "dart" -> "text/x-dart"
            "yaml", "yml" -> "text/x-yaml"
            "json" -> "application/json"
            "xml" -> "application/xml"
            "html" -> "text/html"
            "css" -> "text/css"
            "js" -> "application/javascript"
            "kt" -> "text/x-kotlin"
            "java" -> "text/x-java"
            "gradle" -> "text/x-gradle"
            "md" -> "text/markdown"
            "txt" -> "text/plain"
            "png", "jpg", "jpeg", "gif", "webp" -> "image/*"
            "apk" -> "application/vnd.android.package-archive"
            else -> "application/octet-stream"
        }
    }
}
