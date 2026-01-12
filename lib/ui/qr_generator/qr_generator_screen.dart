import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/primary_button.dart';

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _controller = TextEditingController();
  String? _generated;

  void _generate() {
    setState(() {
      _generated = _controller.text.trim().isEmpty
          ? 'https://example.com/qr/123'
          : _controller.text.trim();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Generator')),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          const Text(
            'Enter a value to create a QR code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Text / URL',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Generate',
            onPressed: _generate,
            icon: const Icon(Icons.qr_code),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              boxShadow: AppConstants.shadows,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _generated ?? 'Preview will appear here',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Icon(
                    Icons.qr_code,
                    size: 112,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'QR image is generated on device. Tap share to copy or export.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
