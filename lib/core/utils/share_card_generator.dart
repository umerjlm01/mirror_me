import 'dart:io';

import 'dart:typed_data';

import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Generates viral share cards using Canvas drawing for the AI Face Intelligence Platform.
class ShareCardGenerator {
  /// Generates a comprehensive AI Face Intelligence Report Card
  static Future<Uint8List> generateIntelligenceCard({
    required File originalImage,
    required String celebrityName,
    required double celebrityConfidence,
    required double overallSymmetry,
    required String explanation,
    required Map<String, double> featureScores,
    int? age,
    String? gender,
  }) async {
    const width = 1080.0;
    const height = 1920.0; // Vertical format for stories
    const padding = 60.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // 1. Background
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, height),
        [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)],
      );

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. User Image
    final uiImage = await _loadUiImage(originalImage);
    final imageRect = Rect.fromLTWH(padding, 200, width - padding * 2, 800);
    _drawClippedImage(canvas, uiImage, imageRect);

    // 3. Header
    _drawText(
      canvas: canvas,
      text: 'FACE INTELLIGENCE REPORT',
      x: width / 2,
      y: 80,
      fontSize: 40,
      color: const Color(0xFFFFD700), // Gold
      bold: true,
      align: TextAlign.center,
      maxWidth: width,
    );

    // 4. Celebrity Match Overlay
    final badgeRect = Rect.fromLTWH(padding + 40, 920, width - padding * 2 - 80, 160);
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(30)), Paint()..color = Colors.black.withOpacity(0.8));
    canvas.drawRRect(RRect.fromRectAndRadius(badgeRect, const Radius.circular(30)), Paint()..color = const Color(0xFFFFD700).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);

    _drawText(
      canvas: canvas,
      text: 'LOOKALIKE MATCH',
      x: padding + 80,
      y: 940,
      fontSize: 24,
      color: const Color(0xFFFFD700),
      bold: true,
      maxWidth: 400,
    );
    _drawText(
      canvas: canvas,
      text: celebrityName,
      x: padding + 80,
      y: 980,
      fontSize: 64,
      color: Colors.white,
      bold: true,
      maxWidth: 600,
    );
    _drawText(
      canvas: canvas,
      text: '${celebrityConfidence.toStringAsFixed(1)}%',
      x: width - padding - 100,
      y: 960,
      fontSize: 80,
      color: const Color(0xFFFFD700),
      bold: true,
      align: TextAlign.right,
      maxWidth: 300,
    );
    
    // Draw Age/Gender if available
    if (age != null || gender != null) {
      String demoText = "";
      if (age != null) demoText += "Age: $age  ";
      if (gender != null) demoText += "Gender: $gender";
      
      _drawText(
        canvas: canvas,
        text: demoText,
        x: padding + 80,
        y: 1045,
        fontSize: 28,
        color: Colors.white54,
        bold: true,
        maxWidth: 600,
      );
    }

    // 5. Symmetry Score
    _drawText(
      canvas: canvas,
      text: 'OVERALL SYMMETRY',
      x: padding,
      y: 1120,
      fontSize: 28,
      color: Colors.white54,
      bold: true,
      maxWidth: width,
    );
    _drawText(
      canvas: canvas,
      text: '${overallSymmetry.toStringAsFixed(1)}%',
      x: padding,
      y: 1160,
      fontSize: 120,
      color: Colors.white,
      bold: true,
      maxWidth: width,
    );

    // 6. Explanation
    final expRect = Rect.fromLTWH(padding, 1320, width - padding * 2, 180);
    canvas.drawRRect(RRect.fromRectAndRadius(expRect, const Radius.circular(20)), Paint()..color = Colors.white.withOpacity(0.05));
    _drawText(
      canvas: canvas,
      text: explanation,
      x: padding + 30,
      y: 1350,
      fontSize: 32,
      color: Colors.white70,
      maxWidth: width - padding * 2 - 60,
    );

    // 7. Branding
    _drawText(
      canvas: canvas,
      text: 'MirrorMe AI • App Store',
      x: width / 2,
      y: height - 100,
      fontSize: 32,
      color: Colors.white30,
      align: TextAlign.center,
      maxWidth: width,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  static void _drawClippedImage(Canvas canvas, ui.Image image, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(40));
    canvas.save();
    canvas.clipRRect(rrect);
    
    // Cover fit logic
    double scale = 1.0;
    double dx = 0, dy = 0;
    if (image.width / image.height > rect.width / rect.height) {
      scale = rect.height / image.height;
      dx = (rect.width - image.width * scale) / 2;
    } else {
      scale = rect.width / image.width;
      dy = (rect.height - image.height * scale) / 2;
    }
    
    final dest = Rect.fromLTWH(rect.left + dx, rect.top + dy, image.width * scale, image.height * scale);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), dest, Paint());
    canvas.restore();
  }

  static Future<ui.Image> _loadUiImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  static void _drawText({
    required Canvas canvas,
    required String text,
    required double x,
    required double y,
    required double fontSize,
    required Color color,
    bool bold = false,
    TextAlign align = TextAlign.left,
    double maxWidth = 400,
  }) {
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: align, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal))
      ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.bold : FontWeight.normal))
      ..addText(text);
    final paragraph = paragraphBuilder.build()..layout(ui.ParagraphConstraints(width: maxWidth));
    double drawX = x;
    if (align == TextAlign.center) drawX = x - maxWidth / 2;
    if (align == TextAlign.right) drawX = x - maxWidth;
    canvas.drawParagraph(paragraph, Offset(drawX, y));
  }
}
