import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/face_analysis_bloc.dart';
import '../bloc/face_analysis_event.dart';
import '../bloc/face_analysis_state.dart';
import '../widgets/custom_button.dart';
import 'processing_screen.dart';
import 'result_screen.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          Navigator.pop(context); // pop loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('MirrorMe', style: AppTypography.titleLarge),
            centerTitle: true,
            elevation: 0,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Analyze your facial symmetry',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload a clear selfie facing forward to get the best results.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CustomButton(
                    text: 'Take a Selfie',
                    icon: Icons.camera,
                    onPressed: () {
                      context.read<FaceAnalysisBloc>().add(CaptureImageEvent());
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Upload from Gallery',
                    icon: Icons.photo_library,
                    isPrimary: false,
                    onPressed: () {
                      context.read<FaceAnalysisBloc>().add(UploadImageEvent());
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
}
