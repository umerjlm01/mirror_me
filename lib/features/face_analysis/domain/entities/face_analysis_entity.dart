import 'dart:io';
import 'package:equatable/equatable.dart';
import 'celebrity_match.dart';

class FaceAnalysisEntity extends Equatable {
  final File originalImage;
  final String celebrityName;
  final double celebrityConfidence;
  final String? celebrityImageUrl;
  final List<CelebrityMatch> topMatches; // Top 5 matches
  final double overallSymmetry;
  final double eyeSymmetry;
  final double noseSymmetry;
  final double mouthSymmetry;
  final Map<String, double> featureScores;
  final String explanation;
  final int? age;
  final String? gender;
  final File? leftPerfectFace;
  final File? rightPerfectFace;

  const FaceAnalysisEntity({
    required this.originalImage,
    required this.celebrityName,
    required this.celebrityConfidence,
    this.celebrityImageUrl,
    required this.topMatches,
    required this.overallSymmetry,
    required this.eyeSymmetry,
    required this.noseSymmetry,
    required this.mouthSymmetry,
    required this.featureScores,
    required this.explanation,
    this.age,
    this.gender,
    this.leftPerfectFace,
    this.rightPerfectFace,
  });

  @override
  List<Object?> get props => [
        originalImage,
        celebrityName,
        celebrityConfidence,
        celebrityImageUrl,
        topMatches,
        overallSymmetry,
        eyeSymmetry,
        noseSymmetry,
        mouthSymmetry,
        featureScores,
        explanation,
        age,
        gender,
        leftPerfectFace,
        rightPerfectFace,
      ];
}
