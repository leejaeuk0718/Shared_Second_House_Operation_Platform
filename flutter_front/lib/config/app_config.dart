import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => '${dotenv.env['PUBLIC_SERVER_URL'] ?? 'http://10.0.2.2:8080'}/api';
  static String get imageBaseUrl => dotenv.env['PUBLIC_SERVER_URL'] ?? 'http://10.0.2.2:8080';
}
