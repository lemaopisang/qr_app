import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _scanHistoryKey = 'scan_history';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _torchOn = false;
  List<Map<String, dynamic>> _scanHistory = [];
  String? _barcodeValue;
  bool _guideShown = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _requestCameraPermission();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_guideShown) return;
      _guideShown = true;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ScanGuideBottomSheet(),
      );
    });
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      _controller.start();
      return;
    }
    final result = await Permission.camera.request();
    if (result.isGranted) {
      _controller.start();
    } else if (result.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scanHistoryKey) ?? [];
    final decoded = raw
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .toList();
    setState(() => _scanHistory = decoded);
  }

  Future<void> _saveHistory(String value) async {
    final entry = {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      _scanHistory.insert(0, entry);
      if (_scanHistory.length > 5) {
        _scanHistory.removeRange(5, _scanHistory.length);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scanHistoryKey,
      _scanHistory.map(jsonEncode).toList(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _handleBarcode(BarcodeCapture capture) {
    final Uint8List? image = capture.image;
    if (capture.barcodes.isEmpty || image == null) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    _controller.stop();
    setState(() => _barcodeValue = rawValue);
    _saveHistory(rawValue);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('QR Terdeteksi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(image, height: 180),
            const SizedBox(height: 16),
            SelectableText(
              _barcodeValue!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _barcodeValue!));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Disalin ke clipboard')),
              );
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('Tutup'),
            onPressed: () {
              Navigator.pop(ctx);
              _controller.start();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFlash() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            placeholderBuilder: (context) =>
                const Center(child: CircularProgressIndicator()),
          ),
          Center(
            child: CustomPaint(
              size: Size(280, 280),
              painter: ScannerOverlayPainter(),
            ),
          ),
          if (_scanHistory.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Riwayat Scan Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ..._scanHistory.take(3).map((entry) {
                      final timestamp = entry['timestamp'] as String?;
                      final parsed = timestamp != null
                          ? DateTime.tryParse(timestamp)?.toLocal()
                          : null;
                      final formattedTime = parsed != null
                          ? '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}'
                          : 'waktu tidak tersedia';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry['value'] as String? ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedTime,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'flash_toggle',
              backgroundColor: Colors.black45,
              onPressed: _toggleFlash,
              child: Icon(_torchOn ? Icons.flash_off : Icons.flash_on),
            ),
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Arahkan QR Code ke dalam kotak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    const cornerLength = 30.0;
    final path = Path();

    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    path.moveTo(0, size.height - cornerLength);
    path.lineTo(0, size.height);
    path.lineTo(cornerLength, size.height);

    path.moveTo(size.width - cornerLength, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanGuideBottomSheet extends StatelessWidget {
  const ScanGuideBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan QR Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Arahkan kamera ke QR Code di dalam kotak agar hasil lebih akurat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Image.asset('assets/images/scan-icon.png', width: 200, height: 200),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mulai Scan'),
          ),
        ],
      ),
    );
  }
}
