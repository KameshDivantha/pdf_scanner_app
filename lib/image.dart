import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import './widgets/app_image_viewer.dart';

/// A service provider for image utilities.
class AppImageUtils {
  AppImageUtils._();
  static AppImageUtils? _instance;

  static AppImageUtils get instance {
    _instance ??= AppImageUtils._();
    return _instance!;
  }

  String defaultBlurHash = r'LPF?CMSwD$r;?^$$Rhf+.8s:k7NZ';

  /// Picks an image from the gallery and crops it.
  Future<File?> pickImage() async {
    // Note: image_picker and image_cropper are still used as specialized native tools.
    // They are imported in service.dart and can be accessed via instance methods there.
    return null; // This will be handled in service.dart to avoid duplication
  }

  /// Builds an image widget based on the provided parameters.
  Widget buildImageWidget({
    Uint8List? image,
    Uri? imageUrl,
    File? imageFile,
    BoxFit fit = BoxFit.cover,
    BorderRadius borderRadius = BorderRadius.zero,
    bool enableImageViewer = false,
  }) {
    if (image != null && image.isNotEmpty) {
      return _MemoryImageViewer(
        image: image,
        fit: fit,
        borderRadius: borderRadius,
        enableImageViewer: enableImageViewer,
      );
    } else if (imageFile != null) {
      return _FileImageViewer(
        imageFile: imageFile,
        fit: fit,
        borderRadius: borderRadius,
        enableImageViewer: enableImageViewer,
      );
    } else if (imageUrl != null) {
      return _NetworkImageViewer(
        imageUri: imageUrl,
        fit: fit,
        borderRadius: borderRadius,
        enableImageViewer: enableImageViewer,
      );
    } else {
      return Container(
        color: Colors.white.withValues(alpha: 0.05),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white24),
      );
    }
  }
}

class _NetworkImageViewer extends StatelessWidget {
  const _NetworkImageViewer({
    required this.imageUri,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.enableImageViewer = true,
  });

  final Uri imageUri;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool enableImageViewer;

  @override
  Widget build(BuildContext context) {
    final imageProvider = NetworkImage(imageUri.toString());
    final imageWidget = Image(
      image: imageProvider,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.redAccent),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );

    Widget content = imageWidget;
    if (borderRadius != BorderRadius.zero) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    if (enableImageViewer) {
      content = GestureDetector(
        onTap: () => AppImageViewer.show(context, imageProvider),
        child: content,
      );
    }

    return content;
  }
}

class _MemoryImageViewer extends StatelessWidget {
  const _MemoryImageViewer({
    required this.image,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.enableImageViewer = true,
  });

  final Uint8List image;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool enableImageViewer;

  @override
  Widget build(BuildContext context) {
    final imageProvider = MemoryImage(image);
    final imageWidget = Image(image: imageProvider, fit: fit);

    Widget content = imageWidget;
    if (borderRadius != BorderRadius.zero) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    if (enableImageViewer) {
      content = GestureDetector(
        onTap: () => AppImageViewer.show(context, imageProvider),
        child: content,
      );
    }

    return content;
  }
}

class _FileImageViewer extends StatelessWidget {
  const _FileImageViewer({
    required this.imageFile,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.enableImageViewer = true,
  });

  final File imageFile;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool enableImageViewer;

  @override
  Widget build(BuildContext context) {
    final imageProvider = FileImage(imageFile);
    final imageWidget = Image(image: imageProvider, fit: fit);

    Widget content = imageWidget;
    if (borderRadius != BorderRadius.zero) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    if (enableImageViewer) {
      content = GestureDetector(
        onTap: () => AppImageViewer.show(context, imageProvider),
        child: Hero(tag: imageProvider.hashCode.toString(), child: content),
      );
    }

    return content;
  }
}
