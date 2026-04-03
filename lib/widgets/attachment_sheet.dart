import 'package:flutter/material.dart';
import '../service.dart';
import '../image.dart';

class AttachmentSheet extends StatefulWidget {
  const AttachmentSheet({
    super.key,
    required this.onAttached,
    this.allowMultipleFromGallery = true,
  });

  final Function(List<AttachedFile>) onAttached;
  final bool allowMultipleFromGallery;

  @override
  State<AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<AttachmentSheet> {
  bool _showUploadOptions = false;
  bool _showCaptureOptions = false;
  bool _isProcessing = false;

  void _handleFiles(BuildContext context, List<AttachedFile>? files) {
    if (files != null && files.isNotEmpty) {
      debugPrint('AttachmentSheet: _handleFiles called with ${files.length} files');
      widget.onAttached(files);
      debugPrint('AttachmentSheet: widget.onAttached callback executed');
      Navigator.pop(context);
    } else {
      debugPrint('AttachmentSheet: _handleFiles called with null or empty list');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final showBack = (_showUploadOptions || _showCaptureOptions) && !_isProcessing;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, bottom + 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A25),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (showBack)
                      IconButton(
                        onPressed: () => setState(() {
                          _showUploadOptions = false;
                          _showCaptureOptions = false;
                        }),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (showBack) const SizedBox(width: 12),
                    Text(
                      _getTitle(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (!_isProcessing)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white24),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (_isProcessing) return 'Working...';
    if (_showCaptureOptions) return 'Capture';
    if (_showUploadOptions) return 'Upload From';
    return 'Add Attachments';
  }

  Widget _buildContent() {
    if (_isProcessing) return _buildLoadingState();
    if (_showCaptureOptions) return _buildCaptureOptions();
    if (_showUploadOptions) return _buildUploadOptions();
    return _buildMainOptions();
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C6AF6)),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Processing attachment...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOptions() {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.camera_enhance_rounded,
          label: 'Capture',
          color: const Color(0xFF7C6AF6),
          onTap: () => setState(() => _showCaptureOptions = true),
        ),
        const SizedBox(width: 16),
        _ActionTile(
          icon: Icons.cloud_upload_rounded,
          label: 'Upload',
          color: const Color(0xFF50D1AA),
          onTap: () => setState(() => _showUploadOptions = true),
        ),
      ],
    );
  }

  Widget _buildCaptureOptions() {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.camera_alt_rounded,
          label: 'Take Photo',
          color: const Color(0xFF7C6AF6),
          onTap: () async {
            setState(() => _isProcessing = true);
            try {
              debugPrint('AttachmentSheet: Take Photo tapped');
              final file = await AppImageUtils.instance.takeImage();
              debugPrint('AttachmentSheet: takeImage returned: ${file?.path}');
              if (mounted && file != null) {
                _handleFiles(context, [AttachedFile.fromPath(file.path)]);
              } else {
                if (mounted) setState(() => _isProcessing = false);
              }
            } catch (e) {
              debugPrint('AttachmentSheet error in takeImage: $e');
              if (mounted) setState(() => _isProcessing = false);
            }
          },
        ),
        const SizedBox(width: 16),
        _ActionTile(
          icon: Icons.document_scanner_rounded,
          label: 'Scan Doc',
          color: const Color(0xFF9D6AF6),
          onTap: () async {
            setState(() => _isProcessing = true);
            try {
              debugPrint('AttachmentSheet: Scan Doc tapped');
              final result = await AttachmentService.instance.scanDocument();
              debugPrint('AttachmentSheet: scanDocument returned: ${result?.path}');
              if (mounted && result != null) {
                _handleFiles(context, [result]);
              } else {
                if (mounted) setState(() => _isProcessing = false);
              }
            } catch (e) {
              debugPrint('AttachmentSheet error in scanDocument: $e');
              if (mounted) setState(() => _isProcessing = false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildUploadOptions() {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.photo_library_rounded,
          label: 'Photos',
          color: const Color(0xFF50D1AA),
          onTap: () async {
            setState(() => _isProcessing = true);
            try {
              final file = await AppImageUtils.instance.pickImage();
              if (mounted && file != null) {
                _handleFiles(context, [AttachedFile.fromPath(file.path)]);
              } else {
                if (mounted) setState(() => _isProcessing = false);
              }
            } catch (e) {
              debugPrint('AttachmentSheet error in pickImage: $e');
              if (mounted) setState(() => _isProcessing = false);
            }
          },
        ),
        const SizedBox(width: 16),
        _ActionTile(
          icon: Icons.folder_rounded,
          label: 'Files',
          color: const Color(0xFFFFB347),
          onTap: () async {
            setState(() => _isProcessing = true);
            try {
              final result = await AttachmentService.instance.pickFile();
              if (mounted && result != null) {
                _handleFiles(context, [result]);
              } else {
                if (mounted) setState(() => _isProcessing = false);
              }
            } catch (e) {
              debugPrint('AttachmentSheet error in pickFile: $e');
              if (mounted) setState(() => _isProcessing = false);
            }
          },
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
