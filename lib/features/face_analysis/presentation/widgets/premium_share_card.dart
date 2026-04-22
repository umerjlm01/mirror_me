import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/share_card_theme.dart';

class PremiumShareCard extends StatelessWidget {
  final File userImage;
  final String celebrityName;
  final String? celebrityImageUrl;
  final double matchScore;
  final int facialHarmony;
  final String mood;
  final int moodConfidence;
  final String archetype;

  const PremiumShareCard({
    super.key,
    required this.userImage,
    required this.celebrityName,
    this.celebrityImageUrl,
    required this.matchScore,
    required this.facialHarmony,
    required this.mood,
    required this.moodConfidence,
    required this.archetype,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ShareCardTheme.cardWidth,
      height: ShareCardTheme.cardHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: ShareCardTheme.backgroundGradient,
          borderRadius: BorderRadius.all(
            Radius.circular(ShareCardTheme.cardRadius),
          ),
          boxShadow: ShareCardTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ShareCardTheme.cardRadius),
          child: Stack(
            children: [
              const _AmbientBackground(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 18),
                    _GlassPanel(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _FaceSpotlight(
                                  title: 'You',
                                  image: FileImage(userImage),
                                  badge: 'Real',
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: _VersusPill(),
                              ),
                              Expanded(
                                child: _FaceSpotlight(
                                  title: celebrityName,
                                  image:
                                      celebrityImageUrl != null &&
                                          celebrityImageUrl!.isNotEmpty
                                      ? NetworkImage(celebrityImageUrl!)
                                      : null,
                                  badge: '${matchScore.toStringAsFixed(0)}%',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              'Top match ${matchScore.toStringAsFixed(0)}% similarity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ShareCardTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You resemble',
                            style: TextStyle(
                              color: ShareCardTheme.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: ShareCardTheme.textPrimary,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                              children: [
                                TextSpan(text: celebrityName),
                                const TextSpan(text: ' 😳'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'MirrorMe thinks your strongest resemblance lands in a polished, camera-ready range. 🔥',
                            style: TextStyle(
                              color: ShareCardTheme.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Facial Harmony',
                              value: '$facialHarmony%',
                              accent: ShareCardTheme.accent,
                              emoji: '✨',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              label: 'Mood',
                              value: '$mood ${_moodEmoji(mood)}',
                              accent: ShareCardTheme.accentSecondary,
                              caption: '$moodConfidence% confidence',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassPanel(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: ShareCardTheme.glowGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: ShareCardTheme.accent.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Archetype',
                                  style: TextStyle(
                                    color: ShareCardTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  archetype,
                                  style: const TextStyle(
                                    color: ShareCardTheme.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text(
                          'What do you think?',
                          style: TextStyle(
                            color: ShareCardTheme.textSecondary.withValues(
                              alpha: 0.95,
                            ),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'MirrorMe',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _moodEmoji(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😄';
      case 'neutral':
        return '🙂';
      case 'sad':
        return '😔';
      case 'angry':
        return '😠';
      case 'surprised':
        return '😮';
      default:
        return '✨';
    }
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: ShareCardTheme.glowGradient,
          ),
          child: const Icon(Icons.auto_fix_high, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MirrorMe',
              style: TextStyle(
                color: ShareCardTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Face Intelligence Card',
              style: TextStyle(
                color: ShareCardTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -70,
          right: -40,
          child: _GlowOrb(
            size: 180,
            color: ShareCardTheme.accent.withValues(alpha: 0.28),
          ),
        ),
        Positioned(
          top: 180,
          left: -50,
          child: _GlowOrb(
            size: 150,
            color: ShareCardTheme.accentSecondary.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: 40,
          right: 20,
          child: _GlowOrb(
            size: 180,
            color: ShareCardTheme.accentSoft.withValues(alpha: 0.16),
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ShareCardTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ShareCardTheme.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _FaceSpotlight extends StatelessWidget {
  final String title;
  final ImageProvider? image;
  final String badge;

  const _FaceSpotlight({
    required this.title,
    required this.image,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ShareCardTheme.glowGradient,
            boxShadow: [
              BoxShadow(
                color: ShareCardTheme.accentSecondary.withValues(alpha: 0.28),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.7),
                width: 2,
              ),
              image: image != null
                  ? DecorationImage(image: image!, fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                    size: 44,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ShareCardTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: ShareCardTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _VersusPill extends StatelessWidget {
  const _VersusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Center(
        child: Text(
          'VS',
          style: TextStyle(
            color: ShareCardTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final String? caption;
  final String? emoji;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
    this.caption,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: ShareCardTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: ShareCardTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          if (emoji != null || caption != null) const SizedBox(height: 8),
          if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 18)),
          if (caption != null)
            Text(
              caption!,
              style: TextStyle(
                color: ShareCardTheme.textSecondary.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
