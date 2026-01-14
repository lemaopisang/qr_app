import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_app/core/constants/history_keys.dart';
import 'package:qr_app/core/utils/qr_export.dart';
import 'package:qr_app/models/qr_history_entry.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_detail_screen.dart';
import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 5;

  final _entries = <QrHistoryEntry>[];
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(generatorHistoryKey) ?? [];
    final loaded = raw.map((entry) => QrHistoryEntry.fromJson(entry)).toList();
    setState(() {
      _entries
        ..clear()
        ..addAll(loaded);
      _currentPage = 0;
      _isLoading = false;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(generatorHistoryKey, _entries.map((e) => e.toJson()).toList());
  }

  Future<void> _shareEntry(QrHistoryEntry entry) async {
    if (kIsWeb) {
      _showSnack('Sharing QR images is not supported on the web.');
      return;
    }

    File? file = entry.imagePath.isNotEmpty ? File(entry.imagePath) : null;
    if (file == null || !await file.exists()) {
      final bytes = entry.imageBytes;
      if (bytes == null) {
        _showSnack('QR tidak ditemukan :(');
        return;
      }
      file = await _writeShareTempFile(bytes, entry.label, entry.format);
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: entry.label.isNotEmpty ? entry.label : 'QR S&G',
        ),
      );
    } catch (error) {
      _showSnack('Gagal berbagi: $error');
    }
  }

  Future<void> _printEntry(QrHistoryEntry entry) async {
    await _showLoadingWhile(() async {
      final matrix = buildQrMatrix(entry.value);
      final pdfBytes = await buildQrPdf(matrix, Colors.white);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'QR_History_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    });
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

  Future<bool?> _confirmAction(String title, String description) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Lanjutkan')),
        ],
      ),
    );
  }

  Future<File> _writeShareTempFile(Uint8List bytes, String label, QrExportFormat format) async {
    final tempDir = await getTemporaryDirectory();
    final name = _sanitizeFileName(label.isNotEmpty ? label : 'QR_${format.label}', format.extension);
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _sanitizeFileName(String base, String extension) {
    final sanitized = base
        .replaceAll(RegExp(r'[^A-Za-z0-9\-_. ]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
    final safeBase = sanitized.isEmpty ? 'QR' : sanitized;
    return '${safeBase}_share.$extension';
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _ensurePageWithinBounds() {
    if (_entries.isEmpty) {
      _currentPage = 0;
      return;
    }
    final maxPage = (_entries.length - 1) ~/ _pageSize;
    if (_currentPage > maxPage) {
      _currentPage = maxPage;
    }
  }

  List<QrHistoryEntry> get _currentPageEntries {
    final start = _currentPage * _pageSize;
    final end = min(start + _pageSize, _entries.length);
    return _entries.sublist(start, end);
  }

  int get _totalPages {
    if (_entries.isEmpty) return 1;
    return (_entries.length / _pageSize).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat QR'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('History is empty. Create a new QR first.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _currentPageEntries.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) => _buildTile(_currentPageEntries[index]),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FilledButton.icon(
                            onPressed: _currentPage > 0
                                ? () => setState(() {
                                      _currentPage--;
                                    })
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            label: const Text('Sebelumnya'),
                          ),
                          Text('Halaman ${_currentPage + 1} dari $_totalPages'),
                          FilledButton.icon(
                            onPressed: _currentPage < _totalPages - 1
                                ? () => setState(() {
                                      _currentPage++;
                                    })
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            label: const Text('Berikutnya'),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_entries.isEmpty) return;
          final confirmed = await _confirmAction('Hapus seluruh riwayat?', 'Tidak bisa dikembalikan.');
          if (confirmed != true) return;
          setState(() => _entries.clear());
          await _saveHistory();
          _showSnack('Riwayat dibersihkan.');
          _ensurePageWithinBounds();
        },
        child: const Icon(Icons.delete_forever),
      ),
    );
  }

  Widget _buildTile(QrHistoryEntry entry) {
    final formattedLabel = entry.label.isNotEmpty ? entry.label : 'QR ${entry.format.label}';
    return ListTile(
      title: Text(formattedLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(entry.value, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(entry.timestamp.toLocal().toString()),
              const SizedBox(width: 12),
              Chip(
                label: Text(entry.format.label),
                backgroundColor: Colors.grey.shade200,
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
      leading: _HistoryTileThumbnail(entry: entry),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () => _shareEntry(entry)),
          IconButton(icon: const Icon(Icons.print), onPressed: () => _printEntry(entry)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await _confirmAction('Hapus entry?', 'Tidak bisa dikembalikan.');
              if (confirmed != true) return;
              setState(() {
                _entries.remove(entry);
                _ensurePageWithinBounds();
              });
              await _saveHistory();
              _showSnack('Entry dihapus.');
            },
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HistoryDetailScreen(entry: entry)),
        );
      },
    );
  }
}


class _HistoryTileThumbnail extends StatelessWidget {
  const _HistoryTileThumbnail({required this.entry});

  final QrHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isImageFormat = entry.format == QrExportFormat.png || entry.format == QrExportFormat.jpg;
    final imageBytes = entry.imageBytes;
    if (isImageFormat && imageBytes != null) {
      return SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(imageBytes, fit: BoxFit.cover),
        ),
      );
    }
    final file = entry.imagePath.isNotEmpty ? File(entry.imagePath) : null;
    if (isImageFormat && file != null && file.existsSync()) {
      return SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, fit: BoxFit.cover),
        ),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.grey.shade200,
      child: Text(entry.format.label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
