import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/domain/controller/route_controller.dart';
import 'package:flutter_front/domain/view/main_screen.dart';
import '../provider/auth_provider.dart';
import 'login_screen.dart';

/// 앱 시작 시 로그인 여부를 확인해서 메인 화면 또는 로그인 화면을 보여줌
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // build 완료 후에 Provider 접근 (안전한 호출 시점)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 앱 실행 즉시(로그인 여부와 무관하게) 위치 권한을 미리 요청
      context.read<RouteController>().ensureLocationPermission();
      context.read<AuthProvider>().checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.unknown:
        return Scaffold(
          backgroundColor: AppColors.background,
          body: const Center(child: CircularProgressIndicator()),
        );
    }
  }
}