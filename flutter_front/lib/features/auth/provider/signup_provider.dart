import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';

class SignupProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  Future<bool> signup({
    required String username,
    required String password,
    required String nickname,
    required String email,
    required String phoneNumber,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.dio.post(
        ApiConstants.signup,
        data: {
          'username': username,
          'password': password,
          'nickname': nickname,
          'email': email,
          'phoneNumber': phoneNumber,
        },
      );
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    final body = data is String ? _tryDecode(data) : data;

    // 백엔드 @Valid 실패 시 List<String> 형태로 에러 메시지를 내려줌
    if (body is List && body.isNotEmpty) {
      return body.first.toString();
    }
    if (body is Map && body['message'] != null) {
      return body['message'].toString();
    }
    if (e.response?.statusCode == 409) {
      return '이미 사용 중인 아이디 또는 이메일입니다.';
    }
    return '회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }
}