import 'dart:io';
import 'dart:developer';
import '../../domain/entities/face_analysis_entity.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/face_analysis_bloc.dart';
import '../bloc/face_analysis_event.dart';
import '../bloc/face_analysis_state.dart';
import '../widgets/custom_button.dart';
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
                        _buildGroomingSuggestionsCard(result),
                        const SizedBox(height: 24),
                        _buildStyleRecommendationsCard(result),
                        const SizedBox(height: 24),
                        _buildFaceInsightsSection(result),
                        const SizedBox(height: 24),
                        _buildPersonalProfileSection(result),
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

  Widget _buildGroomingSuggestionsCard(FaceAnalysisEntity result) {
    return _buildSectionCard(
      title: 'Grooming Suggestions',
      icon: Icons.recommend_rounded,
      subtitle: 'Personalized tips to enhance your appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.face_retouching_natural,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Face Shape: ${result.faceShape}',
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jawline Strength: ${result.jawlineStrength}/100',
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...result.groomingTips.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleRecommendationsCard(FaceAnalysisEntity result) {
    return _buildSectionCard(
      title: 'Style Recommendations',
      icon: Icons.style_rounded,
      subtitle: 'Hair, beard, and accessory suggestions for you',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStyleRecommendationRow(
            icon: Icons.content_cut_rounded,
            title: 'Hair',
            recommendation: result.styleRecommendations.hair,
          ),
          const SizedBox(height: 16),
          _buildStyleRecommendationRow(
            icon: Icons.face_rounded,
            title: 'Beard',
            recommendation: result.styleRecommendations.beard,
          ),
          const SizedBox(height: 16),
          _buildStyleRecommendationRow(
            icon: Icons.remove_red_eye_rounded,
            title: 'Glasses',
            recommendation: result.styleRecommendations.glasses,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleRecommendationRow({
    required IconData icon,
    required String title,
    required String recommendation,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
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
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white70,
                    height: 1.4,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildHeroSection - Using grooming suggestions cards instead

  // Widget _buildHeroImageCard({required String label, required Widget child}) {
  //   return Column(
  //     children: [
  //       AspectRatio(
  //         aspectRatio: 0.78,
  //         child: Container(
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(20),
  //             border: Border.all(
  //               color: AppColors.primary.withValues(alpha: 0.22),
  //               width: 1.5,
  //             ),
  //             color: Colors.white.withValues(alpha: 0.04),
  //           ),
  //           clipBehavior: Clip.antiAlias,
  //           child: child,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       Text(
  //         label,
  //         maxLines: 2,
  //         overflow: TextOverflow.ellipsis,
  //         textAlign: TextAlign.center,
  //         style: const TextStyle(
  //           color: Colors.white70,
  //           fontSize: 12,
  //           fontWeight: FontWeight.w600,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // Removed _buildCelebrityFallback - Using grooming cards instead

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
          if (result.alignedFace != null ||
              (result.leftPerfectFace != null &&
                  result.rightPerfectFace != null)) ...[
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
                  'See the aligned crop and the mirrored left/right renderings',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                children: [
                  const SizedBox(height: 12),
                  _buildSymmetryVisualization(
                    alignedFace: result.alignedFace,
                    leftPerfectFace: result.leftPerfectFace,
                    rightPerfectFace: result.rightPerfectFace,
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
        color: Colors.white.withValues(alpha: 0.04),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
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

  // Widget _buildInfoChip(IconData icon, String label) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withValues(alpha: 0.08),
  //       borderRadius: BorderRadius.circular(999),
  //     ),
  //     child: Row(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Icon(icon, size: 14, color: AppColors.primary),
  //         const SizedBox(width: 6),
  //         Text(
  //           label,
  //           style: const TextStyle(
  //             color: Colors.white70,
  //             fontSize: 11,
  //             fontWeight: FontWeight.w700,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
        color: Colors.white.withValues(alpha: 0.04),
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
            color: Colors.white.withValues(alpha: 0.05),
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
            color: Colors.white.withValues(alpha: 0.04),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
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

  Widget _buildSymmetryVisualization({
    File? alignedFace,
    File? leftPerfectFace,
    File? rightPerfectFace,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SymmetryStepChip(
                step: '01',
                label: 'Face aligned',
                icon: Icons.center_focus_strong,
              ),
              _SymmetryStepChip(
                step: '02',
                label: 'Axis detected',
                icon: Icons.swap_horiz,
              ),
              _SymmetryStepChip(
                step: '03',
                label: 'Halves mirrored',
                icon: Icons.auto_fix_high,
              ),
            ],
          ),
          if (alignedFace != null) ...[
            const SizedBox(height: 16),
            _buildAlignedFacePreview(alignedFace),
          ],
          if (alignedFace != null &&
              leftPerfectFace != null &&
              rightPerfectFace != null) ...[
            const SizedBox(height: 14),
            _buildSymmetryConnector(),
          ],
          if (leftPerfectFace != null && rightPerfectFace != null) ...[
            const SizedBox(height: 14),
            _buildPerfectFaceComparison(leftPerfectFace, rightPerfectFace),
          ],
        ],
      ),
    );
  }

  Widget _buildPerfectFaceComparison(File left, File right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSymmetryFaceCard(
            title: 'Left-Perfect',
            subtitle: 'Left half mirrored into full symmetry',
            accent: const Color(0xFF7EE7C7),
            imageFile: left,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSymmetryFaceCard(
            title: 'Right-Perfect',
            subtitle: 'Right half mirrored into full symmetry',
            accent: const Color(0xFFFFC978),
            imageFile: right,
          ),
        ),
      ],
    );
  }

  Widget _buildAlignedFacePreview(File alignedFace) {
    return _buildSymmetryFaceCard(
      title: 'Aligned Face Reference',
      subtitle: 'Backend-corrected crop used before the symmetry split',
      accent: AppColors.primary,
      imageFile: alignedFace,
      height: 220,
      fullWidth: true,
    );
  }

  Widget _buildSymmetryFaceCard({
    required String title,
    required String subtitle,
    required Color accent,
    required File imageFile,
    double height = 200,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.03),
              child: Image.file(
                imageFile,
                height: height,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymmetryConnector() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Container(height: 1, color: Colors.white12)),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_downward_rounded,
                color: AppColors.primary,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'Mirrored outputs',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white12)),
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
        faceShape: result.faceShape,
        jawlineStrength: result.jawlineStrength,
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

class _SymmetryStepChip extends StatelessWidget {
  final String step;
  final String label;
  final IconData icon;

  const _SymmetryStepChip({
    required this.step,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              step,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
}
