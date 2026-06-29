import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';

enum MyPageLoadStatus { loading, loaded, error }

class MyPageProvider extends ChangeNotifier {
  MyPageLoadStatus loadStatus = MyPageLoadStatus.loading;

  int? userId;
  String? username;
  String? nickname;
  String? email;
  String? phoneNumber;

  bool isUpdatingInfo = false;
  String? infoErrorMessage;

  bool isUpdatingPassword = false;
  String? passwordErrorMessage;
  String? passwordSuccessMessage;

  bool isWithdrawing = false;
  String? withdrawErrorMessage;

  Future<void> fetchMyInfo() async {
    loadStatus = MyPageLoadStatus.loading;
    notifyListeners();

    try {
      final response = await DioClient.instance.dio.get(ApiConstants.myInfo);
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      userId = body['userId'] as int?;
      username = body['username'] as String?;
      nickname = body['nickname'] as String?;
      email = body['email'] as String?;
      phoneNumber = body['phoneNumber'] as String?;
      // ⚠️ body['password']도 응답에 들어있지만 절대 저장/표시하지 않음

      loadStatus = MyPageLoadStatus.loaded;
    } catch (_) {
      loadStatus = MyPageLoadStatus.error;
    }
    notifyListeners();
  }

  /// 회원정보 수정 (username, nickname만 변경 가능)
  Future<bool> updateInfo({
    required String newUsername,
    required String newNickname,
  }) async {
    isUpdatingInfo = true;
    infoErrorMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.dio.patch(
        ApiConstants.updateInfo,
        data: {
          'id': userId,
          'username': newUsername,
          'nickname': newNickname,
        },
      );
      username = newUsername;
      nickname = newNickname;
      return true;
    } on DioException catch (e) {
      infoErrorMessage = _parseError(e);
      return false;
    } finally {
      isUpdatingInfo = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isUpdatingPassword = true;
    passwordErrorMessage = null;
    passwordSuccessMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.dio.patch(
        ApiConstants.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      passwordSuccessMessage = '비밀번호가 변경되었습니다.';
      return true;
    } on DioException catch (e) {
      passwordErrorMessage = _parseError(e);
      return false;
    } finally {
      isUpdatingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> withdraw() async {
    isWithdrawing = true;
    withdrawErrorMessage = null;
    notifyListeners();

    try {
      await DioClient.instance.dio.delete(ApiConstants.withdraw);
      return true;
    } on DioException catch (e) {
      withdrawErrorMessage = _parseError(e);
      return false;
    } finally {
      isWithdrawing = false;
      notifyListeners();
    }
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    final body = data is String ? _tryDecode(data) : data;
    if (body is List && body.isNotEmpty) return body.first.toString();
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (body is String) return body;
    return '요청 처리 중 오류가 발생했습니다.';
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }
}