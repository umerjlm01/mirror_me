import 'package:flutter/material.dart';
import '../../domain/entities/celebrity_match.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class Top5MatchesList extends StatefulWidget {
  final List<CelebrityMatch> matches;

  const Top5MatchesList({
    super.key,
    required this.matches,
  });

  @override
  State<Top5MatchesList> createState() => _Top5MatchesListState();
}

class _Top5MatchesListState extends State<Top5MatchesList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Top 5 Celebrity Matches',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.white10,
          ),

          // Matches list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.matches.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: Colors.white.withOpacity(0.05),
            ),
            itemBuilder: (context, index) {
              final match = widget.matches[index];
              final isExpanded = _expandedIndex == index;

              return _buildMatchItem(match, index, isExpanded);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(
    CelebrityMatch match,
    int index,
    bool isExpanded,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _expandedIndex = isExpanded ? null : index;
        });
      },
      child: Container(
        color: isExpanded ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row
            Row(
              children: [
                // Rank badge
                Container(
                  width: 36,
                  height: 36,
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

                const SizedBox(width: 12),

                // Name and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${match.confidence.toStringAsFixed(0)}% Match',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Score indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(match.confidence),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match.confidence.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Expand icon
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),

            // Expanded details
            if (isExpanded) ...[
              const SizedBox(height: 12),
              _buildFeatureDetails(match),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureDetails(CelebrityMatch match) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Feature Similarity',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Eyes
          _buildFeatureBar(
            'Eyes',
            match.features.eyes,
            Icons.remove_red_eye_outlined,
          ),
          const SizedBox(height: 8),

          // Nose
          _buildFeatureBar(
            'Nose',
            match.features.nose,
            Icons.emoji_nature,
          ),
          const SizedBox(height: 8),

          // Mouth
          _buildFeatureBar(
            'Mouth',
            match.features.mouth,
            Icons.sentiment_satisfied_alt,
          ),
        ],
      ),
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
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
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
