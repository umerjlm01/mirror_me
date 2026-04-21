import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/glow_up_bloc.dart';
import '../bloc/glow_up_event.dart';
import '../bloc/glow_up_state.dart';
import '../../domain/entities/glow_up_entry_entity.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_typography.dart';

class GlowUpScreen extends StatefulWidget {
  const GlowUpScreen({super.key});

  @override
  State<GlowUpScreen> createState() => _GlowUpScreenState();
}

class _GlowUpScreenState extends State<GlowUpScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GlowUpBloc>().add(LoadGlowUpHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('⏳ Glow-Up Tracker', style: AppTypography.titleLarge),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'Clear History',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: BlocBuilder<GlowUpBloc, GlowUpState>(
        builder: (context, state) {
          if (state is GlowUpLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is GlowUpError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (state is GlowUpLoaded) {
            if (state.entries.isEmpty) {
              return _buildEmptyState(state.statusMessage);
            }
            return _buildContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(GlowUpLoaded state) {
    final entries = state.entries;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status Banner
        _buildStatusBanner(state),
        const SizedBox(height: 24),

        // Chart
        if (entries.length >= 2) ...[
          _buildSectionTitle('📈 Symmetry Over Time'),
          const SizedBox(height: 12),
          _buildChart(entries),
          const SizedBox(height: 32),
        ],

        // Comparison (latest vs previous)
        if (entries.length >= 2) ...[
          _buildSectionTitle('🆚 Latest vs Previous'),
          const SizedBox(height: 12),
          _buildComparison(entries[0], entries[1]),
          const SizedBox(height: 32),
        ],

        // Timeline
        _buildSectionTitle('🗓 Scan Timeline'),
        const SizedBox(height: 12),
        ...entries.map((e) => _buildTimelineEntry(e)),
      ],
    );
  }

  Widget _buildStatusBanner(GlowUpLoaded state) {
    Color bannerColor = AppColors.primary;
    if (state.improvement != null) {
      if (state.improvement! > 2) {
        bannerColor = AppColors.success;
      } else if (state.improvement! < -2)
        bannerColor = AppColors.error;
      else
        bannerColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bannerColor.withOpacity(0.2), bannerColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bannerColor.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          if (state.improvement != null)
            Text(
              '${state.improvement! >= 0 ? '+' : ''}${state.improvement!.toStringAsFixed(1)}%',
              style: AppTypography.headlineLarge.copyWith(color: bannerColor),
            ),
          Text(
            state.statusMessage,
            style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (state.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${state.entries.length} total scan${state.entries.length == 1 ? '' : 's'}',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChart(List<GlowUpEntryEntity> entries) {
    // Reverse so oldest is left
    final reversed = entries.reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < reversed.length; i++) {
      spots.add(FlSpot(i.toDouble(), reversed[i].overallScore));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}%',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                  radius: 5,
                  color: AppColors.primary,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(
    GlowUpEntryEntity latest,
    GlowUpEntryEntity previous,
  ) {
    final delta = latest.overallScore - previous.overallScore;
    final isUp = delta >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _scoreCompareColumn(
              'Previous',
              previous.overallScore,
              Colors.white54,
            ),
          ),
          Column(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: isUp ? AppColors.success : AppColors.error,
                size: 32,
              ),
              Text(
                '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isUp ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Expanded(
            child: _scoreCompareColumn(
              'Latest',
              latest.overallScore,
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCompareColumn(String label, double score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(1)}%',
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineEntry(GlowUpEntryEntity entry) {
    final color = entry.overallScore >= 85
        ? AppColors.success
        : entry.overallScore >= 70
        ? AppColors.warning
        : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: File(entry.imagePath).existsSync()
                ? Image.file(
                    File(entry.imagePath),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.white10,
                    child: const Icon(Icons.face, color: Colors.white30),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(entry.timestamp),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.overallScore.toStringAsFixed(1)}% Symmetry',
                  style: AppTypography.labelLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniScore('👁', entry.eyeScore),
                    const SizedBox(width: 8),
                    _miniScore('👃', entry.noseScore),
                    const SizedBox(width: 8),
                    _miniScore('👄', entry.mouthScore),
                  ],
                ),
              ],
            ),
          ),
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              '${entry.overallScore.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniScore(String emoji, double score) {
    return Text(
      '$emoji ${score.toStringAsFixed(0)}%',
      style: const TextStyle(color: Colors.white38, fontSize: 12),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleLarge.copyWith(color: Colors.white),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  •  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'Clear History?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your scan history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GlowUpBloc>().add(ClearGlowUpHistoryEvent());
              Navigator.pop(ctx);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
