import 'dart:math' as math;
import 'dart:ui' show Rect, Offset;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../domain/entities/capture_step.dart';

/// Service for detecting faces and estimating head pose angles
class FaceDetectionService {
  final FaceDetector _faceDetector;

  FaceDetectionService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableContours: false,
          enableClassification: false,
          enableTracking: false,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

  /// Detect faces in an image and return detection result
  Future<FaceDetectionResult> detectFace(String imagePath, {CaptureStep? step}) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceDetectionResult.noFace();
      }

      // Get the first (largest) face
      final face = faces.first;
      return _analyzeFace(face, step: step);
    } catch (e) {
      return FaceDetectionResult.error(e.toString());
    }
  }

  /// Analyze a face to determine its position and angles
  FaceDetectionResult _analyzeFace(Face face, {CaptureStep? step}) {
    // Get face bounding box
    final boundingBox = face.boundingBox;

    // Calculate face center
    final centerX = boundingBox.center.dx;

    // Get landmarks for angle estimation
    // ML Kit uses 'position' with x/y properties, not 'point' with dx/dy
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    // Note: ML Kit doesn't have 'nose' landmark, use boundingBox center as fallback
    final leftEar = face.landmarks[FaceLandmarkType.leftEar];
    final rightEar = face.landmarks[FaceLandmarkType.rightEar];

    // Estimate nose position from bounding box center
    final noseX = boundingBox.center.dx;

    // Estimate yaw (left-right rotation) using eye and ear positions
    double yaw = 0.0;
    double pitch = 0.0;

    if (leftEye != null && rightEye != null) {
      // Calculate yaw from eye positions
      // Use position.x and position.y instead of point.dx/dy
      final leftEyeX = leftEye.position.x;
      final leftEyeY = leftEye.position.y;
      final rightEyeX = rightEye.position.x;
      final rightEyeY = rightEye.position.y;

      final eyeCenter = Offset(
        (leftEyeX + rightEyeX) / 2,
        (leftEyeY + rightEyeY) / 2,
      );

      // Use nose position relative to eye center for yaw estimation
      // Use bounding box center as nose position (ML Kit doesn't have nose landmark)
      final noseOffset = noseX - eyeCenter.dx;
      final eyeDistance = (rightEyeX - leftEyeX).abs();

      // Normalize offset by eye distance
      if (eyeDistance > 0) {
        yaw = (noseOffset / eyeDistance) * 90; // Convert to degrees
      }

      // Calculate pitch from eye vertical positions
      final eyeYDiff = rightEyeY - leftEyeY;
      // eyeDistance already declared above — reuse it directly
      if (eyeDistance > 0) {
        pitch = math.atan2(eyeYDiff, eyeDistance) * 180 / math.pi;
      }
    }

    // If no eye landmarks, try using ear positions
    if (leftEye == null || rightEye == null) {
      if (leftEar != null && rightEar != null) {
        final leftEarX = leftEar.position.x;
        final rightEarX = rightEar.position.x;
        final earDistance = (rightEarX - leftEarX).abs();
        // ML Kit has no nose landmark — use bounding box center as nose proxy
        final noseX = centerX;
        final earCenterX = (leftEarX + rightEarX) / 2;

        if (earDistance > 0) {
          yaw = ((noseX - earCenterX) / earDistance) * 90;
        }
      }
    }

    // Determine feedback based on angles
    final feedback = _determineFeedback(yaw, pitch, face, step);

    // Determine if face is in correct position for current step
    final isCorrectPosition = step != null ? AngleThresholds.validateAngle(yaw, step) && AngleThresholds.isAcceptablePitch(pitch) : AngleThresholds.isAcceptablePitch(pitch);

    return FaceDetectionResult(
      hasFace: true,
      yaw: yaw,
      pitch: pitch,
      boundingBox: boundingBox,
      feedback: feedback,
      isCorrectPosition: isCorrectPosition,
      faceWidth: boundingBox.width.toDouble(),
      faceHeight: boundingBox.height.toDouble(),
    );
  }

  /// Determine alignment feedback based on angles
  AlignmentFeedback _determineFeedback(double yaw, double pitch, Face face, CaptureStep? step) {
    // Check if face is detected at all (handled by main logic)

    // Check pitch (up/down tilt)
    if (pitch < -AngleThresholds.pitchThreshold) {
      return AlignmentFeedback.tiltUp;
    } else if (pitch > AngleThresholds.pitchThreshold) {
      return AlignmentFeedback.tiltDown;
    }

    if (step == null) {
      // Check yaw (left/right rotation)
      if (yaw < AngleThresholds.leftYawMin) {
        return AlignmentFeedback.turnLeft;
      } else if (yaw > AngleThresholds.rightYawMax) {
        return AlignmentFeedback.turnRight;
      }
      return AlignmentFeedback.goodPosition;
    }

    // Step-specific guidance
    switch (step) {
      case CaptureStep.front:
        if (yaw < -AngleThresholds.frontYawThreshold) {
          return AlignmentFeedback.turnRight;
        } else if (yaw > AngleThresholds.frontYawThreshold) {
          return AlignmentFeedback.turnLeft;
        }
        break;
      case CaptureStep.left:
        if (yaw > AngleThresholds.leftYawMax) {
          return AlignmentFeedback.turnMoreLeft;
        } else if (yaw < AngleThresholds.leftYawMin) {
          return AlignmentFeedback.turnRight;
        }
        break;
      case CaptureStep.right:
        if (yaw < AngleThresholds.rightYawMin) {
          return AlignmentFeedback.turnMoreRight;
        } else if (yaw > AngleThresholds.rightYawMax) {
          return AlignmentFeedback.turnLeft;
        }
        break;
    }

    return AlignmentFeedback.goodPosition;
  }

  /// Validate if current angle matches the expected step
  bool validateAngleForStep(double yaw, CaptureStep step) {
    return AngleThresholds.validateAngle(yaw, step);
  }

  /// Dispose the face detector
  void dispose() {
    _faceDetector.close();
  }
}

/// Result of face detection analysis
class FaceDetectionResult {
  final bool hasFace;
  final double yaw;
  final double pitch;
  final Rect? boundingBox;
  final AlignmentFeedback feedback;
  final bool isCorrectPosition;
  final double? faceWidth;
  final double? faceHeight;
  final String? errorMessage;

  FaceDetectionResult({
    required this.hasFace,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.boundingBox,
    required this.feedback,
    required this.isCorrectPosition,
    this.faceWidth,
    this.faceHeight,
    this.errorMessage,
  });

  factory FaceDetectionResult.noFace() {
    return FaceDetectionResult(
      hasFace: false,
      feedback: AlignmentFeedback.noFace,
      isCorrectPosition: false,
    );
  }

  factory FaceDetectionResult.error(String message) {
    return FaceDetectionResult(
      hasFace: false,
      feedback: AlignmentFeedback.noFace,
      isCorrectPosition: false,
      errorMessage: message,
    );
  }

  /// Check if face is too small or too large relative to frame
  bool isFaceTooSmall(double frameWidth, double frameHeight) {
    if (boundingBox == null || faceWidth == null) return true;

    final faceArea = faceWidth! * faceHeight!;
    final frameArea = frameWidth * frameHeight;
    final faceRatio = faceArea / frameArea;

    // Face should be between 15% and 50% of frame
    return faceRatio < 0.15;
  }

  bool isFaceTooLarge(double frameWidth, double frameHeight) {
    if (boundingBox == null || faceWidth == null) return false;

    final faceArea = faceWidth! * faceHeight!;
    final frameArea = frameWidth * frameHeight;
    final faceRatio = faceArea / frameArea;

    return faceRatio > 0.5;
  }

  /// Check if face is centered in frame
  bool isCentered(
    double frameWidth,
    double frameHeight,
    double frameCenterX,
    double frameCenterY,
  ) {
    if (boundingBox == null) return false;

    final faceCenterX = boundingBox!.center.dx;
    final faceCenterY = boundingBox!.center.dy;

    final offsetX = (faceCenterX - frameCenterX).abs();
    final offsetY = (faceCenterY - frameCenterY).abs();

    // Allow 20% offset from center
    return offsetX < frameWidth * 0.2 && offsetY < frameHeight * 0.2;
  }
}
