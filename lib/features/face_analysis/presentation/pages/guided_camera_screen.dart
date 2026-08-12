import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/capture_step.dart';
import '../../domain/services/face_detection_service.dart';
import '../widgets/face_alignment_overlay.dart';

class GuidedCameraScreen extends StatefulWidget {
  final Function(List<File>) onImagesCaptured;

  const GuidedCameraScreen({super.key, required this.onImagesCaptured});

  @override
  State<GuidedCameraScreen> createState() => _GuidedCameraScreenState();
}

class _GuidedCameraScreenState extends State<GuidedCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final List<File> _capturedImages = [];
  CaptureStep _currentStep = CaptureStep.front;
  bool _isInitialized = false;
  bool _isCapturing = false;
  AlignmentFeedback _currentFeedback = AlignmentFeedback.noFace;
  FaceDetectionService? _faceDetectionService;
  Timer? _analysisTimer;
  String? _lastCapturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _faceDetectionService = FaceDetectionService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _analysisTimer?.cancel();
    _controller?.dispose();
    _faceDetectionService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      // Use front camera for face capture
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
        _startFaceAnalysis();
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  void _startFaceAnalysis() {
    // Analyze frames periodically for face detection
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _analyzeCurrentFrame();
    });
  }

  Future<void> _analyzeCurrentFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;

    try {
      final XFile imageFile = await _controller!.takePicture();
      final result = await _faceDetectionService!.detectFace(imageFile.path, step: _currentStep);

      if (mounted) {
        setState(() {
          _currentFeedback = result.feedback;
        });
      }

      // Clean up temp image
      if (_lastCapturedImagePath != imageFile.path) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_analysis.jpg');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        _lastCapturedImagePath = imageFile.path;
      }
    } catch (e) {
      // Silently fail for analysis - don't interrupt capture flow
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing) return;
    if (_currentFeedback == AlignmentFeedback.noFace) {
      _showError('No face detected. Please position your face in the frame.');
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile imageFile = await _controller!.takePicture();

      // Save to permanent location
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'capture_${_currentStep.name}_$timestamp.jpg';
      final savedPath = '${appDir.path}/$fileName';

      await File(imageFile.path).copy(savedPath);

      final capturedFile = File(savedPath);

      setState(() {
        _capturedImages.add(capturedFile);
      });

      // Move to next step or complete
      _moveToNextStep();
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  void _moveToNextStep() {
    final nextStep = _currentStep.next;

    if (nextStep == null) {
      // All steps complete
      _completeCapture();
    } else {
      setState(() => _currentStep = nextStep);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${nextStep.title} - ${nextStep.instruction}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _completeCapture() {
    if (_capturedImages.length >= 3) {
      widget.onImagesCaptured(_capturedImages);
      Navigator.pop(context, _capturedImages);
    } else {
      _showError('Need at least 3 images for analysis');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
      // Reset to first step if we have fewer than 3 images
      if (_capturedImages.length < 3) {
        _currentStep = CaptureStep.front;
      }
    });
  }

  void _retakeAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Retake All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear all captured images.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImages.clear();
                _currentStep = CaptureStep.front;
              });
            },
            child: const Text(
              'Retake',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Face alignment overlay
          if (_isInitialized)
            FaceAlignmentOverlay(
              currentStep: _currentStep,
              feedback: _currentFeedback,
              showCaptureButton:
                  _currentFeedback == AlignmentFeedback.goodPosition,
            ),

          // Captured images preview (bottom)
          if (_capturedImages.isNotEmpty)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 100,
              left: 0,
              right: 0,
              child: _buildCapturedImagesPreview(),
            ),

          // Capture button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: _buildCaptureButton(),
          ),

          // Top bar with close and retake buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                if (_capturedImages.isNotEmpty)
                  TextButton.icon(
                    onPressed: _retakeAll,
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text(
                      'Retake',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    final canCapture =
        _currentFeedback == AlignmentFeedback.goodPosition &&
        !_isCapturing &&
        _capturedImages.length < 5;

    return Center(
      child: GestureDetector(
        onTap: canCapture ? _captureImage : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: canCapture ? AppColors.primary : Colors.white24,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: canCapture
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: _isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Icon(
                  Icons.camera,
                  color: canCapture ? Colors.white : Colors.white38,
                  size: 36,
                ),
        ),
      ),
    );
  }

  Widget _buildCapturedImagesPreview() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _capturedImages.length,
        itemBuilder: (context, index) {
          final step = CaptureStep.values[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _capturedImages[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      step.title.substring(0, 1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
