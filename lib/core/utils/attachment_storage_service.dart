import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  static Future<StoredAttachment?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return null;

    final selected = result.files.single;
    final directory = await _attachmentsDirectory();
    final fileName = _safeFileName(selected.name);
    final target = File(
      p.join(directory.path, '${DateTime.now().microsecondsSinceEpoch}_$fileName'),
    );

    if (selected.path != null && selected.path!.isNotEmpty) {
      await File(selected.path!).copy(target.path);
    } else if (selected.bytes != null) {
      await target.writeAsBytes(selected.bytes!, flush: true);
    } else {
      throw StateError('تعذر الوصول إلى محتوى الملف المحدد.');
    }

    final size = await target.length();
    return StoredAttachment(
      name: selected.name,
      filePath: target.path,
      sizeBytes: size,
      kind: _detectKind(selected.extension ?? p.extension(selected.name)),
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

  static Future<Directory> _attachmentsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'attachments'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static String _safeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\w.\-\s]'), '_').trim();
    return cleaned.isEmpty ? 'attachment' : cleaned;
  }

  static AttachmentKind _detectKind(String extension) {
    switch (extension.toLowerCase().replaceFirst('.', '')) {
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
