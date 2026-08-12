/// Represents the capture steps for guided face scanning
enum CaptureStep {
  front('Front Face', 'Look straight at the camera', 0),
  left('Left Angle', 'Turn your face slightly to the left (~30°)', 1),
  right('Right Angle', 'Turn your face slightly to the right (~30°)', 2);

  final String title;
  final String instruction;
  final int stepIndex;

  const CaptureStep(this.title, this.instruction, this.stepIndex);

  /// Get the next step in the sequence
  CaptureStep? get next {
    switch (this) {
      case CaptureStep.front:
        return CaptureStep.left;
      case CaptureStep.left:
        return CaptureStep.right;
      case CaptureStep.right:
        return null; // No more steps
    }
  }

  /// Get display label for UI
  String get label => 'Step ${stepIndex + 1} of 3: $title';
}

/// Angle tolerance for face detection (in degrees)
class AngleThresholds {
  /// Yaw threshold for front face (degrees)
  static const double frontYawThreshold = 15.0;

  /// Yaw threshold for left angle (degrees, negative = left turn)
  static const double leftYawMin = -40.0;
  static const double leftYawMax = -15.0;

  /// Yaw threshold for right angle (degrees, positive = right turn)
  static const double rightYawMin = 15.0;
  static const double rightYawMax = 40.0;

  /// Pitch threshold for up/down tilt (degrees)
  static const double pitchThreshold = 20.0;

  /// Check if yaw is within front face range
  static bool isFront(double yaw) {
    return yaw.abs() <= frontYawThreshold;
  }

  /// Check if yaw is within left angle range
  static bool isLeft(double yaw) {
    return yaw >= leftYawMin && yaw <= leftYawMax;
  }

  /// Check if yaw is within right angle range
  static bool isRight(double yaw) {
    return yaw >= rightYawMin && yaw <= rightYawMax;
  }

  /// Check if pitch is within acceptable range
  static bool isAcceptablePitch(double pitch) {
    return pitch.abs() <= pitchThreshold;
  }

  /// Validate yaw matches the expected step
  static bool validateAngle(double yaw, CaptureStep step) {
    switch (step) {
      case CaptureStep.front:
        return isFront(yaw);
      case CaptureStep.left:
        return isLeft(yaw);
      case CaptureStep.right:
        return isRight(yaw);
    }
  }
}

/// Feedback messages based on face alignment
enum AlignmentFeedback {
  noFace('No face detected', 'Position your face in the frame'),
  tooFar('Face too small', 'Move closer to the camera'),
  tooClose('Face too large', 'Move back slightly'),
  notCentered('Face not centered', 'Center your face in the oval'),
  turnLeft('Turn left', 'Rotate your face slightly to the left'),
  turnRight('Turn right', 'Rotate your face slightly to the right'),
  turnMoreLeft('Turn more left', 'Rotate further to ~30° left'),
  turnMoreRight('Turn more right', 'Rotate further to ~30° right'),
  tiltUp('Tilt up', 'Raise your chin slightly'),
  tiltDown('Tilt down', 'Lower your chin slightly'),
  goodPosition('Perfect ✅', 'Hold still or tap to capture');

  final String title;
  final String hint;

  const AlignmentFeedback(this.title, this.hint);
}
