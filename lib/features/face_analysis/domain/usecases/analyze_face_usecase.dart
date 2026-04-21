import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/face_analysis_entity.dart';
import '../repositories/face_analysis_repository.dart';

class AnalyzeFaceUseCase {
  final FaceAnalysisRepository repository;

  AnalyzeFaceUseCase(this.repository);

  Future<Either<Failure, FaceAnalysisEntity>> execute(File imageFile) async {
    final result = await repository.analyzeFace(imageFile);
    
    // Save result if successful
    result.fold(
      (failure) => null,
      (success) => repository.saveResult(success),
    );
    
    return result;
  }
}
