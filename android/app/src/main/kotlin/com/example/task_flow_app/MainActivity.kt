package com.example.task_flow_app

import android.net.Uri
import android.provider.OpenableColumns
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val documentChannel = "task_flow/document_picker"
    private var pendingPickResult: MethodChannel.Result? = null

    private val documentPicker = registerForActivityResult(
        ActivityResultContracts.OpenDocument(),
    ) { uri ->
        val result = pendingPickResult ?: return@registerForActivityResult
        pendingPickResult = null

        if (uri == null) {
            result.success(null)
            return@registerForActivityResult
        }

        try {
            result.success(copyDocumentToAppStorage(uri))
        } catch (exception: Exception) {
            result.error("document_copy_failed", exception.message, null)
        }
    }

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
        documentPicker.launch(arrayOf("*/*"))
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
