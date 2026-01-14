import 'dart:convert';
import 'dart:typed_data';

enum QrExportFormat { png, jpg, svg, pdf }

extension QrExportFormatX on QrExportFormat {
  String get label => name.toUpperCase();

  String get extension => name;
}

class QrHistoryEntry {
  const QrHistoryEntry({
    required this.value,
    required this.label,
    required this.imagePath,
    required this.timestamp,
    required this.format,
    this.imageData,
  });

  final String value;
  final String label;
  final String imagePath;
  final String? imageData;
  final DateTime timestamp;
  final QrExportFormat format;

  Map<String, dynamic> toMap() => {
        'value': value,
        'label': label,
        'imagePath': imagePath,
        'timestamp': timestamp.toIso8601String(),
        'format': format.name,
        if (imageData != null) 'imageData': imageData,
      };

  String toJson() => jsonEncode(toMap());

  factory QrHistoryEntry.fromMap(Map<String, dynamic> map) {
    final rawFormat = map['format'] as String? ?? QrExportFormat.png.name;
    final format = QrExportFormat.values.firstWhere(
      (element) => element.name == rawFormat,
      orElse: () => QrExportFormat.png,
    );

    return QrHistoryEntry(
      value: map['value'] as String? ?? '',
      label: map['label'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      format: format,
      imageData: map['imageData'] as String?,
    );
  }

  factory QrHistoryEntry.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return QrHistoryEntry.fromMap(map);
  }

  Uint8List? get imageBytes =>
      imageData == null ? null : base64Decode(imageData!);
}
