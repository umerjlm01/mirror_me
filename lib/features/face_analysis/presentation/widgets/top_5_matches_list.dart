import 'package:flutter/material.dart';
import '../../domain/entities/celebrity_match.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class Top5MatchesList extends StatefulWidget {
  final List<CelebrityMatch> matches;

  const Top5MatchesList({super.key, required this.matches});

  @override
  State<Top5MatchesList> createState() => _Top5MatchesListState();
}

class _Top5MatchesListState extends State<Top5MatchesList> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Matches',
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Swipe through your five closest celebrity matches.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              scrollDirection: Axis.horizontal,
              itemCount: widget.matches.length,
              separatorBuilder: (_, separatorIndex) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildMatchCard(context, widget.matches[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context,
    CelebrityMatch match,
    int index,
  ) {
    return SizedBox(
      width: 168,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _showMatchDetails(context, match, index);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.6),
                          AppColors.primary.withOpacity(0.2),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${match.confidence.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                match.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Best match: ${match.features.topFeature}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (match.confidence / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  color: _getScoreColor(match.confidence),
                ),
              ),
              // const SizedBox(height: 12),
              // Row(
              //   children: [
              //     Expanded(
              //       child: _buildMiniFeatureStat('Eyes', match.features.eyes),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _buildMiniFeatureStat('Nose', match.features.nose),
              //     ),
              //     const SizedBox(width: 8),
              //     Expanded(
              //       child: _buildMiniFeatureStat('Mouth', match.features.mouth),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.open_in_full,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Tap for details',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
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

  // Widget _buildMiniFeatureStat(String label, int score) {
  //   return Column(
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(color: Colors.white38, fontSize: 10),
  //       ),
  //       const SizedBox(height: 4),
  //       Text(
  //         '$score',
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontWeight: FontWeight.w700,
  //           fontSize: 12,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _showMatchDetails(
    BuildContext context,
    CelebrityMatch match,
    int index,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${match.confidence.toStringAsFixed(0)}% overall similarity',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Feature Similarity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureBar(
                        'Eyes',
                        match.features.eyes,
                        Icons.remove_red_eye_outlined,
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureBar(
                        'Nose',
                        match.features.nose,
                        Icons.face_retouching_natural,
                      ),
                      const SizedBox(height: 10),
                      _buildFeatureBar(
                        'Mouth',
                        match.features.mouth,
                        Icons.sentiment_satisfied_alt,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureBar(String label, int score, IconData icon) {
    final scorePercent = score / 100.0;
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  Text(
                    '$score%',
                    style: TextStyle(
                      color: AppColors.primary.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: scorePercent,
                  minHeight: 3,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: _getScoreColor(score.toDouble()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFF00FF88).withOpacity(0.6);
    } else if (score >= 70) {
      return const Color(0xFFFFDD00).withOpacity(0.6);
    } else {
      return const Color(0xFFFF6B6B).withOpacity(0.6);
    }
  }
}
