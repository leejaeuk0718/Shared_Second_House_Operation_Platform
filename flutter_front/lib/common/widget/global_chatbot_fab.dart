import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/domain/view/guest_chat_bot_screen.dart';
import 'package:flutter_front/features/auth/provider/auth_provider.dart';

/// 🤖 앱 전역 플로팅 챗봇 버튼
///
/// MaterialApp.builder 로 Navigator 위에 얹어, 화면을 이동해도 버튼이
/// 그대로 따라다닌다(라우트 바깥에 있으므로 화면 전환에 영향 없음).
/// 탭하면 기존 GuestChatBotScreen 을 풀스크린으로 push 한다. 대화 상태는
/// ChatBotController(Provider)가 들고 있어 어느 화면에서 열어도 이어진다.
class GlobalChatbotFab {
  GlobalChatbotFab._();

  /// MaterialApp 의 Navigator 에 접근하기 위한 키.
  /// builder 의 context 는 Navigator 보다 위라 Navigator.of(context) 를
  /// 쓸 수 없으므로 이 키로 push 한다.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 챗봇 화면이 열려 있는 동안 true → 자기 위에 버튼이 겹쳐 뜨는 걸 막는다.
  static final ValueNotifier<bool> isOpen = ValueNotifier<bool>(false);

  /// MaterialApp.builder 에서 호출. child(=Navigator) 위에 버튼을 얹는다.
  static Widget wrap(Widget? child) {
    return Stack(
      children: [
        child ?? const SizedBox.shrink(),
        // 로그인(authenticated) 상태에서만 챗봇 버튼을 노출한다.
        // (로그인/회원가입 등 미인증 화면에서는 숨김)
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.status != AuthStatus.authenticated) {
              return const SizedBox.shrink();
            }
            return ValueListenableBuilder<bool>(
              valueListenable: isOpen,
              builder: (context, open, _) {
                if (open) return const SizedBox.shrink();
                return Positioned(
                  right: 16,
                  bottom: 75,
                  child: SafeArea(child: _ChatbotButton()),
                );
              },
            );
          },
        ),
      ],
    );
  }

  static Future<void> _openChat() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    isOpen.value = true;
    await navigator.push(
      MaterialPageRoute(builder: (_) => const GuestChatBotScreen()),
    );
    isOpen.value = false;
  }
}

class _ChatbotButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Scaffold/Overlay 밖이라 FloatingActionButton 대신 Material+InkWell 로
    // 자급자족 버튼을 구성한다(필요 의존: Directionality 뿐, builder 가 제공).
    // React FloatingChatbot 의 .fab 디자인과 동일하게:
    // 60px 원, primary 배경, 💬 이모지, 그림자 0 4px 14px rgba(0,0,0,0.25)
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000), // rgba(0,0,0,0.25)
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: GlobalChatbotFab._openChat,
          child: const Center(
            child: Text('💬', style: TextStyle(fontSize: 26)),
          ),
        ),
      ),
    );
  }
}