import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';

abstract class FaceLocalDataSource {
  Future<void> cacheLastResultPath(String path);
  Future<String?> getLastResultPath();
}

class FaceLocalDataSourceImpl implements FaceLocalDataSource {
  final SharedPreferences sharedPreferences;

  FaceLocalDataSourceImpl({required this.sharedPreferences});

  static const CACHED_RESULT_PATH = 'CACHED_RESULT_PATH';

  @override
  Future<void> cacheLastResultPath(String path) async {
    try {
      await sharedPreferences.setString(CACHED_RESULT_PATH, path);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<String?> getLastResultPath() async {
    try {
      return sharedPreferences.getString(CACHED_RESULT_PATH);
    } catch (e) {
      throw CacheException();
    }
  }
}
