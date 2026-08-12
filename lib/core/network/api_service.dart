import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../features/face_analysis/domain/entities/user_intent_entity.dart';

class ApiService {
  final Dio dio;

  ApiService({required this.dio}) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          log('API Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          log('API Error: ${error.type} - ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  /// POST /analyze-face
  /// Returns unified AI face intelligence data from at least 3 images.
  Future<Map<String, dynamic>> analyzeFace(
    List<File> images,
    UserIntentEntity userIntent,
  ) async {
    try {
      final formData = FormData();
      for (final image in images) {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              image.path,
              filename: image.path.split('/').last,
            ),
          ),
        );
      }
      formData.fields.addAll([
        MapEntry('goal', userIntent.goal),
        MapEntry('preference', userIntent.preference),
        MapEntry('glasses', userIntent.glasses),
      ]);

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
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.unknown) {
        throw Exception('Network error: ${e.message}');
      }
      throw Exception('API Error: ${e.message}');
    }
  }
}
