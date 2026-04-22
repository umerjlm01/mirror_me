import 'dart:convert';
import 'dart:io';
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
      
      // Parse top 5 matches with feature similarity
      final topMatchesRaw = apiResponse['top_matches'] as List? ?? [];
      final topMatches = _parseTopMatches(topMatchesRaw);

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
        celebrityName: celebMatch['name'] ?? 'Unknown',
        celebrityConfidence: (celebMatch['confidence'] as num? ?? 0.0)
            .toDouble(),
        celebrityImageUrl: celebMatch['image_url'] as String?,
        topMatches: topMatches,
        overallSymmetry:
            (symmetry['overall_score'] as num? ?? 0.0).toDouble() * 100,
        eyeSymmetry: (symmetry['eye_symmetry'] as num? ?? 0.0).toDouble() * 100,
        noseSymmetry:
            (symmetry['nose_alignment'] as num? ?? 0.0).toDouble() * 100,
        mouthSymmetry:
            (symmetry['mouth_alignment'] as num? ?? 0.0).toDouble() * 100,
        featureScores: features,
        explanation: apiResponse['explanation'] ?? 'Analysis complete.',
        age: insightfaceAnalysis['age'],
        gender: insightfaceAnalysis['gender'],
        leftPerfectFace: leftFile,
        rightPerfectFace: rightFile,
      );

      return Right(entity);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('timeout') || errorMsg.contains('SocketException')) {
        return Left(ServerFailure('Connection timeout. Please try again.'));
      }
      return Left(ServerFailure('Error: $errorMsg'));
    }
  }

  /// Parse top 5 matches from API response into CelebrityMatch objects
  List<CelebrityMatch> _parseTopMatches(List<dynamic> topMatchesRaw) {
    return topMatchesRaw.take(5).map((match) {
      final name = match['name'] as String? ?? 'Unknown';
      final confidence = (match['confidence'] as num? ?? 0.0).toDouble();
      final featuresData = match['features'] as Map<String, dynamic>? ?? {};
      
      final features = CelebrityFeatures(
        eyes: (featuresData['eyes'] as num? ?? 60).toInt(),
        nose: (featuresData['nose'] as num? ?? 60).toInt(),
        mouth: (featuresData['mouth'] as num? ?? 60).toInt(),
      );

      return CelebrityMatch(
        name: name,
        confidence: confidence,
        imageUrl: match['image_url'] as String?,
        features: features,
      );
    }).toList();
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
    return const Right(null);
  }
}
