import 'package:flutter/material.dart';

/// 세컨하우스 컬러 팔레트
/// 웹 버전의 베이지/크림 + 포레스트 그린 톤을 모바일에 맞게 재구성
class AppColors {
  AppColors._();

  // Base - 베이지/크림
  static const Color background = Color(0xFFFAF7F0); // 크림 배경
  static const Color surface = Color(0xFFFFFFFF); // 카드/입력창 배경
  static const Color surfaceVariant = Color(0xFFF3EEE2); // 살짝 톤다운된 베이지

  // Primary - 포레스트 그린
  static const Color primary = Color(0xFF2D5A3D); // 메인 포레스트 그린
  static const Color primaryLight = Color(0xFF4A7A5C);
  static const Color primaryDark = Color(0xFF1E3F2A);

  // Text
  static const Color textPrimary = Color(0xFF2B2620);
  static const Color textSecondary = Color(0xFF7A7265);
  static const Color textHint = Color(0xFFB0A89A);

  // Border
  static const Color border = Color(0xFFE4DDCB);
  static const Color borderFocused = primary;

  // Status
  static const Color error = Color(0xFFC1473B);
  static const Color success = Color(0xFF2D5A3D);

  // Social Login Brand Colors
  static const Color googleButtonBg = Color(0xFFFFFFFF);
  static const Color naverButtonBg = Color(0xFF03C75A);
}