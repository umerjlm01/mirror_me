import '../../domain/entities/face_analysis_entity.dart';

class FaceAnalysisModel extends FaceAnalysisEntity {
  const FaceAnalysisModel({
    required super.originalImage,
    required super.celebrityName,
    required super.celebrityConfidence,
    super.celebrityImageUrl,
    required super.topMatches,
    required super.overallSymmetry,
    required super.eyeSymmetry,
    required super.noseSymmetry,
    required super.mouthSymmetry,
    required super.featureScores,
    required super.explanation,
    super.age,
    super.gender,
    super.leftPerfectFace,
    super.rightPerfectFace,
  });

  // Note: fromJson here is tricky because originalImage and perfectFace Files
  // are handled in the Repository. Models usually represent the raw data.
}
