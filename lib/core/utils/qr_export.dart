import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

const String _logoAsset = 'assets/images/scan-icon.png';

List<List<bool>> buildQrMatrix(String data) {
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

String buildQrSvg(List<List<bool>> matrix, Color backgroundColor) {
  const moduleSize = 10;
  final totalSize = matrix.length * moduleSize;
  final buffer = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$totalSize" height="$totalSize" viewBox="0 0 $totalSize $totalSize">',
    )
    ..writeln(
      '<rect width="$totalSize" height="$totalSize" fill="${_colorToHex(backgroundColor)}"/>',
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

Future<Uint8List> buildQrPdf(List<List<bool>> matrix, Color backgroundColor) async {
  final doc = pw.Document();
  const double moduleSize = 8;
  final double qrSize = matrix.length * moduleSize;
  final logoImage = await _loadLogoImage();

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Stack(
          children: [
            if (logoImage != null)
              pw.Positioned(
                top: 16,
                right: 16,
                child: pw.Opacity(
                  opacity: 0.3,
                  child: pw.Image(logoImage, width: 80, height: 80),
                ),
              ),
            pw.Center(
                child: pw.Container(
                  width: qrSize,
                  height: qrSize,
                  decoration: pw.BoxDecoration(
                    color: _pdfColor(backgroundColor),
                  ),
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
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

Future<pw.MemoryImage?> _loadLogoImage() async {
  try {
    final data = await rootBundle.load(_logoAsset);
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

String _colorToHex(Color color) {
  final rgb = color.value.toRadixString(16).padLeft(8, '0');
  return '#${rgb.substring(2)}';
}

PdfColor _pdfColor(Color color) {
  return PdfColor(
    color.red / 255,
    color.green / 255,
    color.blue / 255,
    color.alpha / 255,
  );
}
