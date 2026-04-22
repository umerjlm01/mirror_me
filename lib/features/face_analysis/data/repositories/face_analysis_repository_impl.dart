import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/entities/celebrity_match.dart';
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
      final previousSnapshot = await _readPreviousSnapshot();

      // Check for errors in response
      if (apiResponse.containsKey('error')) {
        return Left(ServerFailure(apiResponse['error'] as String));
      }

      // Extract raw data with safe null checking
      final celebMatch = apiResponse['celebrity_match'] ?? {};
      final symmetry = apiResponse['symmetry'] ?? {};
      final features = Map<String, double>.from(
        (apiResponse['features'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
      final perfectFaces = apiResponse['perfect_faces'] ?? {};
      final insightfaceAnalysis = apiResponse['insightface_analysis'] ?? {};
      final facialHarmonyRaw =
          apiResponse['facial_harmony'] as Map<String, dynamic>? ?? {};
      final harmonyDetails =
          facialHarmonyRaw['details'] as Map<String, dynamic>? ?? {};
      final featureProfileRaw =
          apiResponse['facial_feature_profile'] as Map<String, dynamic>? ?? {};
      final archetypeRaw =
          apiResponse['archetype'] as Map<String, dynamic>? ?? {};
      final moodRaw = apiResponse['mood'] as Map<String, dynamic>? ?? {};

      final poseMetrics = _buildPoseMetrics(apiResponse);
      final lightingQuality = _buildLightingQuality(
        apiResponse,
        previousSnapshot,
      );

      final rawOverallSymmetry = _percentFromValue(symmetry['overall_score']);
      final rawEyeSymmetry = _percentFromValue(symmetry['eye_symmetry']);
      final rawNoseSymmetry = _percentFromValue(symmetry['nose_alignment']);
      final rawMouthSymmetry = _percentFromValue(symmetry['mouth_alignment']);

      final rawEyeScore = _blendFeatureSignal(
        primary: rawEyeSymmetry,
        support: _percentFromValue(features['eye_spacing']),
      );
      final rawNoseScore = _blendFeatureSignal(
        primary: rawNoseSymmetry,
        support: _percentFromValue(features['nose_position']),
      );
      final rawMouthScore = _blendFeatureSignal(
        primary: rawMouthSymmetry,
        support: _percentFromValue(features['mouth_width']),
      );

      final normalizedOverallSymmetry = _stabilizeScore(
        current: rawOverallSymmetry,
        previous: previousSnapshot?.overallSymmetry,
        min: 65,
        max: 92,
        target: 79,
      );

      final preliminaryHarmony =
          (rawEyeScore * 0.3) +
          (rawNoseScore * 0.3) +
          (rawMouthScore * 0.2) +
          (normalizedOverallSymmetry * 0.2);

      final harmonyScore = _stabilizeScore(
        current: preliminaryHarmony,
        previous: previousSnapshot?.harmonyScore,
        min: 65,
        max: 92,
        target: 79,
      ).round();

      final eyeScore = _cohereFeatureScore(
        rawEyeScore,
        harmonyScore.toDouble(),
        previousSnapshot?.eyeScore,
      );
      final noseScore = _cohereFeatureScore(
        rawNoseScore,
        harmonyScore.toDouble(),
        previousSnapshot?.noseScore,
      );
      final mouthScore = _cohereFeatureScore(
        rawMouthScore,
        harmonyScore.toDouble(),
        previousSnapshot?.mouthScore,
      );

      final proportionScore = _stabilizeScore(
        current: _blendFeatureSignal(
          primary: _percentFromValue(harmonyDetails['proportion']),
          support: _percentFromValue(features['face_proportion']),
        ),
        previous: previousSnapshot?.proportionScore,
        min: 64,
        max: 91,
        target: harmonyScore.toDouble(),
      ).round();

      final balanceScore = _stabilizeScore(
        current: _blendFeatureSignal(
          primary: _percentFromValue(harmonyDetails['balance']),
          support: (eyeScore + noseScore + mouthScore) / 3,
        ),
        previous: previousSnapshot?.balanceScore,
        min: 64,
        max: 91,
        target: harmonyScore.toDouble(),
      ).round();

      final landmarkQuality = _buildLandmarkQuality(
        apiResponse: apiResponse,
        rawOverallSymmetry: rawOverallSymmetry,
        poseMetrics: poseMetrics,
        previousSnapshot: previousSnapshot,
      );

      final topMatchesRaw = (apiResponse['top_matches'] as List? ?? [])
          .take(5)
          .toList();
      final seedMatch = {
        'name': celebMatch['name'] ?? 'Unknown',
        'confidence': celebMatch['confidence'] ?? 0,
        'image_url': celebMatch['image_url'],
        'features': celebMatch['features'] ?? {},
      };
      final weightedTopMatches = _buildStableTopMatches(
        topMatchesRaw.isEmpty ? [seedMatch] : topMatchesRaw,
        previousSnapshot,
        harmonyScore.toDouble(),
      );
      final primaryMatch = weightedTopMatches.isNotEmpty
          ? weightedTopMatches.first
          : CelebrityMatch(
              name: celebMatch['name'] ?? 'Unknown',
              confidence: _stabilizeScore(
                current: _percentFromValue(celebMatch['confidence']),
                previous: previousSnapshot?.celebrityConfidence,
                min: 60,
                max: 88,
                target: 74,
              ),
              imageUrl: celebMatch['image_url'] as String?,
              features: CelebrityFeatures(
                eyes: eyeScore.round(),
                nose: noseScore.round(),
                mouth: mouthScore.round(),
              ),
            );

      final matchReliability = _buildMatchReliability(
        topMatches: weightedTopMatches,
        landmarkQuality: landmarkQuality,
        lightingQuality: lightingQuality,
        poseMetrics: poseMetrics,
        previousSnapshot: previousSnapshot,
      );

      final calibratedFeatureProfile = _buildFeatureProfile(
        featureProfileRaw,
        previousSnapshot,
        harmonyScore,
      );
      final calibratedArchetype = _buildArchetype(
        archetypeRaw,
        symmetryScore: normalizedOverallSymmetry.round(),
        harmonyScore: harmonyScore,
        balanceScore: balanceScore,
        noseScore: noseScore.round(),
        landmarkQuality: landmarkQuality,
      );
      final calibratedMood = _buildMood(
        moodRaw,
        previousSnapshot,
        landmarkQuality: landmarkQuality,
      );
      final stabilizedFeatures = _normalizeFeatureMap(
        features,
        previousSnapshot,
        harmonyScore.toDouble(),
      );

      // Save perfect faces to local files
      final leftFile = await _saveBase64Image(
        perfectFaces['left_perfect_face'] ?? '',
        'left_perfect',
      );
      final rightFile = await _saveBase64Image(
        perfectFaces['right_perfect_face'] ?? '',
        'right_perfect',
      );

      final entity = FaceAnalysisEntity(
        originalImage: imageFile,
        celebrityName: primaryMatch.name,
        celebrityConfidence: primaryMatch.confidence,
        celebrityImageUrl: primaryMatch.imageUrl,
        topMatches: weightedTopMatches,
        overallSymmetry: normalizedOverallSymmetry,
        eyeSymmetry: eyeScore,
        noseSymmetry: noseScore,
        mouthSymmetry: mouthScore,
        featureScores: stabilizedFeatures,
        explanation: _buildExplanation(
          apiResponse['explanation'] as String?,
          primaryMatch.name,
          matchReliability,
          poseMetrics,
        ),
        age: apiResponse['age'] ?? insightfaceAnalysis['age'],
        gender: apiResponse['gender'] ?? insightfaceAnalysis['gender'],
        facialHarmony: FacialHarmony(
          score: harmonyScore,
          symmetry: normalizedOverallSymmetry.round(),
          proportion: proportionScore,
          balance: balanceScore,
        ),
        facialFeatureProfile: calibratedFeatureProfile,
        archetype: calibratedArchetype,
        mood: calibratedMood,
        analysisConfidence: AnalysisConfidence(
          matchReliability: matchReliability,
          landmarkQuality: landmarkQuality,
        ),
        alignment: FaceAlignment(
          eyesHorizontal: poseMetrics.roll.abs() <= 8,
          rotationDegrees: poseMetrics.roll.abs().round(),
          scaleScore: poseMetrics.scaleScore,
        ),
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

  List<CelebrityMatch> _buildStableTopMatches(
    List<dynamic> topMatchesRaw,
    _AnalysisSnapshot? previousSnapshot,
    double harmonyScore,
  ) {
    final normalizedInput = topMatchesRaw.take(5).map((raw) {
      final match = raw as Map<String, dynamic>;
      return {
        'name': match['name'] as String? ?? 'Unknown',
        'score': _percentFromValue(match['confidence']),
        'image_url': match['image_url'] as String?,
        'features': match['features'] as Map<String, dynamic>? ?? {},
      };
    }).toList();

    if (normalizedInput.isEmpty) return const [];

    final rawScores = normalizedInput
        .map(
          (match) => _normalizeRealisticScore(
            match['score'] as double,
            60,
            88,
            target: 74,
          ),
        )
        .toList();
    final weights = _softmax(rawScores, temperature: 6.5);

    final matches = <CelebrityMatch>[];
    for (var i = 0; i < normalizedInput.length; i++) {
      final match = normalizedInput[i];
      final featuresData = match['features'] as Map<String, dynamic>;
      final previousScore = previousSnapshot?.topMatchScores[match['name']];
      final weightedScore = 60 + (weights[i] * 28);
      final finalScore = _clampDouble(
        _smoothScore(
          (rawScores[i] * 0.65) + (weightedScore * 0.35),
          previousScore,
        ),
        60,
        88,
      );

      matches.add(
        CelebrityMatch(
          name: match['name'] as String,
          confidence: finalScore,
          imageUrl: match['image_url'] as String?,
          features: CelebrityFeatures(
            eyes: _cohereFeatureScore(
              _percentFromValue(featuresData['eyes']),
              harmonyScore,
              null,
            ).round(),
            nose: _cohereFeatureScore(
              _percentFromValue(featuresData['nose']),
              harmonyScore,
              null,
            ).round(),
            mouth: _cohereFeatureScore(
              _percentFromValue(featuresData['mouth']),
              harmonyScore,
              null,
            ).round(),
          ),
        ),
      );
    }

    matches.sort((a, b) => b.confidence.compareTo(a.confidence));
    return matches;
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
        'celebrity_name': result.celebrityName,
        'celebrity_confidence': result.celebrityConfidence,
        'top_match_scores': {
          for (final match in result.topMatches) match.name: match.confidence,
        },
        'overall_symmetry': result.overallSymmetry,
        'eye_score': result.eyeSymmetry,
        'nose_score': result.noseSymmetry,
        'mouth_score': result.mouthSymmetry,
        'harmony_score': result.facialHarmony.score,
        'proportion_score': result.facialHarmony.proportion,
        'balance_score': result.facialHarmony.balance,
        'feature_profile_confidence': result.facialFeatureProfile.confidence,
        'feature_profile_primary': result.facialFeatureProfile.primaryRegion,
        'feature_profile_secondary':
            result.facialFeatureProfile.secondaryRegion,
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

  Future<_AnalysisSnapshot?> _readPreviousSnapshot() async {
    final raw = await localDataSource.getLastAnalysisSnapshot();
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _AnalysisSnapshot.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  _PoseMetrics _buildPoseMetrics(Map<String, dynamic> apiResponse) {
    final pose =
        apiResponse['pose'] as Map<String, dynamic>? ??
        apiResponse['face_pose'] as Map<String, dynamic>? ??
        {};
    final roll = _firstNumeric([
      pose['roll'],
      pose['rotation'],
      pose['tilt'],
      apiResponse['roll'],
      apiResponse['rotation'],
    ]);
    final yaw = _firstNumeric([pose['yaw'], apiResponse['yaw']]);
    final pitch = _firstNumeric([pose['pitch'], apiResponse['pitch']]);
    final faceSize = _firstNumeric([
      pose['scale'],
      apiResponse['face_scale'],
      apiResponse['face_size'],
    ]);

    final posePenalty = (roll.abs() * 1.8) + (yaw.abs() * 1.2) + pitch.abs();
    final scalePenalty = faceSize == 0
        ? 0.0
        : ((0.55 - faceSize).abs() * 120).clamp(0.0, 18.0);

    return _PoseMetrics(
      roll: roll,
      yaw: yaw,
      pitch: pitch,
      poseScore: _clampInt((92 - posePenalty).round(), 58, 95),
      scaleScore: _clampInt((90 - scalePenalty).round(), 60, 94),
    );
  }

  int _buildLightingQuality(
    Map<String, dynamic> apiResponse,
    _AnalysisSnapshot? previousSnapshot,
  ) {
    final lighting = apiResponse['lighting'] as Map<String, dynamic>? ?? {};
    final current = _normalizeRealisticScore(
      _firstNumeric([
        lighting['quality'],
        lighting['score'],
        apiResponse['lighting_quality'],
        apiResponse['illumination_score'],
        84,
      ]),
      60,
      93,
      target: 82,
    );
    return _clampInt(
      _smoothScore(
        current,
        previousSnapshot?.matchReliability?.toDouble(),
      ).round(),
      60,
      93,
    );
  }

  int _buildLandmarkQuality({
    required Map<String, dynamic> apiResponse,
    required double rawOverallSymmetry,
    required _PoseMetrics poseMetrics,
    required _AnalysisSnapshot? previousSnapshot,
  }) {
    final landmarks = apiResponse['landmarks'] as Map<String, dynamic>? ?? {};
    final baseQuality = _normalizeRealisticScore(
      _firstNumeric([
        landmarks['quality'],
        landmarks['stability'],
        apiResponse['landmark_quality'],
        apiResponse['landmark_stability'],
        rawOverallSymmetry,
      ]),
      60,
      95,
      target: 84,
    );
    final posePenalty = max(0.0, 78 - poseMetrics.poseScore) * 0.35;
    return _clampInt(
      _smoothScore(
        baseQuality - posePenalty,
        previousSnapshot?.landmarkQuality?.toDouble(),
      ).round(),
      58,
      95,
    );
  }

  int _buildMatchReliability({
    required List<CelebrityMatch> topMatches,
    required int landmarkQuality,
    required int lightingQuality,
    required _PoseMetrics poseMetrics,
    required _AnalysisSnapshot? previousSnapshot,
  }) {
    final topGap = topMatches.length > 1
        ? (topMatches.first.confidence - topMatches[1].confidence)
        : 10.0;
    final distinctiveness = _clampDouble(68 + (topGap * 1.4), 65, 90);
    final current =
        (landmarkQuality * 0.45) +
        (lightingQuality * 0.25) +
        (poseMetrics.poseScore * 0.2) +
        (distinctiveness * 0.1);
    return _clampInt(
      _smoothScore(
        current,
        previousSnapshot?.matchReliability?.toDouble(),
      ).round(),
      60,
      92,
    );
  }

  FacialFeatureProfile _buildFeatureProfile(
    Map<String, dynamic> raw,
    _AnalysisSnapshot? previousSnapshot,
    int harmonyScore,
  ) {
    final regions = (raw['regions'] as List? ?? [])
        .whereType<Map>()
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();

    final primaryRaw =
        (raw['primary'] as String?) ??
        (regions.isNotEmpty ? regions.first['name'] as String? : null) ??
        previousSnapshot?.featurePrimary ??
        raw['label'] as String? ??
        'Mixed global features';
    final secondaryRaw =
        (raw['secondary'] as String?) ??
        (regions.length > 1 ? regions[1]['name'] as String? : null) ??
        previousSnapshot?.featureSecondary ??
        'Mediterranean-like';

    final confidence = _clampInt(
      _stabilizeScore(
        current: _firstNumeric([
          raw['confidence'],
          regions.isNotEmpty ? regions.first['confidence'] : null,
          harmonyScore.toDouble(),
          72,
        ]),
        previous: previousSnapshot?.featureProfileConfidence,
        min: 60,
        max: 90,
        target: 72,
      ).round(),
      60,
      90,
    );

    final primaryShare = _clampInt((confidence - 8), 52, 72);
    final secondaryShare = _clampInt((100 - primaryShare - 12), 18, 34);
    final primaryRegion = _safeRegionLabel(primaryRaw);
    final secondaryRegion = _safeRegionLabel(
      secondaryRaw == primaryRaw ? 'South Asian-like' : secondaryRaw,
    );

    return FacialFeatureProfile(
      label: 'Mixed regional resemblance',
      confidence: confidence,
      primaryRegion: primaryRegion,
      primaryShare: primaryShare,
      secondaryRegion: secondaryRegion,
      secondaryShare: secondaryShare,
      summary:
          'You resemble features commonly found in $primaryRegion ($primaryShare%) and $secondaryRegion ($secondaryShare%).',
    );
  }

  FaceArchetype _buildArchetype(
    Map<String, dynamic> raw, {
    required int symmetryScore,
    required int harmonyScore,
    required int balanceScore,
    required int noseScore,
    required int landmarkQuality,
  }) {
    final sharpness = ((noseScore * 0.6) + (symmetryScore * 0.4)).round();
    final softness = ((balanceScore * 0.6) + (harmonyScore * 0.4)).round();

    String name;
    String description;
    if (symmetryScore >= 82 && sharpness >= 80) {
      name = 'The Leader';
      description =
          'High symmetry with sharper structure gives your look a composed, decisive presence.';
    } else if (softness >= 80 && balanceScore >= 78) {
      name = 'The Charmer';
      description =
          'Balanced proportions and softer transitions create a warm, approachable appearance.';
    } else if (symmetryScore >= 77 && harmonyScore >= 78) {
      name = 'The Strategist';
      description =
          'Even structure and measured definition create a thoughtful, self-possessed look.';
    } else {
      name = 'The Thinker';
      description =
          'Balanced facial geometry with calmer contours gives an observant, steady impression.';
    }

    final confidence = _clampInt(
      ((landmarkQuality * 0.45) + (harmonyScore * 0.35) + (balanceScore * 0.2))
          .round(),
      62,
      88,
    );

    return FaceArchetype(
      name: name,
      confidence: confidence,
      description: raw['description'] as String? ?? description,
    );
  }

  MoodAnalysis _buildMood(
    Map<String, dynamic> raw,
    _AnalysisSnapshot? previousSnapshot, {
    required int landmarkQuality,
  }) {
    final rawType = (raw['type'] as String? ?? 'Neutral').trim();
    final rawConfidence = _stabilizeScore(
      current: _firstNumeric([raw['confidence'], 58]),
      previous: previousSnapshot?.moodConfidence,
      min: 45,
      max: 90,
      target: 62,
    ).round();

    var finalType = rawType.isEmpty ? 'Neutral' : rawType;
    var finalConfidence = rawConfidence;

    if (finalConfidence <= 60 || landmarkQuality < 65) {
      finalType = 'Neutral';
      finalConfidence = max(60, finalConfidence);
    } else if (previousSnapshot?.moodType != null &&
        previousSnapshot!.moodType != finalType &&
        finalConfidence < ((previousSnapshot.moodConfidence ?? 60) + 8)) {
      finalType = previousSnapshot.moodType!;
      finalConfidence = _clampInt(
        ((finalConfidence * 0.6) +
                ((previousSnapshot.moodConfidence ?? 60) * 0.4))
            .round(),
        55,
        86,
      );
    }

    return MoodAnalysis(
      type: finalType,
      confidence: _clampInt(finalConfidence, 55, 90),
    );
  }

  Map<String, double> _normalizeFeatureMap(
    Map<String, double> features,
    _AnalysisSnapshot? previousSnapshot,
    double harmonyScore,
  ) {
    final normalized = <String, double>{};
    for (final entry in features.entries) {
      final previousValue = previousSnapshot?.featureScores[entry.key];
      final stabilized = _stabilizeScore(
        current: _percentFromValue(entry.value),
        previous: previousValue == null ? null : previousValue * 100,
        min: 60,
        max: 90,
        target: harmonyScore,
      );
      normalized[entry.key] = (stabilized / 100).clamp(0.0, 1.0);
    }
    return normalized;
  }

  String _buildExplanation(
    String? apiExplanation,
    String celebrityName,
    int matchReliability,
    _PoseMetrics poseMetrics,
  ) {
    final base = (apiExplanation == null || apiExplanation.trim().isEmpty)
        ? 'Analysis complete.'
        : apiExplanation.trim();
    final alignmentNote = poseMetrics.roll.abs() > 8
        ? ' Slight head tilt reduced certainty slightly.'
        : ' Alignment looked stable for this frame.';
    return '$base Best resemblance is $celebrityName with $matchReliability% match reliability.$alignmentNote';
  }

  double _blendFeatureSignal({
    required double primary,
    required double support,
  }) {
    return (primary * 0.7) + (support * 0.3);
  }

  double _cohereFeatureScore(
    double raw,
    double harmonyScore,
    double? previous,
  ) {
    final stabilized = _stabilizeScore(
      current: raw,
      previous: previous,
      min: 60,
      max: 90,
      target: harmonyScore,
    );
    return _clampDouble(
      (stabilized * 0.82) + (harmonyScore * 0.18),
      harmonyScore - 12,
      harmonyScore + 8,
    );
  }

  List<double> _softmax(List<double> values, {double temperature = 1.0}) {
    final maxValue = values.reduce(max);
    final exps = values
        .map((value) => exp((value - maxValue) / temperature))
        .toList();
    final sumExp = exps.fold<double>(0, (sum, value) => sum + value);
    return exps.map((value) => value / sumExp).toList();
  }

  double _stabilizeScore({
    required double current,
    required double? previous,
    required double min,
    required double max,
    required double target,
  }) {
    final normalized = _normalizeRealisticScore(
      current,
      min,
      max,
      target: target,
    );
    return _clampDouble(_smoothScore(normalized, previous), min, max);
  }

  double _normalizeRealisticScore(
    double raw,
    double min,
    double max, {
    required double target,
  }) {
    final percent = _percentFromValue(raw);
    final compressed = target + ((percent - target) * 0.72);
    return _clampDouble(compressed, min, max);
  }

  double _smoothScore(double current, double? previous) {
    if (previous == null) return current;
    return (current * 0.7) + (previous * 0.3);
  }

  double _percentFromValue(dynamic value) {
    if (value == null) return 0;
    final numeric = (value as num).toDouble();
    return numeric <= 1.0 ? numeric * 100 : numeric;
  }

  double _firstNumeric(List<dynamic> values) {
    for (final value in values) {
      if (value is num) return value.toDouble();
    }
    return 0;
  }

  double _clampDouble(double value, double min, double max) {
    return value.clamp(min, max).toDouble();
  }

  int _clampInt(int value, int min, int max) {
    return value.clamp(min, max);
  }

  String _safeRegionLabel(String raw) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return 'mixed global features';
    if (cleaned.toLowerCase().startsWith('you resemble')) return cleaned;
    if (cleaned.toLowerCase().endsWith('-like')) return cleaned;
    if (cleaned.toLowerCase().contains('features commonly found in')) {
      return cleaned.replaceFirst(
        RegExp(r'^.*in\s+', caseSensitive: false),
        '',
      );
    }
    return '$cleaned-like';
  }
}

class _AnalysisSnapshot {
  final double? celebrityConfidence;
  final Map<String, double> topMatchScores;
  final double? overallSymmetry;
  final double? eyeScore;
  final double? noseScore;
  final double? mouthScore;
  final double? harmonyScore;
  final double? proportionScore;
  final double? balanceScore;
  final double? featureProfileConfidence;
  final String? featurePrimary;
  final String? featureSecondary;
  final String? moodType;
  final double? moodConfidence;
  final int? matchReliability;
  final int? landmarkQuality;
  final Map<String, double> featureScores;

  const _AnalysisSnapshot({
    required this.celebrityConfidence,
    required this.topMatchScores,
    required this.overallSymmetry,
    required this.eyeScore,
    required this.noseScore,
    required this.mouthScore,
    required this.harmonyScore,
    required this.proportionScore,
    required this.balanceScore,
    required this.featureProfileConfidence,
    required this.featurePrimary,
    required this.featureSecondary,
    required this.moodType,
    required this.moodConfidence,
    required this.matchReliability,
    required this.landmarkQuality,
    required this.featureScores,
  });

  factory _AnalysisSnapshot.fromJson(Map<String, dynamic> json) {
    return _AnalysisSnapshot(
      celebrityConfidence: (json['celebrity_confidence'] as num?)?.toDouble(),
      topMatchScores: (json['top_match_scores'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
      overallSymmetry: (json['overall_symmetry'] as num?)?.toDouble(),
      eyeScore: (json['eye_score'] as num?)?.toDouble(),
      noseScore: (json['nose_score'] as num?)?.toDouble(),
      mouthScore: (json['mouth_score'] as num?)?.toDouble(),
      harmonyScore: (json['harmony_score'] as num?)?.toDouble(),
      proportionScore: (json['proportion_score'] as num?)?.toDouble(),
      balanceScore: (json['balance_score'] as num?)?.toDouble(),
      featureProfileConfidence: (json['feature_profile_confidence'] as num?)
          ?.toDouble(),
      featurePrimary: json['feature_profile_primary'] as String?,
      featureSecondary: json['feature_profile_secondary'] as String?,
      moodType: json['mood_type'] as String?,
      moodConfidence: (json['mood_confidence'] as num?)?.toDouble(),
      matchReliability: json['match_reliability'] as int?,
      landmarkQuality: json['landmark_quality'] as int?,
      featureScores: (json['feature_scores'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, (value as num).toDouble())),
    );
  }
}

class _PoseMetrics {
  final double roll;
  final double yaw;
  final double pitch;
  final int poseScore;
  final int scaleScore;

  const _PoseMetrics({
    required this.roll,
    required this.yaw,
    required this.pitch,
    required this.poseScore,
    required this.scaleScore,
  });
}
