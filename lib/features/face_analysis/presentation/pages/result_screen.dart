import 'dart:io';
import 'dart:developer';
import '../../domain/entities/face_analysis_entity.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/face_analysis_bloc.dart';
import '../bloc/face_analysis_event.dart';
import '../bloc/face_analysis_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/top_5_matches_list.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/share_card_generator.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isGeneratingCard = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FaceAnalysisBloc, FaceAnalysisState>(
      builder: (context, state) {
        if (state is! FaceAnalysisSuccess) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
              child: Text('No Result', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final result = state.result;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF0D0D0D),
                  expandedHeight: 80,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      context.read<FaceAnalysisBloc>().add(ResetEvent());
                      Navigator.pop(context);
                    },
                  ),
                  title: const Text(
                    'Face Intelligence',
                    style: AppTypography.titleLarge,
                  ),
                  centerTitle: true,
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(result),
                        const SizedBox(height: 24),
                        _buildFaceInsightsSection(result),
                        const SizedBox(height: 24),
                        _buildPersonalProfileSection(result),
                        const SizedBox(height: 24),
                        if (result.topMatches.isNotEmpty)
                          Top5MatchesList(matches: result.topMatches),
                        if (result.topMatches.isNotEmpty)
                          const SizedBox(height: 32),
                        const SizedBox(height: 40),
                        if (_isGeneratingCard)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        else
                          CustomButton(
                            text: 'Share My Report',
                            icon: Icons.share_rounded,
                            onPressed: () => _shareReport(context, result),
                            isPrimary: true,
                          ),

                        const SizedBox(height: 12),
                        CustomButton(
                          text: 'Save to Glow-Up Tracker',
                          icon: Icons.auto_graph_rounded,
                          onPressed: () {
                            context.read<FaceAnalysisBloc>().add(
                              SaveGlowUpEntryEvent(result.originalImage),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Result saved to history'),
                              ),
                            );
                          },
                          isPrimary: false,
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(FaceAnalysisEntity result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.18),
            const Color(0xFF1A1A1A),
            Colors.black,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Celebrity Match',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildHeroImageCard(
                  label: 'You',
                  child: Image.file(result.originalImage, fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${result.celebrityConfidence.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'MATCH',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildHeroImageCard(
                  label: result.celebrityName,
                  child:
                      result.celebrityImageUrl != null &&
                          result.celebrityImageUrl!.isNotEmpty
                      ? Image.network(
                          result.celebrityImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCelebrityFallback(result.celebrityName),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            );
                          },
                        )
                      : _buildCelebrityFallback(result.celebrityName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            result.celebrityName,
            style: AppTypography.headlineLarge.copyWith(color: Colors.white),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '${result.celebrityConfidence.toStringAsFixed(1)}% similarity match',
            style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.verified_outlined,
                'Reliability ${result.analysisConfidence.matchReliability}%',
              ),
              if (result.age != null)
                _buildInfoChip(Icons.cake_outlined, 'Age ${result.age}'),
              if (result.gender != null)
                _buildInfoChip(
                  result.gender == 'Male' ? Icons.male : Icons.female,
                  result.gender!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.explanation,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white70,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImageCard({required String label, required Widget child}) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.78,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.22),
                width: 1.5,
              ),
              color: Colors.white.withOpacity(0.04),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCelebrityFallback(String name) {
    return Container(
      color: Colors.white.withOpacity(0.03),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 52,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaceInsightsSection(FaceAnalysisEntity result) {
    final goldenRatioScore =
        ((result.featureScores['face_proportion'] ?? 0) * 100).round();

    return _buildSectionCard(
      title: 'Face Insights',
      icon: Icons.insights_rounded,
      subtitle: 'Core structure, symmetry, and proportion at a glance.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricPill(
                icon: Icons.center_focus_strong,
                label: 'Landmarks',
                value: '${result.analysisConfidence.landmarkQuality}%',
              ),
              _buildMetricPill(
                icon: Icons.rotate_right,
                label: 'Rotation',
                value: '${result.alignment.rotationDegrees}°',
              ),
              _buildMetricPill(
                icon: Icons.zoom_out_map,
                label: 'Scale',
                value: '${result.alignment.scaleScore}%',
              ),
              _buildMetricPill(
                icon: result.alignment.eyesHorizontal
                    ? Icons.check_circle_outline
                    : Icons.remove_circle_outline,
                label: 'Eye Line',
                value: result.alignment.eyesHorizontal ? 'Aligned' : 'Adjusted',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildScoreBar('Facial Harmony', result.facialHarmony.score),
          const SizedBox(height: 12),
          _buildScoreBar('Overall Symmetry', result.overallSymmetry.round()),
          const SizedBox(height: 12),
          _buildScoreBar('Golden Ratio', goldenRatioScore),
          const SizedBox(height: 18),
          _buildSubsectionLabel('Feature Breakdown'),
          const SizedBox(height: 12),
          _buildCompactFeatureGrid(result),
          const SizedBox(height: 18),
          _buildSubsectionLabel('Geometric Scores'),
          const SizedBox(height: 12),
          _buildGeometricScoreWrap(result.featureScores),
          if (result.leftPerfectFace != null &&
              result.rightPerfectFace != null) ...[
            const SizedBox(height: 16),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                iconColor: AppColors.primary,
                collapsedIconColor: AppColors.primary,
                title: const Text(
                  'Symmetry Visualization',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Compare left-perfect and right-perfect renderings',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                children: [
                  const SizedBox(height: 12),
                  _buildPerfectFaceComparison(
                    result.leftPerfectFace!,
                    result.rightPerfectFace!,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalProfileSection(FaceAnalysisEntity result) {
    return _buildSectionCard(
      title: 'Personal Profile',
      icon: Icons.person_pin_circle_outlined,
      subtitle: 'Archetype, expression, and style similarity in one place.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileTile(
            icon: Icons.auto_awesome,
            title: result.archetype.name,
            trailing: '${result.archetype.confidence}%',
            body: result.archetype.description,
          ),
          const SizedBox(height: 12),
          _buildProfileTile(
            icon: Icons.mood,
            title: '${result.mood.type} ${_moodEmoji(result.mood.type)}',
            trailing: '${result.mood.confidence}%',
            body: 'Current expression read from your capture.',
          ),
          const SizedBox(height: 12),
          _buildProfileTile(
            icon: Icons.public,
            title: result.facialFeatureProfile.label,
            trailing: '${result.facialFeatureProfile.confidence}%',
            body:
                '${result.facialFeatureProfile.summary} ${result.facialFeatureProfile.primaryRegion} ${result.facialFeatureProfile.primaryShare}% • ${result.facialFeatureProfile.secondaryRegion} ${result.facialFeatureProfile.secondaryShare}%',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final normalized = (score / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$score%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: normalized,
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: _getFeatureScoreColor(normalized),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildCompactFeatureGrid(FaceAnalysisEntity result) {
    final tiles = [
      _FeatureTileData(
        label: 'Eyes',
        score: result.eyeSymmetry.round(),
        icon: Icons.remove_red_eye_outlined,
      ),
      _FeatureTileData(
        label: 'Nose',
        score: result.noseSymmetry.round(),
        icon: Icons.face_retouching_natural,
      ),
      _FeatureTileData(
        label: 'Mouth',
        score: result.mouthSymmetry.round(),
        icon: Icons.sentiment_satisfied_alt_outlined,
      ),
      _FeatureTileData(
        label: 'Balance',
        score: result.facialHarmony.balance,
        icon: Icons.tune,
      ),
    ];

    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(tile.icon, color: AppColors.primary, size: 18),
              const Spacer(),
              Text(
                tile.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${tile.score}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (tile.score / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  color: _getFeatureScoreColor(
                    (tile.score / 100).clamp(0.0, 1.0),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeometricScoreWrap(Map<String, double> features) {
    final orderedFeatures = [
      for (final entry in [
        MapEntry('eye_spacing', features['eye_spacing']),
        MapEntry('nose_position', features['nose_position']),
        MapEntry('mouth_width', features['mouth_width']),
        MapEntry('face_proportion', features['face_proportion']),
      ])
        if (entry.value != null) MapEntry(entry.key, entry.value!),
      ...features.entries.where(
        (entry) => !{
          'eye_spacing',
          'nose_position',
          'mouth_width',
          'face_proportion',
        }.contains(entry.key),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: orderedFeatures.map((entry) {
        final score = (entry.value * 100).round();
        return Container(
          width: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFeatureLabel(entry.key),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$score%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: entry.value.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white10,
                  color: _getFeatureScoreColor(entry.value.clamp(0.0, 1.0)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String trailing,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      trailing,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _moodEmoji(String mood) {
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
        return '🙂';
    }
  }

  String _formatFeatureLabel(String key) {
    switch (key) {
      case 'eye_spacing':
        return 'EYE SPACING';
      case 'nose_position':
        return 'NOSE POSITION';
      case 'mouth_width':
        return 'MOUTH WIDTH';
      case 'face_proportion':
        return 'FACE PROPORTION';
      default:
        return key.toUpperCase().replaceAll('_', ' ');
    }
  }

  Color _getFeatureScoreColor(double score) {
    if (score >= 0.8) return Colors.greenAccent;
    if (score >= 0.6) return AppColors.primary;
    if (score >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildPerfectFaceComparison(File left, File right) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  left,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Left-Perfect',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  right,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Right-Perfect',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _shareReport(
    BuildContext context,
    FaceAnalysisEntity result,
  ) async {
    setState(() => _isGeneratingCard = true);
    try {
      await ShareCardGenerator.sharePremiumCard(
        context: context,
        originalImage: result.originalImage,
        celebrityName: result.celebrityName,
        celebrityImageUrl: result.celebrityImageUrl,
        celebrityConfidence: result.celebrityConfidence,
        facialHarmony: result.facialHarmony.score,
        mood: result.mood.type,
        moodConfidence: result.mood.confidence,
        archetype: result.archetype.name,
      );
    } catch (e) {
      log('Error sharing report: $e');
    } finally {
      setState(() => _isGeneratingCard = false);
    }
  }
}

class _FeatureTileData {
  final String label;
  final int score;
  final IconData icon;

  const _FeatureTileData({
    required this.label,
    required this.score,
    required this.icon,
  });
}
