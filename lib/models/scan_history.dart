class ScanHistory {
  ScanHistory({
    required this.content,
    required this.timestamp,
    required this.isGenerated,
  });

  final String content;
  final DateTime timestamp;
  final bool isGenerated;
}
