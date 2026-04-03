import 'package:flutter/material.dart';

class AppImageViewer extends StatelessWidget {
  const AppImageViewer({
    super.key,
    required this.imageProvider,
    this.title = 'Preview',
  });

  final ImageProvider imageProvider;
  final String title;

  static void show(BuildContext context, ImageProvider provider, {String title = 'Preview'}) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return AppImageViewer(imageProvider: provider, title: title);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! > 500 || details.primaryVelocity! < -500) {
            Navigator.of(context).pop();
          }
        },
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Center(
            child: Hero(
              tag: imageProvider.hashCode.toString(),
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
