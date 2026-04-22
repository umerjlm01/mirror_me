import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/face_analysis/presentation/widgets/premium_share_card.dart';
import '../constants/share_card_theme.dart';

class ShareCardGenerator {
  static Future<File> generateAndSavePremiumCard({
    required BuildContext context,
    required File originalImage,
    required String celebrityName,
    String? celebrityImageUrl,
    required double celebrityConfidence,
    required int facialHarmony,
    required String mood,
    required int moodConfidence,
    required String archetype,
  }) async {
    await _precacheAssets(
      context: context,
      originalImage: originalImage,
      celebrityImageUrl: celebrityImageUrl,
    );
    if (!context.mounted) {
      throw StateError('Share card context was disposed before capture.');
    }

    final boundaryKey = GlobalKey();
    final completer = Completer<File>();
    late final OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: Positioned(
          left: -10000,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: boundaryKey,
              child: PremiumShareCard(
                userImage: originalImage,
                celebrityName: celebrityName,
                celebrityImageUrl: celebrityImageUrl,
                matchScore: celebrityConfidence,
                facialHarmony: facialHarmony,
                mood: mood,
                moodConfidence: moodConfidence,
                archetype: archetype,
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(overlayEntry);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: ShareCardTheme.exportPixelRatio,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = await _saveBytes(bytes);
      completer.complete(file);
    } catch (e, st) {
      completer.completeError(e, st);
    } finally {
      overlayEntry.remove();
    }

    return completer.future;
  }

  static Future<void> sharePremiumCard({
    required BuildContext context,
    required File originalImage,
    required String celebrityName,
    String? celebrityImageUrl,
    required double celebrityConfidence,
    required int facialHarmony,
    required String mood,
    required int moodConfidence,
    required String archetype,
  }) async {
    final file = await generateAndSavePremiumCard(
      context: context,
      originalImage: originalImage,
      celebrityName: celebrityName,
      celebrityImageUrl: celebrityImageUrl,
      celebrityConfidence: celebrityConfidence,
      facialHarmony: facialHarmony,
      mood: mood,
      moodConfidence: moodConfidence,
      archetype: archetype,
    );
    if (!context.mounted) {
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'You resemble $celebrityName 😳 What do you think?',
      ),
    );
  }

  static Future<void> _precacheAssets({
    required BuildContext context,
    required File originalImage,
    String? celebrityImageUrl,
  }) async {
    await precacheImage(FileImage(originalImage), context);
    if (!context.mounted) {
      return;
    }
    if (celebrityImageUrl != null && celebrityImageUrl.isNotEmpty) {
      try {
        await precacheImage(NetworkImage(celebrityImageUrl), context);
      } catch (_) {
        // Ignore and fall back to placeholder in the card.
      }
    }
  }

  static Future<File> _saveBytes(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/mirrorme_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    return file.writeAsBytes(bytes, flush: true);
  }
}
