import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_service.dart';
import 'features/face_analysis/data/datasources/face_local_data_source.dart';
import 'features/face_analysis/data/repositories/face_analysis_repository_impl.dart';
import 'features/face_analysis/domain/repositories/face_analysis_repository.dart';
import 'features/face_analysis/domain/usecases/analyze_face_usecase.dart';
import 'features/face_analysis/presentation/bloc/face_analysis_bloc.dart';
import 'features/glow_up/data/datasources/glow_up_local_data_source.dart';
import 'features/glow_up/presentation/bloc/glow_up_bloc.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // ── BLoCs ──────────────────────────────────────────────────────────────────
  sl.registerFactory(
    () => FaceAnalysisBloc(
      analyzeFaceUseCase: sl(),
      glowUpDataSource: sl(),
    ),
  );


  sl.registerFactory(
    () => GlowUpBloc(dataSource: sl()),
  );

  // ── Use Cases ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton(() => AnalyzeFaceUseCase(sl()));

  // ── Repositories ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<FaceAnalysisRepository>(
    () => FaceAnalysisRepositoryImpl(
      localDataSource: sl(),
      apiService: sl(),
    ),
  );

  // ── Network Service ────────────────────────────────────────────────────────

  sl.registerLazySingleton(() => ApiService(dio: sl()));

  // ── Data Sources ───────────────────────────────────────────────────────────
  sl.registerLazySingleton<FaceLocalDataSource>(
    () => FaceLocalDataSourceImpl(sharedPreferences: sl()),
  );

  sl.registerLazySingleton(
    () => GlowUpLocalDataSource(sharedPreferences: sl()),
  );


  // ── External ───────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Configure Dio with proper timeouts for face analysis processing
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5), // Face analysis takes time
      sendTimeout: const Duration(minutes: 5),
      contentType: 'application/json',
    ),
  );

  sl.registerLazySingleton(() => dio);
}
