class ApiConstants {
  ApiConstants._();

  static const String login = '/users/login';
  static const String logout = '/users/logout';
  static const String refreshToken = '/users/refresh-token';
  static const String googleLogin = '/users/google-login';
  static const String kakaoLogin = '/users/kakao-login';
  static const String checkEmailExists = '/users/exists'; // 추가

  static const String signup = '/users';
  static const String myInfo = '/users';
  static const String updateInfo = '/users';
  static const String changePassword = '/users/password';
  static const String withdraw = '/users';
}