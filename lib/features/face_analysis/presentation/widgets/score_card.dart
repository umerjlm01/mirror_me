import 'package:flutter/material.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';

class ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final bool isMain;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    Color getScoreColor(double s) {
      if (s >= 90) return AppColors.success;
      if (s >= 75) return AppColors.warning;
      return AppColors.error;
    }

    final color = getScoreColor(score);

    return Container(
      padding: EdgeInsets.all(isMain ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: isMain ? AppTypography.titleLarge : AppTypography.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(1)}%',
            style: (isMain ? AppTypography.headlineLarge : AppTypography.headlineMedium).copyWith(
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: color.withOpacity(0.2),
            color: color,
            borderRadius: BorderRadius.circular(8),
            minHeight: isMain ? 8 : 4,
          )
        ],
      ),
    );
  }
}
