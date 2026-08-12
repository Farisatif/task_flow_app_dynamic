package com.example.task_flow_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val documentChannel = "task_flow/document_picker"
    private val documentPickerRequestCode = 9412
    private var pendingPickResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, documentChannel)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "pickAndStoreDocument" -> pickAndStoreDocument(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun pickAndStoreDocument(result: MethodChannel.Result) {
        if (pendingPickResult != null) {
            result.error("picker_busy", "يوجد اختيار ملف قيد التنفيذ.", null)
            return
        }

        pendingPickResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivityForResult(intent, documentPickerRequestCode)
        } catch (exception: Exception) {
            pendingPickResult = null
            result.error("document_picker_unavailable", exception.message, null)
        }
    }

    @Deprecated("Deprecated in Android API 30, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != documentPickerRequestCode) return

        val result = pendingPickResult ?: return
        pendingPickResult = null
        val uri = data?.data

        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }

        try {
            result.success(copyDocumentToAppStorage(uri))
        } catch (exception: Exception) {
            result.error("document_copy_failed", exception.message, null)
        }
    }

    private fun copyDocumentToAppStorage(uri: Uri): Map<String, Any> {
        val displayName = queryDisplayName(uri) ?: "attachment"
        val safeName = displayName.replace(Regex("[^A-Za-z0-9._ -]"), "_")
            .ifBlank { "attachment" }
        val directory = File(filesDir, "attachments")
        if (!directory.exists() && !directory.mkdirs()) {
            throw IllegalStateException("تعذر إنشاء مجلد المرفقات.")
        }

        val destination = File(directory, "${System.currentTimeMillis()}_$safeName")
        contentResolver.openInputStream(uri)?.use { input ->
            destination.outputStream().use { output -> input.copyTo(output) }
        } ?: throw IllegalStateException("تعذر قراءة الملف المحدد.")

        return mapOf(
            "path" to destination.absolutePath,
            "name" to displayName,
            "sizeBytes" to destination.length(),
            "mimeType" to (contentResolver.getType(uri) ?: ""),
        )
    }

    private fun queryDisplayName(uri: Uri): String? {
        contentResolver.query(uri, null, null, null, null)?.use { cursor ->
            val columnIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (columnIndex >= 0 && cursor.moveToFirst()) {
                return cursor.getString(columnIndex)
            }
        }
        return null
    }
}
