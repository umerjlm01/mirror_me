import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class FaceAnalysisEvent extends Equatable {
  const FaceAnalysisEvent();

  @override
  List<Object?> get props => [];
}

class UploadImageEvent extends FaceAnalysisEvent {}

class CaptureImageEvent extends FaceAnalysisEvent {}

class AnalyzeFaceEvent extends FaceAnalysisEvent {
  final File imageFile;

  const AnalyzeFaceEvent(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

class ResetEvent extends FaceAnalysisEvent {}

class SaveGlowUpEntryEvent extends FaceAnalysisEvent {
  final File originalImage;

  const SaveGlowUpEntryEvent(this.originalImage);

  @override
  List<Object?> get props => [originalImage];
}
