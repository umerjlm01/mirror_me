import 'package:equatable/equatable.dart';
import '../../domain/entities/face_analysis_entity.dart';

abstract class FaceAnalysisState extends Equatable {
  const FaceAnalysisState();

  @override
  List<Object?> get props => [];
}

class FaceAnalysisInitial extends FaceAnalysisState {}

class FaceAnalysisLoading extends FaceAnalysisState {}

class FaceAnalysisSuccess extends FaceAnalysisState {
  final FaceAnalysisEntity result;
  final bool glowUpSaved;

  const FaceAnalysisSuccess(this.result, {this.glowUpSaved = false});

  FaceAnalysisSuccess copyWith({
    FaceAnalysisEntity? result,
    bool? glowUpSaved,
  }) {
    return FaceAnalysisSuccess(
      result ?? this.result,
      glowUpSaved: glowUpSaved ?? this.glowUpSaved,
    );
  }

  @override
  List<Object?> get props => [result, glowUpSaved];
}

class FaceAnalysisError extends FaceAnalysisState {
  final String message;

  const FaceAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}
