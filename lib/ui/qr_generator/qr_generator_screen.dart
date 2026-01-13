import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:qr_app/core/constants/history_keys.dart';
import 'package:qr_app/core/utils/qr_export.dart';

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
const String _generatorHistoryKey = 'generator_history';

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

  bool get _canSave => _qrData != null && _qrData!.isNotEmpty;

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

  Future<void> _saveGenerated() async {
    if (!_canSave) return;
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(generatorHistoryKey) ?? [];
    final entry = jsonEncode({
          'value': _qrData,
      'timestamp': DateTime.now().toIso8601String(),
    });
    history.insert(0, entry);
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await prefs.setStringList(_generatorHistoryKey, history);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR tersimpan ke riwayat.')));
    Navigator.pop(context);
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

  Future<void> _downloadVector(QrVectorFormat format) async {
    if (!_canSave) return;

    Future<void> saveTask() async {
      final matrix = buildQrMatrix(_qrData!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final bytes = format == QrVectorFormat.svg
          ? Uint8List.fromList(utf8.encode(buildQrSvg(matrix, _qrColor)))
          : await buildQrPdf(matrix, _qrColor);
      final extension = format == QrVectorFormat.svg ? 'svg' : 'pdf';

      final directory = format == QrVectorFormat.pdf
          ? (await getDownloadsDirectory() ??
              (throw StateError('Folder Downloads tidak tersedia')))
          : await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/qrcode_$timestamp.$extension');
      await file.writeAsBytes(bytes);
      _showSnack('Disimpan ke ${file.path}');

      if (format == QrVectorFormat.pdf) {
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          _showSnack('Gagal membuka file: ${result.message}');
        }
      }
    }

    try {
      if (format == QrVectorFormat.pdf) {
        await _showLoadingWhile(saveTask);
      } else {
        await saveTask();
      }
    } catch (e) {
      _showSnack('Gagal menyimpan: $e');
    }
  }

  Future<void> _saveAndPrint() async {
    if (!_canSave) return;
    final format = await _showSavePrintDialog();
    if (format == null) return;
    await _downloadVector(format);
    await _printQrDocument();
  }

  Future<QrVectorFormat?> _showSavePrintDialog() async {
    QrVectorFormat selection = QrVectorFormat.svg;
    return showDialog<QrVectorFormat>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Type of File?'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<QrVectorFormat>(
                value: selection,
                decoration: const InputDecoration(
                  labelText: 'Pilih format',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: QrVectorFormat.svg,
                    child: Text('SVG'),
                  ),
                  DropdownMenuItem(
                    value: QrVectorFormat.pdf,
                    child: Text('PDF'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selection = value);
                  }
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selection),
              child: const Text('Print'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printQrDocument() async {
    await _showLoadingWhile(() async {
      final imageBytes = await _captureQrSnapshot(pixelRatio: 3.0);
      if (imageBytes == null) {
        _showSnack('Gagal menangkap QR untuk mencetak.');
        return;
      }
      try {
        final pdf = pw.Document();
        final qrImage = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'QR Code Generated',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Image(qrImage, width: 200, height: 200),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'Link/Teks: ${_qrData ?? '-'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Dibuat oleh: QR S&G App',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        );
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
          name: 'QR_Code_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      } catch (e) {
        _showSnack('Gagal print: $e');
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<Uint8List?> _captureQrSnapshot({double pixelRatio = 2.0}) async {
    return await _screenshotController.capture(pixelRatio: pixelRatio);
  }

  @override
  Widget build(BuildContext context) {
    final saveButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.grey.shade300
            : const Color(0xFF80EF80);
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.black
            : Colors.white;
      }),
    );

    final downloadButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.grey.shade300
            : const Color(0xFF00EEEE);
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.black
            : Colors.white;
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _canShare ? _shareQr : null,
          ),
        ],
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
                              child: ElevatedButton(
                                onPressed: _canSave ? _saveGenerated : null,
                                style: saveButtonStyle,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canSave
                                    ? () => _downloadVector(QrVectorFormat.svg)
                                    : null,
                                style: downloadButtonStyle,
                                child: const Text('Download SVG'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canSave
                                    ? () => _downloadVector(QrVectorFormat.pdf)
                                    : null,
                                style: downloadButtonStyle,
                                child: const Text('Download PDF'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canSave ? _saveAndPrint : null,
                            style: downloadButtonStyle,
                            child: const Text('Save & Print'),
                          ),
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
