import 'dart:io';

import 'package:flutter/material.dart';

import '../service.dart';

class AttachmentPreviewScreen extends StatelessWidget {
  const AttachmentPreviewScreen({super.key, required this.file});

  final AttachedFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (file.humanSize.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  file.humanSize,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: file.type == AttachmentType.image ? _imageView() : _fileView(),
    );
  }

  Widget _imageView() {
    return InteractiveViewer(
      child: Center(
        child: Image.file(
          File(file.path),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_rounded,
            color: Colors.white38,
            size: 64,
          ),
        ),
      ),
    );
  }

  Widget _fileView() {
    final isPdf = file.type == AttachmentType.pdf;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isPdf
                      ? const Color(0xFFFF6B6B)
                      : const Color(0xFF7C6AF6))
                  .withOpacity(0.12),
            ),
            child: Icon(
              isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              size: 72,
              color: isPdf
                  ? const Color(0xFFFF6B6B)
                  : const Color(0xFF7C6AF6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            file.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (file.humanSize.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              file.humanSize,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
