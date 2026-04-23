import 'dart:io';
import 'package:equatable/equatable.dart';

class FaceAnalysisEntity extends Equatable {
  final File originalImage;
  // Grooming-focused fields
  final String faceShape;
  final int jawlineStrength;
  final FaceProportions faceProportions;
  final List<String> groomingTips;
  final StyleRecommendations styleRecommendations;
  // Original analysis fields (kept for insights)
  final double overallSymmetry;
  final double eyeSymmetry;
  final double noseSymmetry;
  final double mouthSymmetry;
  final Map<String, double> featureScores;
  final String explanation;
  final int? age;
  final String? gender;
  final FacialHarmony facialHarmony;
  final FacialFeatureProfile facialFeatureProfile;
  final FaceArchetype archetype;
  final MoodAnalysis mood;
  final AnalysisConfidence analysisConfidence;
  final FaceAlignment alignment;
  final File? alignedFace;
  final File? leftPerfectFace;
  final File? rightPerfectFace;

  const FaceAnalysisEntity({
    required this.originalImage,
    required this.faceShape,
    required this.jawlineStrength,
    required this.faceProportions,
    required this.groomingTips,
    required this.styleRecommendations,
    required this.overallSymmetry,
    required this.eyeSymmetry,
    required this.noseSymmetry,
    required this.mouthSymmetry,
    required this.featureScores,
    required this.explanation,
    this.age,
    this.gender,
    required this.facialHarmony,
    required this.facialFeatureProfile,
    required this.archetype,
    required this.mood,
    required this.analysisConfidence,
    required this.alignment,
    this.alignedFace,
    this.leftPerfectFace,
    this.rightPerfectFace,
  });

  @override
  List<Object?> get props => [
    originalImage,
    faceShape,
    jawlineStrength,
    faceProportions,
    groomingTips,
    styleRecommendations,
    overallSymmetry,
    eyeSymmetry,
    noseSymmetry,
    mouthSymmetry,
    featureScores,
    explanation,
    age,
    gender,
    facialHarmony,
    facialFeatureProfile,
    archetype,
    mood,
    analysisConfidence,
    alignment,
    alignedFace,
    leftPerfectFace,
    rightPerfectFace,
  ];
}

class FacialHarmony extends Equatable {
  final int score;
  final int symmetry;
  final int proportion;
  final int balance;

  const FacialHarmony({
    required this.score,
    required this.symmetry,
    required this.proportion,
    required this.balance,
  });

  @override
  List<Object?> get props => [score, symmetry, proportion, balance];
}

class FacialFeatureProfile extends Equatable {
  final String label;
  final int confidence;
  final String summary;
  final String primaryRegion;
  final int primaryShare;
  final String secondaryRegion;
  final int secondaryShare;

  const FacialFeatureProfile({
    required this.label,
    required this.confidence,
    required this.summary,
    required this.primaryRegion,
    required this.primaryShare,
    required this.secondaryRegion,
    required this.secondaryShare,
  });

  @override
  List<Object?> get props => [
    label,
    confidence,
    summary,
    primaryRegion,
    primaryShare,
    secondaryRegion,
    secondaryShare,
  ];
}

class FaceArchetype extends Equatable {
  final String name;
  final int confidence;
  final String description;

  const FaceArchetype({
    required this.name,
    required this.confidence,
    required this.description,
  });

  @override
  List<Object?> get props => [name, confidence, description];
}

class MoodAnalysis extends Equatable {
  final String type;
  final int confidence;

  const MoodAnalysis({required this.type, required this.confidence});

  @override
  List<Object?> get props => [type, confidence];
}

class AnalysisConfidence extends Equatable {
  final int matchReliability;
  final int landmarkQuality;

  const AnalysisConfidence({
    required this.matchReliability,
    required this.landmarkQuality,
  });

  @override
  List<Object?> get props => [matchReliability, landmarkQuality];
}

class FaceAlignment extends Equatable {
  final bool eyesHorizontal;
  final int rotationDegrees;
  final int scaleScore;

  const FaceAlignment({
    required this.eyesHorizontal,
    required this.rotationDegrees,
    required this.scaleScore,
  });

  @override
  List<Object?> get props => [eyesHorizontal, rotationDegrees, scaleScore];
}

class FaceProportions extends Equatable {
  final double widthHeightRatio;
  final String assessment;

  const FaceProportions({
    required this.widthHeightRatio,
    required this.assessment,
  });

  @override
  List<Object?> get props => [widthHeightRatio, assessment];
}

class StyleRecommendations extends Equatable {
  final String hair;
  final String beard;
  final String glasses;

  const StyleRecommendations({
    required this.hair,
    required this.beard,
    required this.glasses,
  });

  @override
  List<Object?> get props => [hair, beard, glasses];
}
