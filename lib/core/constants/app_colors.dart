import 'package:flutter/material.dart';

/// App color palette - Blue-themed design
class AppColors {
  AppColors._();

  // Primary Blues - Lighter and softer
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color vibrantBlue = Color(0xFF42A5F5);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color mediumBlue = Color(0xFF64B5F6);
  
  // Accent Colors - Softer tones
  static const Color accentCyan = Color(0xFF26C6DA);
  static const Color accentTeal = Color(0xFF26A69A);
  static const Color accentPurple = Color(0xFF7E57C2);
  static const Color accentIndigo = Color(0xFF5C6BC0);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentAmber = Color(0xFFFFC107);
  
  // Backgrounds
  static const Color scaffoldBackground = Color(0xFFF5F9FC);
  static const Color cardBackground = Colors.white;
  static const Color lightBackground = Color(0xFFF0F4F8);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  
  // Functional Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Gradients - Lighter and more subtle
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
  );
  
  static const LinearGradient createGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF26C6DA), Color(0xFF4DD0E1)],
  );
  
  static const LinearGradient scanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
  );
  
  static const LinearGradient historyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF64B5F6), Color(0xFF90CAF9)],
  );
  
  // Shadow
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
}
