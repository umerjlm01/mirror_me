import 'package:flutter/material.dart';

class ShareCardTheme {
  static const double cardWidth = 360;
  static const double cardHeight = 640;
  static const double exportPixelRatio = 3;
  static const double cardRadius = 28;

  static const Color baseBackground = Color(0xFF08111F);
  static const Color surface = Color(0x26FFFFFF);
  static const Color surfaceStrong = Color(0x30FFFFFF);
  static const Color border = Color(0x40FFFFFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xCCDBE7FF);
  static const Color accent = Color(0xFFFF8A5B);
  static const Color accentSecondary = Color(0xFF58E1FF);
  static const Color accentSoft = Color(0xFF8B7CFF);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF07111F),
      Color(0xFF0A1F39),
      Color(0xFF1E1848),
      Color(0xFF401B38),
    ],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentSecondary],
  );

  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 18)),
  ];
}
