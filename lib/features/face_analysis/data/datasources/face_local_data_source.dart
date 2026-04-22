import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';

abstract class FaceLocalDataSource {
  Future<void> cacheLastResultPath(String path);
  Future<String?> getLastResultPath();
  Future<void> cacheLastAnalysisSnapshot(String json);
  Future<String?> getLastAnalysisSnapshot();
}

class FaceLocalDataSourceImpl implements FaceLocalDataSource {
  final SharedPreferences sharedPreferences;

  FaceLocalDataSourceImpl({required this.sharedPreferences});

  static const cachedResultPath = 'CACHED_RESULT_PATH';
  static const cachedAnalysisSnapshot = 'CACHED_ANALYSIS_SNAPSHOT';

  @override
  Future<void> cacheLastResultPath(String path) async {
    try {
      await sharedPreferences.setString(cachedResultPath, path);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<String?> getLastResultPath() async {
    try {
      return sharedPreferences.getString(cachedResultPath);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheLastAnalysisSnapshot(String json) async {
    try {
      await sharedPreferences.setString(cachedAnalysisSnapshot, json);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<String?> getLastAnalysisSnapshot() async {
    try {
      return sharedPreferences.getString(cachedAnalysisSnapshot);
    } catch (e) {
      throw CacheException();
    }
  }
}
