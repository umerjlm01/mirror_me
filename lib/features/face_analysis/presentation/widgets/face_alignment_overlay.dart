import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/capture_step.dart';

/// Overlay widget that provides face alignment guidance
class FaceAlignmentOverlay extends StatelessWidget {
  final CaptureStep currentStep;
  final AlignmentFeedback feedback;
  final bool showCaptureButton;

  const FaceAlignmentOverlay({
    super.key,
    required this.currentStep,
    required this.feedback,
    this.showCaptureButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Oval face guide
        CustomPaint(
          size: Size.infinite,
          painter: _OvalGuidePainter(
            feedback: feedback,
            isActive: feedback == AlignmentFeedback.goodPosition,
          ),
        ),
        // Step indicator at top
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: _buildStepIndicator(),
        ),
        // Feedback hint at bottom
        Positioned(
          bottom: 120,
          left: 24,
          right: 24,
          child: _buildFeedbackCard(),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(CaptureStep.front, currentStep == CaptureStep.front),
          _buildStepLine(),
          _buildStepDot(CaptureStep.left, currentStep == CaptureStep.left),
          _buildStepLine(),
          _buildStepDot(CaptureStep.right, currentStep == CaptureStep.right),
        ],
      ),
    );
  }

  Widget _buildStepDot(CaptureStep step, bool isActive) {
    final isCompleted = step.index < currentStep.index;
    final color = isCompleted
        ? AppColors.success
        : isActive
        ? AppColors.primary
        : Colors.white30;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 14)
          : isActive
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    final isGood = feedback == AlignmentFeedback.goodPosition;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.success.withValues(alpha: 0.9)
            : Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: isGood ? Border.all(color: AppColors.success, width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentStep.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.info_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                feedback.hint,
                style: TextStyle(
                  color: isGood ? Colors.white : Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the oval face guide
class _OvalGuidePainter extends CustomPainter {
  final AlignmentFeedback feedback;
  final bool isActive;

  _OvalGuidePainter({required this.feedback, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ovalWidth = size.width * 0.75;
    final ovalHeight = ovalWidth * 1.3;

    // Determine colors based on feedback
    Color guideColor;
    Color borderColor;
    double borderWidth;

    if (isActive) {
      guideColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success;
      borderWidth = 3.0;
    } else if (feedback == AlignmentFeedback.noFace) {
      guideColor = Colors.white.withValues(alpha: 0.05);
      borderColor = Colors.white30;
      borderWidth = 2.0;
    } else {
      guideColor = AppColors.primary.withValues(alpha: 0.1);
      borderColor = AppColors.primary;
      borderWidth = 2.0;
    }

    // Draw oval guide
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Fill
    final fillPaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(ovalRect, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawOval(ovalRect, borderPaint);

    // Draw corner guides
    _drawCornerGuides(canvas, size, center, ovalWidth, ovalHeight, borderColor);

    // Draw center crosshair
    _drawCenterCrosshair(canvas, center, borderColor);

    // Draw eye level indicator
    _drawEyeLevelGuide(canvas, center, ovalWidth, ovalHeight, borderColor);
  }

  void _drawCornerGuides(
    Canvas canvas,
    Size size,
    Offset center,
    double ovalWidth,
    double ovalHeight,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // Top-left corner
    canvas.drawLine(
      Offset(ovalRect.left + 20, ovalRect.top + 40),
      Offset(ovalRect.left + 20 + cornerLength, ovalRect.top + 40),
      paint,
    );
    canvas.drawLine(
      Offset(ovalRect.left + 20, ovalRect.top + 40),
      Offset(ovalRect.left + 20, ovalRect.top + 40 + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(ovalRect.right - 20, ovalRect.top + 40),
      Offset(ovalRect.right - 20 - cornerLength, ovalRect.top + 40),
      paint,
    );
    canvas.drawLine(
      Offset(ovalRect.right - 20, ovalRect.top + 40),
      Offset(ovalRect.right - 20, ovalRect.top + 40 + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(ovalRect.left + 20, ovalRect.bottom - 40),
      Offset(ovalRect.left + 20 + cornerLength, ovalRect.bottom - 40),
      paint,
    );
    canvas.drawLine(
      Offset(ovalRect.left + 20, ovalRect.bottom - 40),
      Offset(ovalRect.left + 20, ovalRect.bottom - 40 - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(ovalRect.right - 20, ovalRect.bottom - 40),
      Offset(ovalRect.right - 20 - cornerLength, ovalRect.bottom - 40),
      paint,
    );
    canvas.drawLine(
      Offset(ovalRect.right - 20, ovalRect.bottom - 40),
      Offset(ovalRect.right - 20, ovalRect.bottom - 40 - cornerLength),
      paint,
    );
  }

  void _drawCenterCrosshair(Canvas canvas, Offset center, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - 60),
      Offset(center.dx, center.dy + 60),
      paint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - 40, center.dy),
      Offset(center.dx + 40, center.dy),
      paint,
    );
  }

  void _drawEyeLevelGuide(
    Canvas canvas,
    Offset center,
    double ovalWidth,
    double ovalHeight,
    Color color,
  ) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Eye level indicator (two small horizontal lines)
    final eyeY = center.dy - ovalHeight * 0.15;
    final eyeWidth = ovalWidth * 0.3;

    // Left eye position
    canvas.drawLine(
      Offset(center.dx - eyeWidth, eyeY),
      Offset(center.dx - eyeWidth + 20, eyeY),
      paint,
    );

    // Right eye position
    canvas.drawLine(
      Offset(center.dx + eyeWidth - 20, eyeY),
      Offset(center.dx + eyeWidth, eyeY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalGuidePainter oldDelegate) {
    return oldDelegate.feedback != feedback || oldDelegate.isActive != isActive;
  }
}
