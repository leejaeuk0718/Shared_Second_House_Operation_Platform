import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/domain/controller/stay_accommodation_controller.dart';
import 'package:flutter_front/domain/controller/stay_reservation_controller.dart';
import 'package:flutter_front/domain/controller/stay_subscription_controller.dart';
import 'package:flutter_front/domain/controller/chat_bot_controller.dart';
import 'package:flutter_front/domain/controller/restaurant_controller.dart';
import 'package:flutter_front/domain/controller/route_controller.dart';
import 'package:flutter_front/common/widget/global_chatbot_fab.dart';
import 'package:flutter_front/features/auth/provider/auth_provider.dart'; // 추가
import 'package:flutter_front/features/auth/screen/auth_gate.dart';        // 추가
import 'package:flutter_front/features/auth/screen/login_screen.dart';    // 추가
import 'package:flutter_front/features/auth/screen/signup_screen.dart';   // 추가
import 'package:flutter_front/features/auth/provider/signup_provider.dart';
import 'package:flutter_front/features/mypage/provider/mypage_provider.dart'; // 추가
import 'package:flutter_front/features/mypage/screen/mypage_screen.dart';     // 추가

// [화면 Import]
import 'package:flutter_front/domain/view/stay_accommodation_list_screen.dart';
import 'package:flutter_front/domain/view/stay_accommodation_detail_screen.dart';
import 'package:flutter_front/domain/view/stay_reservation_calendar_screen.dart';
import 'package:flutter_front/domain/view/stay_my_reservation_screen.dart';
import 'package:flutter_front/domain/view/stay_my_subscription_screen.dart';
import 'package:flutter_front/domain/view/guest_chat_screen.dart';
import 'package:flutter_front/domain/view/live_route_map_screen.dart';
import 'package:flutter_front/features/auth/provider/google_signin_provider.dart';



final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()), // 추가
        ChangeNotifierProvider(create: (_) => StayAccommodationController()),
        ChangeNotifierProvider(create: (_) => StayReservationController()),
        ChangeNotifierProvider(create: (_) => StaySubscriptionController()),
        ChangeNotifierProvider(create: (_) => ChatBotController()),
        ChangeNotifierProvider(create: (_) => RestaurantController()),
        ChangeNotifierProvider(create: (_) => RouteController()),
        ChangeNotifierProvider(create: (_) => SignupProvider()),
        ChangeNotifierProvider(create: (_) => MyPageProvider()), // 추가
        ChangeNotifierProvider(create: (_) => GoogleSignInProvider())


      ],
      child: MaterialApp(
        title: '세컨하우스',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
        ),
        navigatorKey: GlobalChatbotFab.navigatorKey,
        navigatorObservers: [routeObserver],
        builder: (context, child) => GlobalChatbotFab.wrap(child),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),          // 변경: MainScreen → AuthGate
          '/login': (context) => const LoginScreen(),   // 추가
          '/signup': (context) => const SignupScreen(),  // 추가
          '/mypage': (context) => const MyPageScreen(), // 추가
          '/accommodations': (context) => const StayAccommodationListScreen(),
          '/my/reservations': (context) => const StayMyReservationScreen(),
          // '/route': (context) => const LiveRouteMapScreen(),
          '/my/subscriptions': (context) => const StayMySubscriptionScreen(),
          '/chat': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return GuestChatScreen(
              chatRoomId: args['chatRoomId'],
              currentUserId: args['currentUserId'],
              currentUserName: args['currentUserName'],
            );
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/accommodations/')) {
            final id = int.tryParse(settings.name!.split('/').last);
            if (id != null) {
              return MaterialPageRoute(builder: (_) => StayAccommodationDetailScreen(accommodationId: id));
            }
          }
          if (settings.name != null && settings.name!.startsWith('/reservations/')) {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (_) => StayReservationCalendarScreen(
                  accommodationId: args['accommodationId'],
                  accommodationName: args['accommodationName'],
                  subscriptionStartDate: args['subscriptionStartDate'] as DateTime?,
                  subscriptionEndDate: args['subscriptionEndDate'] as DateTime?,
                ),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}