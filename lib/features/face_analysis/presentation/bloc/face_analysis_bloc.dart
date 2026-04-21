import 'dart:developer';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  final _selectedImageSubject = BehaviorSubject<File?>();
  final _loadingSubject = BehaviorSubject<bool>.seeded(false);

  Stream<File?> get selectedImageStream => _selectedImageSubject.stream;
  Stream<bool> get loadingStream => _loadingSubject.stream;

  FaceAnalysisBloc({
    required this.analyzeFaceUseCase,
    required this.glowUpDataSource,
  }) : super(FaceAnalysisInitial()) {
    on<UploadImageEvent>(_onUploadImage);
    on<CaptureImageEvent>(_onCaptureImage);
    on<AnalyzeFaceEvent>(_onAnalyzeFace);
    on<ResetEvent>(_onReset);
    on<SaveGlowUpEntryEvent>(_onSaveGlowUpEntry);
  }

  Future<void> _onUploadImage(UploadImageEvent event, Emitter<FaceAnalysisState> emit) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      _selectedImageSubject.add(file);
      add(AnalyzeFaceEvent(file));
    }
  }

  Future<void> _onCaptureImage(CaptureImageEvent event, Emitter<FaceAnalysisState> emit) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      _selectedImageSubject.add(file);
      add(AnalyzeFaceEvent(file));
    }
  }

  Future<void> _onAnalyzeFace(AnalyzeFaceEvent event, Emitter<FaceAnalysisState> emit) async {
    emit(FaceAnalysisLoading());
    _loadingSubject.add(true);

    try {
      final compressedFile = await ImageUtils.compressImage(event.imageFile);
      final result = await analyzeFaceUseCase.execute(compressedFile);

      result.fold(
        (failure) {
          String errorMsg = failure.message;
          if (errorMsg.contains('SocketException') || errorMsg.contains('timeout')) {
            errorMsg = 'Connection timeout. Please check your internet and try again.';
          } else if (errorMsg.contains('No face detected')) {
            errorMsg = 'No face detected. Please try with a clearer photo.';
          }
          emit(FaceAnalysisError(errorMsg));
        },
        (success) => emit(FaceAnalysisSuccess(success)),
      );
    } catch (e) {
      String errorMsg = 'Unexpected error occurred';
      if (e.toString().contains('SocketException') || e.toString().contains('timeout')) {
        errorMsg = 'Connection timeout. Please check your internet and try again.';
      }
      emit(FaceAnalysisError(errorMsg));
      log("Error: $e");
    } finally {
      _loadingSubject.add(false);
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
    _selectedImageSubject.add(null);
    _loadingSubject.add(false);
    emit(FaceAnalysisInitial());
  }

  @override
  Future<void> close() {
    _selectedImageSubject.close();
    _loadingSubject.close();
    return super.close();
  }
}
