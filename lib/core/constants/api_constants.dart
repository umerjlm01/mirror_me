import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Use a getter instead of 'static const'
  static String get baseUrl =>
      dotenv.env['IP_ADDRESS'] ?? 'http://localhost:8000';

  static const String analyzeFaceEndpoint = '/analyze-face';
}
