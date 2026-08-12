import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/face_analysis_entity.dart';
import '../entities/user_intent_entity.dart';

abstract class FaceAnalysisRepository {
  Future<Either<Failure, FaceAnalysisEntity>> analyzeFace(
    List<File> imageFiles,
    UserIntentEntity userIntent,
  );
  Future<Either<Failure, FaceAnalysisEntity>> getLastResult();
  Future<Either<Failure, void>> saveResult(FaceAnalysisEntity result);
}
