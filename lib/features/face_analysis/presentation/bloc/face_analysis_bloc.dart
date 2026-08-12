import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/image_utils.dart';
import 'package:mirror_me_app/features/glow_up/data/datasources/glow_up_local_data_source.dart';
import 'package:mirror_me_app/features/glow_up/domain/entities/glow_up_entry_entity.dart';
import '../../domain/usecases/analyze_face_usecase.dart';
import 'face_analysis_event.dart';
import 'face_analysis_state.dart';

class FaceAnalysisBloc extends Bloc<FaceAnalysisEvent, FaceAnalysisState> {
  final AnalyzeFaceUseCase analyzeFaceUseCase;
  final GlowUpLocalDataSource glowUpDataSource;
  final _uuid = const Uuid();

  FaceAnalysisBloc({
    required this.analyzeFaceUseCase,
    required this.glowUpDataSource,
  }) : super(FaceAnalysisInitial()) {
    on<AnalyzeFaceEvent>(_onAnalyzeFace);
    on<ResetEvent>(_onReset);
    on<SaveGlowUpEntryEvent>(_onSaveGlowUpEntry);
  }

  Future<void> _onAnalyzeFace(
    AnalyzeFaceEvent event,
    Emitter<FaceAnalysisState> emit,
  ) async {
    emit(FaceAnalysisLoading());

    try {
      if (event.imageFiles.length < 3) {
        emit(
          const FaceAnalysisError(
            'Please select at least 3 images (front, slight left, slight right).',
          ),
        );
        return;
      }

      final compressedFiles = await Future.wait(
        event.imageFiles.map((file) => ImageUtils.compressImage(file)),
      );

      final result = await analyzeFaceUseCase.execute(
        compressedFiles,
        event.userIntent,
      );
      try {
        result.fold((failure) {
          String errorMsg = failure.message;
          if (errorMsg.contains('SocketException') ||
              errorMsg.contains('timeout')) {
            errorMsg =
                'Connection timeout. Please check your internet and try again.';
          } else if (errorMsg.contains('No face detected')) {
            errorMsg =
                'No face detected in one or more images. Please try clearer photos.';
          } else if (errorMsg.contains('At least 3 valid images')) {
            errorMsg =
                'At least 3 valid images are required. Use front, slight left, and slight right with good lighting.';
          }
          emit(FaceAnalysisError(errorMsg));
          log("Error Message: $errorMsg ");
        }, (success) => emit(FaceAnalysisSuccess(success)));
      } catch (e, t) {
        log("Error: $e, trace: $t");
      }
    } catch (e, t) {
      String errorMsg = 'Unexpected error occurred';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('timeout')) {
        errorMsg =
            'Connection timeout. Please check your internet and try again.';
      }
      emit(FaceAnalysisError(errorMsg));
      log("Error: $e, trace: $t");
    }
  }

  Future<void> _onSaveGlowUpEntry(
    SaveGlowUpEntryEvent event,
    Emitter<FaceAnalysisState> emit,
  ) async {
    if (state is! FaceAnalysisSuccess) return;
    final current = state as FaceAnalysisSuccess;
    final result = current.result;

    try {
      final entry = GlowUpEntryEntity(
        id: _uuid.v4(),
        imagePath: event.originalImage.path,
        overallScore: result.overallSymmetry,
        eyeScore: result.eyeSymmetry,
        noseScore: result.noseSymmetry,
        mouthScore: result.mouthSymmetry,
        timestamp: DateTime.now(),
      );

      await glowUpDataSource.saveEntry(entry);
      emit(current.copyWith(glowUpSaved: true));
    } catch (e) {
      log("Failed to save glow-up entry: $e");
    }
  }

  void _onReset(ResetEvent event, Emitter<FaceAnalysisState> emit) {
    emit(FaceAnalysisInitial());
  }
}
