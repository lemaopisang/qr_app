import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/format_utils.dart';
import '../../core/widgets/primary_button.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  String? _scanned;

  void _startScan() {
    setState(() {
      _scanned = 'Sample Scan Code: ${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, size: 80),
              ),
            ),
            const Text(
              'Point your camera to a QR code to see the decoded value appear below.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Start Scan', onPressed: _startScan),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: _scanned == null
                    ? const Center(
                        child: Text(
                          'No scan data yet, tap start to simulate a camera scan.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Decoded data',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(_scanned!),
                          const Spacer(),
                          Text('Captured ${FormatUtils.elapsed(DateTime.now())}'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
