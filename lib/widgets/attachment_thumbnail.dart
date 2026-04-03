import 'dart:io';

import 'package:flutter/material.dart';

import '../screens/attachment_preview_screen.dart';
import '../service.dart';

class AttachmentThumbnail extends StatelessWidget {
  const AttachmentThumbnail({
    super.key,
    required this.file,
    this.onDelete,
    this.size = 88.0,
  });

  final AttachedFile file;
  final VoidCallback? onDelete;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openPreview(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _thumbnail(),
          if (onDelete != null) _deleteBtn(),
        ],
      ),
    );
  }

  Widget _thumbnail() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E1E2E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _content(),
    );
  }

  Widget _content() {
    if (file.type == AttachmentType.image) {
      return Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _iconContent(
          Icons.broken_image_rounded,
          Colors.white38,
        ),
      );
    } else if (file.type == AttachmentType.pdf) {
      return _iconContent(
        Icons.picture_as_pdf_rounded,
        const Color(0xFFFF6B6B),
      );
    } else {
      return _iconContent(
        Icons.insert_drive_file_rounded,
        const Color(0xFF7C6AF6),
      );
    }
  }

  Widget _iconContent(IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: size * 0.38),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            file.name,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _deleteBtn() {
    return Positioned(
      top: -6,
      right: -6,
      child: GestureDetector(
        onTap: onDelete,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A2A3A),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: const Icon(Icons.close, color: Colors.white70, size: 13),
        ),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AttachmentPreviewScreen(file: file),
      ),
    );
  }
}

/// An "add" slot matching the thumbnail grid style.
class AddAttachmentSlot extends StatelessWidget {
  const AddAttachmentSlot({super.key, required this.onTap, this.size = 88.0});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1A1A25),
          border: Border.all(
            color: const Color(0xFF7C6AF6).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: const Color(0xFF7C6AF6),
              size: size * 0.38,
            ),
            const SizedBox(height: 4),
            const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFF7C6AF6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
