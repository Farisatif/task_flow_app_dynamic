import 'dart:io';

import 'package:flutter/services.dart';

import '../database/tables.dart';

class StoredAttachment {
  final String name;
  final String filePath;
  final int sizeBytes;
  final AttachmentKind kind;

  const StoredAttachment({
    required this.name,
    required this.filePath,
    required this.sizeBytes,
    required this.kind,
  });
}

/// ينسخ الملف المختار إلى مساحة التطبيق حتى لا يعتمد المرفق على URI مؤقت أو
/// صلاحية قد يسحبها نظام التشغيل بعد اختيار الملف.
class AttachmentStorageService {
  static const _documentChannel = MethodChannel('task_flow/document_picker');

  static Future<StoredAttachment?> pickAndStore() async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('اختيار المستندات متاح حاليًا على Android فقط.');
    }

    final result = await _documentChannel
        .invokeMethod<Map<dynamic, dynamic>>('pickAndStoreDocument');
    if (result == null) return null;

    final filePath = result['path'] as String?;
    final fileName = result['name'] as String?;
    if (filePath == null || filePath.isEmpty || fileName == null || fileName.isEmpty) {
      throw StateError('لم تُرجع أداة اختيار المستندات بيانات ملف صالحة.');
    }

    final rawSize = result['sizeBytes'];
    final size = rawSize is num ? rawSize.toInt() : 0;
    final mimeType = result['mimeType'] as String? ?? '';
    return StoredAttachment(
      name: fileName,
      filePath: filePath,
      sizeBytes: size,
      kind: _detectKind(_extensionFor(fileName), mimeType),
    );
  }

  static Future<void> deleteStoredFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<bool> exists(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    return File(filePath).exists();
  }

  static String _extensionFor(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    return lastDot >= 0 ? fileName.substring(lastDot + 1) : '';
  }

  static AttachmentKind _detectKind(String extension, String mimeType) {
    if (mimeType.startsWith('image/')) return AttachmentKind.image;
    if (mimeType == 'application/pdf') return AttachmentKind.pdf;

    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
        return AttachmentKind.image;
      case 'pdf':
        return AttachmentKind.pdf;
      case 'txt':
      case 'md':
      case 'csv':
      case 'json':
        return AttachmentKind.text;
      case 'xls':
      case 'xlsx':
      case 'ods':
        return AttachmentKind.chart;
      case 'ppt':
      case 'pptx':
      case 'odp':
        return AttachmentKind.presentation;
      default:
        return AttachmentKind.doc;
    }
  }
}
