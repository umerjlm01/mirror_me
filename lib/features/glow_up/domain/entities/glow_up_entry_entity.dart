import 'package:equatable/equatable.dart';

class GlowUpEntryEntity extends Equatable {
  final String id;
  final String imagePath;
  final double overallScore;
  final double eyeScore;
  final double noseScore;
  final double mouthScore;
  final DateTime timestamp;

  const GlowUpEntryEntity({
    required this.id,
    required this.imagePath,
    required this.overallScore,
    required this.eyeScore,
    required this.noseScore,
    required this.mouthScore,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, timestamp, overallScore];
}
