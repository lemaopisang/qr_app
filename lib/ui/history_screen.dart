import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:qr_app/core/constants/history_keys.dart';
import 'package:qr_app/core/utils/qr_export.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<_HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<_HistoryEntry>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawEntries = prefs.getStringList(generatorHistoryKey) ?? [];
    return rawEntries.map((entry) {
      final parsed = jsonDecode(entry) as Map<String, dynamic>;
      return _HistoryEntry(
        value: parsed['value'] as String? ?? '',
        timestamp: DateTime.tryParse(parsed['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  Future<void> _shareEntry(String value) async {
    try {
      await Share.share(value, subject: 'QR S&G');
    } catch (error) {
      _showSnack('Gagal berbagi: $error');
    }
  }

  Future<void> _printEntry(String value) async {
    try {
      final matrix = buildQrMatrix(value);
      final bytes = await buildQrPdf(matrix, Colors.white);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'QR_History_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (error) {
      _showSnack('Gagal print: $error');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat QR'),
      ),
      body: FutureBuilder<List<_HistoryEntry>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data;
          if (entries == null || entries.isEmpty) {
            return const Center(
              child: Text('Riwayat kosong. Kunjungi fitur Create untuk menyimpan QR baru.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                title: Text(entry.value, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(entry.timestamp.toLocal().toString()),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () => _shareEntry(entry.value),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => _printEntry(entry.value),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.value, required this.timestamp});

  final String value;
  final DateTime timestamp;
}
