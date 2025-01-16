import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchanllger/page/ai_video.dart';
import 'package:bigchanllger/page/login_page.dart';
import 'package:bigchanllger/page/register_page.dart';
import 'package:bigchanllger/page/setting_page.dart';
import 'package:bigchanllger/page/buy_credits_page.dart';
import 'package:bigchanllger/page/img_to_video_page.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const AIVideo(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingPage(),
    ),
    GoRoute(
      path: '/buy-credits',
      builder: (context, state) => const BuyCreditsPage(),
    ),
    GoRoute(
      path: '/img-to-video',
      builder: (context, state) => const ImgToVideoPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BigChallenger',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
    );
  }
}
