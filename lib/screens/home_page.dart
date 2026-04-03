import 'package:flutter/material.dart';

import '../service.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/attachment_thumbnail.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final List<AttachedFile> _attachments = [];

  void _showAttachmentSheet(String module) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AttachmentSheet(
        onAttached: (files) {
          setState(() {
            _attachments.addAll(files);
          });
        },
      ),
    );
  }

  void _deleteAttachment(String module, int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attachment Studio'),
      ),
      body: _buildModuleView('Service'),
    );
  }

  Widget _buildModuleView(String module) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(_attachments.length),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _attachments.length + 1,
              itemBuilder: (context, index) {
                if (index == _attachments.length) {
                  return AddAttachmentSlot(
                    onTap: () => _showAttachmentSheet(module),
                  );
                }
                return AttachmentThumbnail(
                  file: _attachments[index],
                  onDelete: () => _deleteAttachment(module, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attach inspection reports and service logs.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF7C6AF6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7C6AF6).withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count attachment${count == 1 ? '' : 's'} added',
            style: const TextStyle(
              color: Color(0xFF7C6AF6),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
