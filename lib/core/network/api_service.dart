import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class ApiService {
  final Dio dio;

  ApiService({required this.dio}) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('API Error: ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// POST /analyze-face
  /// Returns unified AI face intelligence data.
  Future<Map<String, dynamic>> analyzeFace(File image) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          image.path,
          filename: image.path.split('/').last,
        ),
      });

      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.analyzeFaceEndpoint}',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to analyze face: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.unknown) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('API Error: ${e.message}');
    }
  }
}
