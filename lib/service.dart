import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

// ─────────────────────────────────────────────────────────────────────────────
// Data Model
// ─────────────────────────────────────────────────────────────────────────────

enum AttachmentType { image, pdf, file }

class AttachedFile {
  const AttachedFile({
    required this.path,
    required this.type,
    required this.name,
    this.sizeBytes,
  });

  final String path;
  final AttachmentType type;
  final String name;
  final int? sizeBytes;

  factory AttachedFile.fromPath(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    final AttachmentType type;
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].contains(ext)) {
      type = AttachmentType.image;
    } else if (ext == '.pdf') {
      type = AttachmentType.pdf;
    } else {
      type = AttachmentType.file;
    }
    int? size;
    try {
      size = File(filePath).lengthSync();
    } catch (_) {}
    return AttachedFile(
      path: filePath,
      type: type,
      name: p.basename(filePath),
      sizeBytes: size,
    );
  }

  String get humanSize {
    if (sizeBytes == null) return '';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  static const _channel = MethodChannel('com.example.pdf_scanner_app/scanner');

  // ── Document Scanning ───────────────────────────────────────────────────

  /// Launches the native document scanner and returns a single PDF file.
  Future<AttachedFile?> scanDocument() async {
    debugPrint('AttachmentService: scanDocument started via MethodChannel');
    try {
      final result = await _channel.invokeMethod('scanDocument');
      if (result != null && result is List) {
        final images = List<String>.from(result);
        if (images.isNotEmpty) {
          debugPrint('AttachmentService: Native scanner returned ${images.length} images');
          final pdfFile = await buildPdf(images);
          debugPrint('AttachmentService: PDF built at ${pdfFile.path}');
          return AttachedFile.fromPath(pdfFile.path);
        }
      }
      debugPrint('AttachmentService: Scanner returned no images or null');
      return null;
    } catch (e) {
      debugPrint('AttachmentService error in scanDocument: $e');
      return null;
    }
  }

  // ── Camera & Gallery ───────────────────────────────────────────────────

  Future<File?> takeImage() async {
    debugPrint('AttachmentService: takeImage started');
    try {
      final String? path = await _channel.invokeMethod('takeImage');
      if (path == null) return null;

      return await cropImage(path);
    } catch (e) {
      debugPrint('AttachmentService error in takeImage: $e');
      return null;
    }
  }

  Future<File?> pickImage() async {
    debugPrint('AttachmentService: pickImage started');
    try {
      final String? path = await _channel.invokeMethod('pickImage');
      if (path == null) return null;

      return await cropImage(path);
    } catch (e) {
      debugPrint('AttachmentService error in pickImage: $e');
      return null;
    }
  }

  Future<List<AttachedFile>> pickMultiFromGallery() async {
    debugPrint('AttachmentService: pickMultiFromGallery started');
    try {
      final List? results = await _channel.invokeMethod('pickMultiImage');
      if (results == null) return [];
      return results.map((e) => AttachedFile.fromPath(e.toString())).toList();
    } catch (e) {
      debugPrint('AttachmentService error in pickMultiFromGallery: $e');
      return [];
    }
  }

  // ── File Picker ───────────────────────────────────────────────────────────

  Future<AttachedFile?> pickFile() async {
    debugPrint('AttachmentService: pickFile started');
    try {
      final String? path = await _channel.invokeMethod('pickFile');
      if (path != null) {
        debugPrint('AttachmentService: Native picker returned: $path');
        return AttachedFile.fromPath(path);
      }
      debugPrint('AttachmentService: Native picker returned null');
      return null;
    } catch (e) {
      debugPrint('AttachmentService error in pickFile: $e');
      return null;
    }
  }

  // ── Image Processing ──────────────────────────────────────────────────────

  Future<File?> cropImage(String imagePath) async {
    debugPrint('AttachmentService: cropImage started for $imagePath');
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: imagePath,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );
      debugPrint('AttachmentService: cropImage result: ${cropped?.path ?? 'null'}');
      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      debugPrint('AttachmentService error in cropImage: $e');
      return null;
    }
  }

  /// Rotates an image 90° clockwise (once per call) and saves to a temp file.
  Future<File?> rotateImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final src = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(src.height.toDouble(), 0);
      canvas.rotate(math.pi / 2);
      canvas.drawImage(src, Offset.zero, Paint());
      final pic = recorder.endRecording();
      final rotated = await pic.toImage(src.height, src.width);
      final byteData =
          await rotated.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      debugPrint('AttachmentService error in rotateImage: $e');
      return null;
    }
  }

  // ── PDF Builder ───────────────────────────────────────────────────────────

  Future<File> buildPdf(List<String> imagePaths) async {
    final pdf = pw.Document();
    for (var path in imagePaths) {
      if (path.startsWith('file://')) {
        path = Uri.parse(path).toFilePath();
      }
      
      final bytes = await File(path).readAsBytes();
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(build: (ctx) => pw.Center(child: pw.Image(image))),
      );
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
