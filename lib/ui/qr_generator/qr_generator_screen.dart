import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:qr_app/core/constants/app_constants.dart';
import 'package:qr_app/core/constants/history_keys.dart';
import 'package:qr_app/core/constants/app_colors.dart';
import 'package:qr_app/core/utils/qr_export.dart';
import 'package:qr_app/core/utils/web_download.dart';
import 'package:qr_app/models/qr_history_entry.dart';

const List<Color> qrColors = [
  Colors.white,
  Colors.orange,
  Colors.yellow,
  Colors.green,
  Colors.cyan,
  Colors.purple,
];

const String _logoAsset = 'assets/images/scan-icon.png';
const int _maxInputLength = 280;

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();

  Key _inputFieldKey = UniqueKey();
  String? _inputError;

  String? _qrData;
  Color _qrColor = Colors.white;
  QrExportFormat _selectedFormat = QrExportFormat.png;
  bool get _canSave => _qrData != null && _qrData!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _inputController.text = 'https://example.com';
    _qrData = _inputController.text;
  }

  void _resetFields() {
    setState(() {
      _qrData = null;
      _qrColor = Colors.white;
      _inputError = null;
      _inputFieldKey = UniqueKey();
      _nameController.clear();
      _selectedFormat = QrExportFormat.png;
      _inputController.text = 'https://example.com';
      _qrData = _inputController.text;
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
      return 'Maximum $_maxInputLength characters';
    }
    if (_looksLikeUrl(value)) {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
        return 'Unvalid Link/URL';
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

  Future<void> _printQrDocument() async {
    await _showLoadingWhile(() async {
      final imageBytes = await _captureQrSnapshot(pixelRatio: 3.0);
      if (imageBytes == null) {
        _showSnack('Failed to capture QR for printing.');
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
                      'Link/Text: ${_qrData ?? '-'}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Created by: ${AppConstants.appName} App',
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
        _showSnack('Failed to print: $e');
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

  Future<Directory?> _exportDirectoryFor(QrExportFormat format) async {
    if (format == QrExportFormat.pdf) {
      return await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<Uint8List?> _buildExportBytes(QrExportFormat format) async {
    if (!_canSave) return null;

    if (format == QrExportFormat.png || format == QrExportFormat.jpg) {
      final snapshot = await _captureQrSnapshot(pixelRatio: 3.0);
      if (snapshot == null) {
        _showSnack('Failed to capture QR for saving.');
        return null;
      }
      final normalized = _normalizedSnapshot(snapshot, format);
      if (normalized == null) {
        _showSnack('Failed to process QR image.');
        return null;
      }
      return normalized;
    }

    final matrix = buildQrMatrix(_qrData!);
    if (format == QrExportFormat.svg) {
      return Uint8List.fromList(utf8.encode(buildQrSvg(matrix, _qrColor)));
    }
    return await buildQrPdf(matrix, _qrColor);
  }

  Future<File?> _writeExportFile(Uint8List bytes, QrExportFormat format, {bool showSuccessSnack = true}) async {
    final directory = await _exportDirectoryFor(format);
    if (directory == null) {
      _showSnack('Destination folder is not available.');
      return null;
    }

    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (e) {
      _showSnack('Failed to prepare storage folder: $e');
      return null;
    }

    final fileName = _namedExportFile(format);
    final file = File('${directory.path}/$fileName');
    try {
      await file.writeAsBytes(bytes);
    } catch (e) {
      _showSnack('Failed to write file: $e');
      return null;
    }
    if (showSuccessSnack) {
      _showSnack('Saved to ${file.path}');
    }
    if (format == QrExportFormat.pdf) {
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        _showSnack('Failed to open file: ${result.message}');
      }
    }
    return file;
  }

  Uint8List? _normalizedSnapshot(Uint8List snapshot, QrExportFormat format) {
    final decoded = img.decodeImage(snapshot);
    if (decoded == null) return null;
    final resized = img.copyResize(
      decoded,
      width: 200,
      height: 200,
      interpolation: img.Interpolation.nearest,
    );
    final grayscale = img.grayscale(resized);
    if (format == QrExportFormat.jpg) {
      return Uint8List.fromList(img.encodeJpg(grayscale, quality: 90));
    }
    return Uint8List.fromList(img.encodePng(grayscale));
  }

  Future<void> _downloadForWeb(Uint8List bytes, QrExportFormat format) async {
    final fileName = _namedExportFile(format);
    final mimeType = _mimeTypeForFormat(format);
    await downloadWebFile(bytes, fileName, mimeType);
    _showSnack('Download started.');
  }

  String _mimeTypeForFormat(QrExportFormat format) {
    switch (format) {
      case QrExportFormat.jpg:
        return 'image/jpeg';
      case QrExportFormat.svg:
        return 'image/svg+xml';
      case QrExportFormat.pdf:
        return 'application/pdf';
      case QrExportFormat.png:
        return 'image/png';
    }
  }

  Future<void> _persistHistoryEntry({File? file, Uint8List? data, required QrExportFormat format}) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(generatorHistoryKey) ?? [];
    final entry = QrHistoryEntry(
      value: _qrData!,
      label: _nameController.text.trim(),
      imagePath: file?.path ?? '',
      timestamp: DateTime.now(),
      format: format,
      imageData: data != null ? base64Encode(data) : null,
    );
    history.insert(0, entry.toJson());
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    await prefs.setStringList(generatorHistoryKey, history);
  }

  Future<void> _handleSave({bool printAfter = false, QrExportFormat? format}) async {
    if (!_canSave) return;
    final selectedFormat = format ?? _selectedFormat;
    final bytes = await _buildExportBytes(selectedFormat);
    if (bytes == null) return;

    if (kIsWeb) {
      await _persistHistoryEntry(data: bytes, format: selectedFormat);
      _showSnack('QR Saves to History!');
      await _downloadForWeb(bytes, selectedFormat);
      if (printAfter) {
        await _printQrDocument();
      }
      _navigateHomeAfterSave();
      return;
    }

    final file = await _writeExportFile(bytes, selectedFormat, showSuccessSnack: !printAfter);
    if (file == null) {
      await _handleSaveFallback(bytes, selectedFormat, printAfter);
      return;
    }
    await _persistHistoryEntry(file: file, format: selectedFormat);
    _showSnack('QR Saves to History!');
    if (printAfter) {
      await _printQrDocument();
    }
    _navigateHomeAfterSave();
  }

  Future<void> _handleSaveFallback(Uint8List bytes, QrExportFormat format, bool printAfter) async {
    _showSnack('Unable to save to device storage. Falling back to browser download where available.');
    if (!kIsWeb) {
      _showSnack('Browser download only runs in a web browser. Please enable storage permissions or run the app in web to download.');
      return;
    }
    await _persistHistoryEntry(data: bytes, format: format);
    _showSnack('QR Saves to History!');
    await _downloadForWeb(bytes, format);
    if (printAfter) {
      await _printQrDocument();
    }
    _navigateHomeAfterSave();
  }

  void _navigateHomeAfterSave() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  String _namedExportFile(QrExportFormat format) {
    final rawLabel = _nameController.text.trim();
    final base = rawLabel.isNotEmpty ? rawLabel : 'QR_${format.label}';
    final sanitized = base
      .replaceAll(RegExp(r'[^A-Za-z0-9 \-_]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();
    final safe = sanitized.isEmpty ? 'QR_${format.label}' : sanitized;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${safe}_$timestamp.${format.extension}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saveButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.grey.shade300
            : AppColors.accentCyan;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? AppColors.textSecondary
            : Colors.white;
      }),
      elevation: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled) ? 0 : 2;
      }),
    );

    final downloadButtonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? Colors.grey.shade300
            : AppColors.primaryBlue;
      }),
      foregroundColor: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled)
            ? AppColors.textSecondary
            : Colors.white;
      }),
      elevation: MaterialStateProperty.resolveWith((states) {
        return states.contains(MaterialState.disabled) ? 0 : 2;
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(height: 220, color: AppColors.primaryBlue),
              Expanded(child: Container(color: AppColors.scaffoldBackground)),
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
                      boxShadow: AppColors.cardShadow,
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
                                      'Input Text/Link for a QR preview',
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
                          controller: _inputController,
                          key: _inputFieldKey,
                          decoration: InputDecoration(
                            labelText: 'Link/Text for QR',
                            hintText: 'google.com or any text',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            errorText: _inputError,
                          ),
                          minLines: 1,
                          maxLines: 2,
                          maxLength: _maxInputLength,
                          onChanged: _handleInput,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'QR Name',
                            hintText: 'e.x: E-Report',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          maxLength: 60,
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pick a Background Color',
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pick Export Format',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: QrExportFormat.values.map((format) {
                            final isSelected = _selectedFormat == format;
                            return ChoiceChip(
                              label: Text(format.label),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() => _selectedFormat = format);
                              },
                              selectedColor: AppColors.accentCyan,
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetFields,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canSave ? () => _handleSave(format: _selectedFormat) : null,
                                style: saveButtonStyle,
                                child: const Text('Save'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _canSave
                                ? () => _handleSave(printAfter: true, format: _selectedFormat)
                                : null,
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
