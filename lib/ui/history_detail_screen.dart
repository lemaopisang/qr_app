import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:printing/printing.dart';
import 'package:qr_app/core/utils/qr_export.dart';
import 'package:qr_app/models/qr_history_entry.dart';
import 'package:share_plus/share_plus.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.entry});

  final QrHistoryEntry entry;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  Future<void> _shareEntry() async {
    final file = File(widget.entry.imagePath);
    if (!await file.exists()) {
      _showSnack('QR not found :(');
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: widget.entry.label.isNotEmpty ? widget.entry.label : 'QR S&G',
        ),
      );
    } catch (error) {
      _showSnack('Failed to share: $error');
    }
  }

  Future<void> _printEntry() async {
    await _showLoadingWhile(() async {
      final matrix = buildQrMatrix(widget.entry.value);
      final pdfBytes = await buildQrPdf(matrix, Colors.white);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'QR_History_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    });
  }

  Future<T> _showLoadingWhile<T>(Future<T> Function() task) async {
    if (!mounted) return task();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      return await task();
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildPreviewImage() {
    final isImageFormat =
        widget.entry.format == QrExportFormat.png || widget.entry.format == QrExportFormat.jpg;
    final imageBytes = widget.entry.imageBytes;
    if (isImageFormat && imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.memory(
          imageBytes,
          width: double.infinity,
          height: 280,
          fit: BoxFit.cover,
        ),
      );
    }
    final file = widget.entry.imagePath.isNotEmpty ? File(widget.entry.imagePath) : null;
    if (isImageFormat && file != null && file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          file,
          width: double.infinity,
          height: 280,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: PrettyQrView.data(
            data: widget.entry.value,
            decoration: const PrettyQrDecoration(
              shape: PrettyQrSmoothSymbol(),
              image: PrettyQrDecorationImage(
                image: AssetImage('assets/images/scan-icon.png'),
                fit: BoxFit.contain,
                scale: 0.22,
                padding: EdgeInsets.all(6),
                position: PrettyQrDecorationImagePosition.embedded,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.entry.label.isNotEmpty
        ? widget.entry.label
        : 'QR ${widget.entry.format.label}';

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareEntry,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printEntry,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildPreviewImage(),
          const SizedBox(height: 24),
          Text('Name', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Contents', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(widget.entry.value, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Saved on', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(widget.entry.timestamp.toLocal().toString(), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Format', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Chip(label: Text(widget.entry.format.label)),
        ],
      ),
    );
  }
}
