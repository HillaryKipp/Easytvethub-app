import 'package:flutter/material.dart';

class AppColors {
  static const purple = Color(0xFF662C91);
  static const purpleDark = Color(0xFF4B1F6F);
  static const purpleDeep = Color(0xFF1F0F33);
  static const purpleGradientEnd = Color(0xFF3A1856);
  static const purpleTint = Color(0xFFF4EFF9);
  static const purpleSoft = Color(0xFFF8F5FD);

  static const red = Color(0xFFBD1E2C);
  static const redDark = Color(0xFF9C1824);
  static const redTint = Color(0xFFFBECED);
  static const green = Color(0xFF006838);
  static const greenTint = Color(0xFFECFDF3);

  static const ink = Color(0xFF1D1823);
  static const text = Color(0xFF5C5766);
  static const muted = Color(0xFF8B8794);
  static const line = Color(0xFFEBE7F0);
  static const lineStrong = Color(0xFFD9D3E2);
  static const surface = Color(0xFFF7F5FA);
  static const white = Color(0xFFFFFFFF);

  // Secondary Framework & Badge Accents
  static const teal = Color(0xFF0F766E);
  static const tealTint = Color(0xFFF0FDFA);
  static const amber = Color(0xFFB45309);
  static const skyText = Color(0xFF0369A1);
  static const skyTint = Color(0xFFF0F9FF);
  static const amberBadgeText = Color(0xFF92400E);
  static const amberBadgeTint = Color(0xFFFFFBEB);

  static const heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purpleDark, purple, purpleGradientEnd],
  );

  static const cardShadow = [
    BoxShadow(
      color: Color(0x0A1F0F33), // rgba(31, 15, 51, 0.04)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
