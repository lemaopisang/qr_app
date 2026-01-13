import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr/qr.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

const Color primaryColor = Color(0xFF3A2EC3);

const List<Color> qrColors = [
  Colors.white,
  Colors.grey,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.cyan,
  Colors.purple,
];

const String _logoAsset = 'assets/images/scan-icon.png';
const int _maxInputLength = 280;

enum QrVectorFormat { svg, pdf }

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Key _inputFieldKey = UniqueKey();
  String? _inputError;

  String? _qrData;
  Color _qrColor = Colors.white;

  bool get _canShare =>
      _qrData != null && _qrData!.isNotEmpty && _inputError == null;

  Future<void> _shareQr() async {
    if (!_canShare) return;

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    await Future.delayed(const Duration(milliseconds: 100));
    final Uint8List? imageBytes = await _screenshotController.capture(
      pixelRatio: pixelRatio,
    );

    if (imageBytes != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              imageBytes,
              name: 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png',
              mimeType: 'image/png',
            ),
          ],
        ),
      );
    }
  }

  void _resetFields() {
    setState(() {
      _qrData = null;
      _qrColor = Colors.white;
      _inputError = null;
      _inputFieldKey = UniqueKey();
    });
  }

  void _handleInput(String value) {
    final trimmed = value.trim();
    final error = _validateInput(trimmed);
    setState(() {
      _inputError = error;
      _qrData = trimmed.isEmpty ? null : trimmed;
    });
  }

  String? _validateInput(String value) {
    if (value.isEmpty) return null;
    if (value.length > _maxInputLength) {
      return 'Maksimal $_maxInputLength karakter';
    }
    if (_looksLikeUrl(value)) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
        return 'URL tidak valid';
      }
    }
    return null;
  }

  bool _looksLikeUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        value.contains('.');
  }

  Future<void> _exportVector(QrVectorFormat format) async {
    if (!_canShare) return;
    final matrix = _buildQrMatrix(_qrData!);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    Uint8List bytes;
    String name;
    String mime;
    if (format == QrVectorFormat.svg) {
      final svg = _buildSvg(matrix);
      bytes = Uint8List.fromList(utf8.encode(svg));
      name = 'qrcode_$timestamp.svg';
      mime = 'image/svg+xml';
    } else {
      bytes = await _buildPdf(matrix);
      name = 'qrcode_$timestamp.pdf';
      mime = 'application/pdf';
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: mime)],
      ),
    );
  }

  List<List<bool>> _buildQrMatrix(String data) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    return List.generate(
      qrImage.moduleCount,
      (y) => List.generate(qrImage.moduleCount, (x) => qrImage.isDark(y, x)),
    );
  }

  String _buildSvg(List<List<bool>> matrix) {
    const moduleSize = 10;
    final totalSize = matrix.length * moduleSize;
    final buffer = StringBuffer()
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" width="$totalSize" height="$totalSize" viewBox="0 0 $totalSize $totalSize">',
      )
      ..writeln(
        '<rect width="$totalSize" height="$totalSize" fill="${_colorToHex(_qrColor)}"/>',
      );

    for (var y = 0; y < matrix.length; y++) {
      for (var x = 0; x < matrix.length; x++) {
        if (!matrix[y][x]) continue;
        final left = x * moduleSize;
        final top = y * moduleSize;
        buffer.writeln(
          '<rect x="$left" y="$top" width="$moduleSize" height="$moduleSize" fill="#000"/>',
        );
      }
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  Future<Uint8List> _buildPdf(List<List<bool>> matrix) async {
    final doc = pw.Document();
    const double moduleSize = 8;
    final double qrSize = matrix.length * moduleSize;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Center(
            child: pw.Container(
              width: qrSize,
              height: qrSize,
              color: PdfColors.white,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: matrix.map((row) {
                  return pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: row.map((cell) {
                      return pw.Container(
                        width: moduleSize,
                        height: moduleSize,
                        color: cell ? PdfColors.black : PdfColors.white,
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  String _colorToHex(Color color) {
    final rgb = color.value.toRadixString(16).padLeft(8, '0');
    return '#${rgb.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: 220, color: primaryColor),
              Expanded(child: Container(color: Colors.grey.shade50)),
            ],
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Screenshot(
                          controller: _screenshotController,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _qrColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black12,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _qrData == null || _qrData!.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'Masukkan teks/link untuk generate QR',
                                      style: TextStyle(
                                        color: _qrColor.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : PrettyQrView.data(
                                    data: _qrData!,
                                    decoration: const PrettyQrDecoration(
                                      shape: PrettyQrSmoothSymbol(),
                                      image: PrettyQrDecorationImage(
                                        image: const AssetImage(_logoAsset),
                                        fit: BoxFit.contain,
                                        scale: 0.22,
                                        padding: const EdgeInsets.all(6),
                                        position:
                                            PrettyQrDecorationImagePosition
                                                .embedded,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          key: _inputFieldKey,
                          decoration: InputDecoration(
                            labelText: 'Link atau Teks',
                            hintText: 'https://example.com atau teks apa saja',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            errorText: _inputError,
                          ),
                          maxLines: 3,
                          maxLength: _maxInputLength,
                          onChanged: _handleInput,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pilih Warna Background QR',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: qrColors.map((color) {
                            final bool isSelected = _qrColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _qrColor = color),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetFields,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _canShare ? _shareQr : null,
                                icon: const Icon(Icons.share),
                                label: const Text('Share QR'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canShare
                                    ? () => _exportVector(QrVectorFormat.svg)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                child: const Text('Export SVG'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canShare
                                    ? () => _exportVector(QrVectorFormat.pdf)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                ),
                                child: const Text('Export PDF'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
