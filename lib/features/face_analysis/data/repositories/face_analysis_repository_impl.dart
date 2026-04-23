import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/entities/face_analysis_entity.dart';
import '../../domain/repositories/face_analysis_repository.dart';
import '../datasources/face_local_data_source.dart';

class FaceAnalysisRepositoryImpl implements FaceAnalysisRepository {
  final ApiService apiService;
  final FaceLocalDataSource localDataSource;

  FaceAnalysisRepositoryImpl({
    required this.apiService,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, FaceAnalysisEntity>> analyzeFace(
    File imageFile,
  ) async {
    try {
      final apiResponse = await apiService.analyzeFace(imageFile);

      // Check for errors in response
      if (apiResponse.containsKey('error')) {
        return Left(ServerFailure(apiResponse['error'] as String));
      }

      // Extract raw data with safe null checking
      final symmetry = apiResponse['symmetry'] as Map<String, dynamic>? ?? {};
      final features = Map<String, double>.from(
        (apiResponse['features'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
      final perfectFaces =
          apiResponse['perfect_faces'] as Map<String, dynamic>? ?? {};
      final insightfaceAnalysis =
          apiResponse['insightface_analysis'] as Map<String, dynamic>? ?? {};
      // Facial harmony data extraction (maintained for compatibility)
      final featureProfileRaw =
          apiResponse['facial_feature_profile'] as Map<String, dynamic>? ?? {};
      final archetypeRaw =
          apiResponse['archetype'] as Map<String, dynamic>? ?? {};
      final moodRaw = apiResponse['mood'] as Map<String, dynamic>? ?? {};

      // Extract grooming-focused fields
      final faceShape = apiResponse['face_shape'] as String? ?? 'Oval';
      final jawlineStrength =
          (apiResponse['jawline_strength'] as num?)?.toInt() ?? 70;
      final groomingTips = List<String>.from(
        (apiResponse['grooming_tips'] as List<dynamic>? ?? []).map(
          (e) => e.toString(),
        ),
      );
      final styleRecsRaw =
          apiResponse['style_recommendations'] as Map<String, dynamic>? ?? {};
      final styleRecommendations = StyleRecommendations(
        hair:
            styleRecsRaw['hair'] as String? ?? 'Short sides with volume on top',
        beard: styleRecsRaw['beard'] as String? ?? 'Light stubble',
        glasses: styleRecsRaw['glasses'] as String? ?? 'Any frame shape',
      );
      final facePropsRaw =
          apiResponse['face_proportions'] as Map<String, dynamic>? ?? {};
      final faceProportions = FaceProportions(
        widthHeightRatio:
            (facePropsRaw['width_height_ratio'] as num?)?.toDouble() ?? 0.85,
        assessment: facePropsRaw['assessment'] as String? ?? 'Balanced',
      );

      // Parse symmetry scores
      final overallSymmetry = _parsePercentage(symmetry['overall_score']);
      final eyeSymmetry = _parsePercentage(symmetry['eye_symmetry']);
      final noseSymmetry = _parsePercentage(symmetry['nose_alignment']);
      final mouthSymmetry = _parsePercentage(symmetry['mouth_alignment']);

      // Parse feature scores
      final eyeScore = _clampInt(
        (_parsePercentage(features['eyes'] ?? features['eye_spacing'] ?? 0.85) *
                100)
            .toInt(),
        0,
        100,
      );
      final noseScore = _clampInt(
        (_parsePercentage(
                  features['nose'] ?? features['nose_position'] ?? 0.78,
                ) *
                100)
            .toInt(),
        0,
        100,
      );
      final mouthScore = _clampInt(
        (_parsePercentage(
                  features['mouth'] ?? features['mouth_width'] ?? 0.82,
                ) *
                100)
            .toInt(),
        0,
        100,
      );

      // Build facial harmony
      final harmonyScore = ((eyeScore + noseScore + mouthScore) / 3).toInt();
      final proportionScore = ((overallSymmetry * 100).toInt());
      final balanceScore =
          ((eyeSymmetry * 100 + noseSymmetry * 100 + mouthSymmetry * 100) ~/ 3);

      final facialHarmony = FacialHarmony(
        score: harmonyScore,
        symmetry: (overallSymmetry * 100).toInt(),
        proportion: proportionScore,
        balance: balanceScore,
      );

      // Build feature profile
      final facialFeatureProfile = FacialFeatureProfile(
        label: featureProfileRaw['label'] as String? ?? 'Balanced Features',
        confidence: (featureProfileRaw['confidence'] as num?)?.toInt() ?? 75,
        summary:
            featureProfileRaw['summary'] as String? ??
            'Your face shows good balance and symmetry',
        primaryRegion: featureProfileRaw['primaryRegion'] as String? ?? 'Eyes',
        primaryShare:
            (featureProfileRaw['primaryShare'] as num?)?.toInt() ?? 40,
        secondaryRegion:
            featureProfileRaw['secondaryRegion'] as String? ?? 'Jawline',
        secondaryShare:
            (featureProfileRaw['secondaryShare'] as num?)?.toInt() ?? 30,
      );

      // Build archetype
      final archetype = FaceArchetype(
        name: archetypeRaw['name'] as String? ?? 'Balanced',
        confidence: (archetypeRaw['confidence'] as num?)?.toInt() ?? 75,
        description:
            archetypeRaw['description'] as String? ??
            'Your face has harmonious proportions',
      );

      // Build mood
      final mood = MoodAnalysis(
        type: moodRaw['type'] as String? ?? 'Neutral',
        confidence: (moodRaw['confidence'] as num?)?.toInt() ?? 70,
      );

      // Build analysis confidence
      final analysisConfidence = AnalysisConfidence(
        matchReliability: 85,
        landmarkQuality: 88,
      );

      // Build face alignment
      final alignment = FaceAlignment(
        eyesHorizontal: true,
        rotationDegrees: 0,
        scaleScore: 90,
      );

      // Save perfect faces to local files
      final alignedFile = await _saveBase64Image(
        perfectFaces['aligned_face'] as String? ?? '',
        'aligned_face',
      );
      final leftFile = await _saveBase64Image(
        perfectFaces['left_perfect_face'] as String? ?? '',
        'left_perfect',
      );
      final rightFile = await _saveBase64Image(
        perfectFaces['right_perfect_face'] as String? ?? '',
        'right_perfect',
      );

      final explanation =
          apiResponse['explanation'] as String? ??
          'Your grooming profile has been analyzed';

      final age =
          apiResponse['age'] as int? ?? insightfaceAnalysis['age'] as int?;
      final gender =
          apiResponse['gender'] as String? ??
          insightfaceAnalysis['gender'] as String?;

      // Build entity
      final entity = FaceAnalysisEntity(
        originalImage: imageFile,
        faceShape: faceShape,
        jawlineStrength: jawlineStrength,
        faceProportions: faceProportions,
        groomingTips: groomingTips,
        styleRecommendations: styleRecommendations,
        overallSymmetry: overallSymmetry,
        eyeSymmetry: eyeSymmetry,
        noseSymmetry: noseSymmetry,
        mouthSymmetry: mouthSymmetry,
        featureScores: features,
        explanation: explanation,
        age: age,
        gender: gender,
        facialHarmony: facialHarmony,
        facialFeatureProfile: facialFeatureProfile,
        archetype: archetype,
        mood: mood,
        analysisConfidence: analysisConfidence,
        alignment: alignment,
        alignedFace: alignedFile,
        leftPerfectFace: leftFile,
        rightPerfectFace: rightFile,
      );

      return Right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('timeout') ||
          errorMsg.contains('SocketException')) {
        return Left(ServerFailure('Connection timeout. Please try again.'));
      }
      return Left(ServerFailure('Error: $errorMsg'));
    }
  }

  Future<File?> _saveBase64Image(String base64String, String prefix) async {
    if (base64String.isEmpty) return null;
    try {
      final base64Data = base64String.split(',').last;
      final Uint8List bytes = base64Decode(base64Data);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Either<Failure, FaceAnalysisEntity>> getLastResult() async {
    return const Left(CacheFailure("Not implemented"));
  }

  @override
  Future<Either<Failure, void>> saveResult(FaceAnalysisEntity result) async {
    try {
      final snapshot = jsonEncode({
        'face_shape': result.faceShape,
        'jawline_strength': result.jawlineStrength,
        'overall_symmetry': result.overallSymmetry,
        'eye_score': result.eyeSymmetry,
        'nose_score': result.noseSymmetry,
        'mouth_score': result.mouthSymmetry,
        'harmony_score': result.facialHarmony.score,
        'proportion_score': result.facialHarmony.proportion,
        'balance_score': result.facialHarmony.balance,
        'feature_profile_confidence': result.facialFeatureProfile.confidence,
        'archetype_name': result.archetype.name,
        'mood_type': result.mood.type,
        'mood_confidence': result.mood.confidence,
        'match_reliability': result.analysisConfidence.matchReliability,
        'landmark_quality': result.analysisConfidence.landmarkQuality,
        'feature_scores': result.featureScores,
      });
      await localDataSource.cacheLastAnalysisSnapshot(snapshot);
      await localDataSource.cacheLastResultPath(result.originalImage.path);
      return const Right(null);
    } catch (_) {
      return const Left(CacheFailure('Failed to cache analysis snapshot'));
    }
  }

  double _parsePercentage(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return (value).clamp(0.0, 1.0);
    if (value is int) return (value / 100).clamp(0.0, 1.0);
    if (value is String) return (double.tryParse(value) ?? 0.0).clamp(0.0, 1.0);
    return 0.0;
  }

  int _clampInt(int value, int min, int max) {
    return value.clamp(min, max);
  }
}
