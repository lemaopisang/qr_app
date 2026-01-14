import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_app/models/qr_history_entry.dart';
import 'package:qr_app/ui/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_app/core/constants/history_keys.dart';

void main() {
  testWidgets('shows entries stored in shared preferences', (tester) async {
    final entry = QrHistoryEntry(
      value: 'Hello',
      label: 'Test QR',
      imagePath: 'path/to/file.png',
      timestamp: DateTime.parse('2025-01-01T12:00:00.000Z'),
      format: QrExportFormat.png,
    );
    SharedPreferences.setMockInitialValues({
      generatorHistoryKey: [entry.toJson()],
    });

    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Test QR'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });
}
