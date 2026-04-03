// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// A service provider for image utilities.
class AppImageUtils {
  AppImageUtils._() {
    _init();
  }
  static AppImageUtils? _instance;

  static AppImageUtils get instance {
    _instance ??= AppImageUtils._();
    return _instance!;
  }

  String defaultBlurHash = r'LPF?CMSwD$r;?^$$Rhf+.8s:k7NZ';

  /// Initializes the image picker platform.
  void _init() {
    final imagePickerPlatform = ImagePickerPlatform.instance;
    if (imagePickerPlatform is ImagePickerAndroid) {
      imagePickerPlatform.useAndroidPhotoPicker = true;
    }
  }

  /// Picks an image from the gallery and crops it.
  Future<File?> pickImage() async {
    debugPrint('AppImageUtils: pickImage started');
    try {
      final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) {
        debugPrint('AppImageUtils: No image picked from gallery');
        return null;
      }
      debugPrint('AppImageUtils: Image picked: ${pickedImage.path}');
      final cropped = await _cropImage(file: pickedImage);
      if (cropped == null) {
        debugPrint('AppImageUtils: Cropping cancelled or failed');
      } else {
        debugPrint('AppImageUtils: Cropping successful: ${cropped.path}');
      }
      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      debugPrint('AppImageUtils Error in pickImage: $e');
      return null;
    }
  }

  /// Takes an image using the camera and crops it.
  Future<File?> takeImage() async {
    debugPrint('AppImageUtils: takeImage started');
    try {
      final pickedImage = await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedImage == null) {
        debugPrint('AppImageUtils: No image picked from camera');
        return null;
      }
      debugPrint('AppImageUtils: Image picked: ${pickedImage.path}');
      
      // Safety delay for iOS to allow the camera UI to fully dismiss
      if (Platform.isIOS) {
        debugPrint('AppImageUtils: Applying iOS safety delay...');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final cropped = await _cropImage(file: pickedImage);
      if (cropped == null) {
        debugPrint('AppImageUtils: Cropping cancelled or failed');
      } else {
        debugPrint('AppImageUtils: Cropping successful: ${cropped.path}');
      }
      return cropped != null ? File(cropped.path) : null;
    } catch (e) {
      debugPrint('AppImageUtils Error in takeImage: $e');
      return null;
    }
  }

  Future<CroppedFile?> _cropImage({required XFile file}) async {
    debugPrint('AppImageUtils: _cropImage internal started for ${file.path}');
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: file.path,
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
            minimumAspectRatio: 1.0,
            aspectRatioPickerButtonHidden: false,
            resetButtonHidden: false,
            doneButtonTitle: 'Crop',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );
      debugPrint('AppImageUtils: ImageCropper result: ${result?.path ?? 'null'}');
      return result;
    } catch (e) {
      debugPrint('AppImageUtils Error in _cropImage: $e');
      return null;
    }
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
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
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
    final imageWidget = CachedNetworkImage(
      imageUrl: imageUri.toString(),
      fit: fit,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );

    Widget content = imageWidget;
    if (borderRadius != BorderRadius.zero) {
      content = ClipRRect(borderRadius: borderRadius, child: content);
    }

    if (enableImageViewer) {
      content = GestureDetector(
        onTap: () => showImageViewer(context, CachedNetworkImageProvider(imageUri.toString())),
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
        onTap: () => showImageViewer(context, imageProvider),
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
        onTap: () => showImageViewer(context, imageProvider),
        child: content,
      );
    }

    return content;
  }
}
