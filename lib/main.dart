import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bigchallenger/page/ai_video.dart';
import 'package:bigchallenger/page/login_page.dart';
import 'package:bigchallenger/page/register_page.dart';
import 'package:bigchallenger/page/setting_page.dart';
import 'package:bigchallenger/page/buy_credits_page.dart';
import 'package:bigchallenger/page/img_to_video_page.dart';
import 'package:bigchallenger/page/text_to_video_page.dart';
import 'package:provider/provider.dart';
import 'package:bigchallenger/constants/theme.dart';
import 'package:bigchallenger/providers/theme_provider.dart';
import 'package:bigchallenger/page/video_history_page.dart';
import 'package:bigchallenger/service/database_service.dart';
import 'package:bigchallenger/service/auth_service.dart';
import 'package:bigchallenger/service/credits_service.dart';
import 'package:bigchallenger/page/histories_page.dart';
import 'package:bigchallenger/models/user_config.dart';
import 'package:bigchallenger/page/purchase_history_page.dart';
import 'package:bigchallenger/service/locale_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 删除数据库 测试用
  // await DatabaseService().deleteDatabase();

  // 初始化数据库
  await DatabaseService().database;

  // 检查认证状态
  await AuthService().checkAuth();

  // 加载用户金币
  await CreditsService().loadCredits();

  // 加载语言设置
  await LocaleService().loadLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CreditsService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
      ],
      child: const MyApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final auth = context.read<AuthService>();
    final isLoggedIn = auth.currentUser != null;

    if (!isLoggedIn &&
        state.uri.path != '/login' &&
        state.uri.path != '/register') {
      return '/login';
    }

    if (isLoggedIn &&
        (state.uri.path == '/login' || state.uri.path == '/register')) {
      return '/home';
    }

    return null;
  },
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
    GoRoute(
      path: '/text-to-video',
      builder: (context, state) => const TextToVideoPage(),
    ),
    GoRoute(
      path: '/video-history',
      builder: (context, state) => const VideoHistoryPage(),
    ),
    GoRoute(
      path: '/histories',
      builder: (context, state) => const HistoriesPage(),
    ),
    GoRoute(
      path: '/purchase-history',
      builder: (context, state) => const PurchaseHistoryPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'BigChallenger',
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
