import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/user_intent_entity.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key, this.initialIntent});

  final UserIntentEntity? initialIntent;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late String _goal;
  late String _preference;
  late String _glasses;

  static const goals = [
    'Improve attractiveness',
    'Look sharper',
    'Try new style',
  ];

  static const preferences = ['Beard', 'Clean', 'Trendy', 'Professional'];

  static const glassesOptions = ['Yes', 'No', 'Open to suggestions'];

  @override
  void initState() {
    super.initState();
    final seed = widget.initialIntent ?? UserIntentEntity.defaults;
    _goal = seed.goal;
    _preference = seed.preference;
    _glasses = seed.glasses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Grooming Goals',
          style: AppTypography.titleLarge,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            title: 'What is your goal?',
            options: goals,
            value: _goal,
            onChanged: (v) => setState(() => _goal = v),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Preferred style',
            options: preferences,
            value: _preference,
            onChanged: (v) => setState(() => _preference = v),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Do you wear glasses?',
            options: glassesOptions,
            value: _glasses,
            onChanged: (v) => setState(() => _glasses = v),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                UserIntentEntity(
                  goal: _goal,
                  preference: _preference,
                  glasses: _glasses,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Use These Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> options,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (option) => ChoiceChip(
                    selected: value == option,
                    label: Text(option),
                    selectedColor: AppColors.primary.withValues(alpha: 0.22),
                    labelStyle: TextStyle(
                      color: value == option ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: value == option
                          ? AppColors.primary
                          : Colors.white24,
                    ),
                    onSelected: (_) => onChanged(option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
