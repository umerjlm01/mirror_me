import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_intent_entity.dart';

abstract class FaceAnalysisEvent extends Equatable {
  const FaceAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class UploadImageEvent extends FaceAnalysisEvent {}

class CaptureImageEvent extends FaceAnalysisEvent {}

class AnalyzeFaceEvent extends FaceAnalysisEvent {
  final List<File> imageFiles;
  final UserIntentEntity userIntent;

  const AnalyzeFaceEvent(this.imageFiles, this.userIntent);

  @override
  List<Object?> get props => [imageFiles, userIntent];
}

class ResetEvent extends FaceAnalysisEvent {}

class SaveGlowUpEntryEvent extends FaceAnalysisEvent {
  final File originalImage;

  const SaveGlowUpEntryEvent(this.originalImage);

  @override
  List<Object?> get props => [originalImage];
}
