import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/primary_button.dart';
import '../models/scan_history.dart';
import 'qr_generator/qr_generator_screen.dart';
import 'qr_scanner/qr_scanner_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static final _history = [
    ScanHistory(
      content: 'https://example.com/invite',
      timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
      isGenerated: true,
    ),
    ScanHistory(
      content: 'Sample QR Scan',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isGenerated: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Generate QR',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QrGeneratorScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  label: 'Scan QR',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const QrScannerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Recent history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ..._history.map(
            (history) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  history.isGenerated ? Icons.qr_code : Icons.qr_code_scanner,
                  color: AppColors.primary,
                ),
                title: Text(history.content),
                subtitle: Text(history.timestamp.toLocal().toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
