import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


/// 구글 로그인 처리 상태
enum GoogleSignInStep {
  idle,
  checkingEmail,
  needsAdditionalInfo, // 신규 유저: 휴대폰번호 등 추가정보 필요
  submitting,
  done,
}

class GoogleSignInProvider extends ChangeNotifier {
  // ⚠️ google_sign_in 6.x API 사용 중. pubspec.yaml의 ^6.2.1 제약을 ^7.0.0 이상으로
  // 올리면 GoogleSignIn() 생성자, signIn() 메서드가 제거되어 전체 재작성 필요함.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
  );
  GoogleSignInStep step = GoogleSignInStep.idle;
  String? errorMessage;

  // 구글 로그인 후, 추가정보 입력 화면에서 쓸 임시 데이터
  String? _pendingGeneratedUsername;
  String? _pendingGeneratedPassword;
  String? _pendingEmail;
  String? _pendingNickname;

  String? get pendingNickname => _pendingNickname;
  String? get pendingEmail => _pendingEmail;

  /// 1단계: 구글 계정 선택 → 이메일 가입여부 확인까지
  Future<void> startGoogleSignIn() async {
    errorMessage = null;
    step = GoogleSignInStep.checkingEmail;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // 사용자가 계정 선택 취소
        step = GoogleSignInStep.idle;
        notifyListeners();
        return;
      }

      final email = account.email;
      final googleId = account.id; // 구글 계정 고유 ID
      final displayName = account.displayName ?? '';

      _pendingEmail = email;
      _pendingGeneratedUsername = 'google_$googleId';
      _pendingGeneratedPassword = const Uuid().v4();
      _pendingNickname = _sanitizeNickname(displayName);

      final exists = await _checkEmailExists(email);

      if (exists) {
        // 기존 유저 → 바로 로그인 처리
        await _submitGoogleLogin(phoneNumber: null);
      } else {
        // 신규 유저 → 추가정보 입력 화면으로
        step = GoogleSignInStep.needsAdditionalInfo;
        notifyListeners();
      }
    } catch (e, stack) {
      print('🔴 구글 로그인 에러: $e'); // 디버그용
      print('🔴 스택트레이스: $stack');   // 디버그용
      errorMessage = '구글 로그인 중 오류가 발생했습니다.';
      step = GoogleSignInStep.idle;
      notifyListeners();
    }
  }

  /// 2단계: 신규 유저가 추가정보(휴대폰번호 등) 입력 완료 후 호출
  Future<bool> completeSignUpWithPhoneNumber(String phoneNumber) async {
    step = GoogleSignInStep.submitting;
    notifyListeners();

    final success = await _submitGoogleLogin(phoneNumber: phoneNumber);
    return success;
  }

  Future<bool> _submitGoogleLogin({String? phoneNumber}) async {
    try {
      final response = await DioClient.instance.dio.post(
        ApiConstants.googleLogin,
        data: {
          'username': _pendingGeneratedUsername,
          'password': _pendingGeneratedPassword,
          'nickname': _pendingNickname,
          'email': _pendingEmail,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final accessToken = body['accessToken'] as String;
      await SecureStorage.instance.saveAccessToken(accessToken);

      step = GoogleSignInStep.done;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      errorMessage = _parseError(e);
      step = GoogleSignInStep.idle;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _checkEmailExists(String email) async {
    final response = await DioClient.instance.dio.get(
      ApiConstants.checkEmailExists,
      queryParameters: {'email': email},
    );
    print('🔍 /exists 응답: ${response.data}'); // 디버그용
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    final result = body['exists'] as bool? ?? false;
    print('🔍 exists 판정 결과: $result'); // 디버그용
    return result;
  }

  /// 구글 displayName을 닉네임 규칙(한글/영문/숫자 2~10자)에 맞게 다듬음.
  /// 규칙 위반 시 사용자가 추가정보 화면에서 직접 수정 가능하도록 빈 값은 안 만듦.
  String _sanitizeNickname(String displayName) {
    final filtered =
    displayName.replaceAll(RegExp(r'[^가-힣a-zA-Z0-9]'), '');
    if (filtered.length < 2) return 'user${DateTime.now().millisecondsSinceEpoch % 10000}';
    if (filtered.length > 10) return filtered.substring(0, 10);
    return filtered;
  }

  String _parseError(DioException e) {
    final data = e.response?.data;
    final body = data is String ? _tryDecode(data) : data;
    if (body is List && body.isNotEmpty) return body.first.toString();
    if (body is Map && body['message'] != null) return body['message'].toString();
    if (e.response?.statusCode == 409) {
      return '이미 일반 회원으로 가입된 이메일입니다. 일반 로그인을 이용해주세요.';
    }
    return '구글 로그인 처리 중 오류가 발생했습니다.';
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  Future<void> reset() async {
    step = GoogleSignInStep.idle;
    errorMessage = null;
    await _googleSignIn.signOut(); // 다음 로그인 때 계정 선택창이 다시 뜨도록
  }
}