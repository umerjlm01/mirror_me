import 'dart:io';
import 'dart:developer';
import '../../domain/entities/face_analysis_entity.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../bloc/face_analysis_bloc.dart';
import '../bloc/face_analysis_event.dart';
import '../bloc/face_analysis_state.dart';
import '../widgets/score_card.dart';
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
                        _buildCelebrityHeader(result),
                        const SizedBox(height: 24),
                        _buildExplanation(result.explanation),
                        const SizedBox(height: 32),
                        ScoreCard(
                          title: 'Overall Symmetry',
                          score: result.overallSymmetry,
                          isMain: true,
                        ),
                        const SizedBox(height: 24),
                        _buildSymmetryBreakdown(result),
                        const SizedBox(height: 32),
                        const Text(
                          'Geometric Feature Scores',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureGrid(result.featureScores),
                        const SizedBox(height: 32),
                        const Text(
                          'Symmetry Visualization',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 16),

                        if (result.leftPerfectFace != null &&
                            result.rightPerfectFace != null)
                          _buildPerfectFaceComparison(
                            result.leftPerfectFace!,
                            result.rightPerfectFace!,
                          ),

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

  Widget _buildCelebrityHeader(FaceAnalysisEntity result) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face, color: Colors.black, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Celebrity Lookalike',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  result.celebrityName,
                  style: AppTypography.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (result.age != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Age: ${result.age}',
                      ),
                    if (result.age != null && result.gender != null)
                      const SizedBox(width: 8),
                    if (result.gender != null)
                      _buildInfoChip(
                        result.gender == 'Male' ? Icons.male : Icons.female,
                        result.gender!,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${result.celebrityConfidence.toStringAsFixed(1)}%',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Match',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymmetryBreakdown(FaceAnalysisEntity result) {
    return Row(
      children: [
        Expanded(
          child: ScoreCard(title: 'Eyes', score: result.eyeSymmetry),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(title: 'Nose', score: result.noseSymmetry),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ScoreCard(title: 'Mouth', score: result.mouthSymmetry),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(Map<String, double> features) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: features.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                e.key.toUpperCase().replaceAll('_', ' '),
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(e.value * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: LinearProgressIndicator(
                      value: e.value,
                      backgroundColor: Colors.white10,
                      color: AppColors.primary,
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
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
      // For the share card, we need an original image.
      // In this setup, we'll use the left perfect face as a placeholder if original isn't easily accessible,
      // but ideally we should pass the original image from the bloc.
      final Uint8List cardBytes =
          await ShareCardGenerator.generateIntelligenceCard(
            originalImage: result.originalImage,

            celebrityName: result.celebrityName,
            celebrityConfidence: result.celebrityConfidence,
            overallSymmetry: result.overallSymmetry,
            explanation: result.explanation,
            featureScores: result.featureScores,
            age: result.age,
            gender: result.gender,
          );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/share_report.png').create();
      await file.writeAsBytes(cardBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out my Face Intelligence report from MirrorMe! 🚀');
    } catch (e) {
      log('Error sharing report: $e');
    } finally {
      setState(() => _isGeneratingCard = false);
    }
  }
}
