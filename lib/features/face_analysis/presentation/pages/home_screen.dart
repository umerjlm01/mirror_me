import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/user_intent_entity.dart';
import '../bloc/face_analysis_bloc.dart';
import '../bloc/face_analysis_event.dart';
import '../bloc/face_analysis_state.dart';
import '../widgets/custom_button.dart';
import '../widgets/image_source_picker.dart';
import 'processing_screen.dart';
import 'questionnaire_screen.dart';
import 'result_screen.dart';
import 'guided_camera_screen.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  UserIntentEntity _userIntent = UserIntentEntity.defaults;

  Future<void> _showImageSourcePicker() async {
    final source = await ImageSourcePicker.show(context);
    if (source == null) return;

    if (source == ImageSourceType.camera) {
      _openGuidedCamera();
    } else {
      _pickImages();
    }
  }

  Future<void> _openGuidedCamera() async {
    final result = await Navigator.push<List<File>>(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedCameraScreen(
          onImagesCaptured: (images) {
            // Images will be passed back via navigation
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedImages = result;
      });

      if (_selectedImages.length < 3 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select at least 3 images: front, slight left, slight right.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 95);
    if (picked.isEmpty) return;

    setState(() {
      _selectedImages = picked.map((x) => File(x.path)).toList();
    });

    if (_selectedImages.length < 3 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least 3 images: front, slight left, slight right.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _openQuestionnaire() async {
    final result = await Navigator.push<UserIntentEntity>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionnaireScreen(initialIntent: _userIntent),
      ),
    );
    if (result != null) {
      setState(() => _userIntent = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FaceAnalysisBloc, FaceAnalysisState>(
      listener: (context, state) {
        if (state is FaceAnalysisLoading) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProcessingScreen()),
          );
        } else if (state is FaceAnalysisSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        } else if (state is FaceAnalysisError) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final canAnalyze = _selectedImages.length >= 3;

        return Scaffold(
          appBar: AppBar(
            title: const Text('MirrorMe', style: AppTypography.titleLarge),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 72,
                    color: Theme.of(
                      context,
                    ).iconTheme.color?.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Realistic Multi-Image Face Analysis',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Upload at least 3 photos: front, slight left, and slight right. Then set your grooming goals.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  _buildStatusPill(
                    icon: Icons.collections,
                    label: 'Images selected',
                    value: '${_selectedImages.length}',
                  ),
                  const SizedBox(height: 10),
                  _buildStatusPill(
                    icon: Icons.flag_circle,
                    label: 'Current goal',
                    value: _userIntent.goal,
                  ),
                  const SizedBox(height: 18),
                  if (_selectedImages.isNotEmpty) _buildImagePreviewRow(),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: 'Add Images (Min 3)',
                    icon: Icons.add_photo_alternate,
                    onPressed: _showImageSourcePicker,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Set Questionnaire',
                    icon: Icons.fact_check_outlined,
                    isPrimary: false,
                    onPressed: _openQuestionnaire,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Start Analysis',
                    icon: Icons.auto_awesome,
                    isPrimary: canAnalyze,
                    onPressed: () {
                      if (!canAnalyze) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select at least 3 images before analysis.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      context.read<FaceAnalysisBloc>().add(
                        AnalyzeFaceEvent(_selectedImages, _userIntent),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewRow() {
    final preview = _selectedImages.take(3).toList();
    final labels = ['Front', 'Left', 'Right'];

    return Row(
      children: List.generate(preview.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == preview.length - 1 ? 0 : 8),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    preview[i],
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
