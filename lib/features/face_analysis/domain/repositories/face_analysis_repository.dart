import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/face_analysis_entity.dart';

abstract class FaceAnalysisRepository {
  Future<Either<Failure, FaceAnalysisEntity>> analyzeFace(File imageFile);
  Future<Either<Failure, FaceAnalysisEntity>> getLastResult();
  Future<Either<Failure, void>> saveResult(FaceAnalysisEntity result);
}
