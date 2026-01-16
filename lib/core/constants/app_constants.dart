import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const appName = 'TheQR';
  static const defaultPadding = 16.0;
  static const defaultBorderRadius = 12.0;
  static const shadows = [
    BoxShadow(
      color: Color(0x1F1E1E1E),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
}
