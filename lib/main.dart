import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/page/ai_video.dart';
import 'package:ai_video/page/login_page.dart';
import 'package:ai_video/page/register_page.dart';
import 'package:ai_video/page/setting_page.dart';
import 'package:ai_video/page/subscribe_page.dart';
import 'package:ai_video/page/img_to_video_page.dart';
import 'package:ai_video/page/text_to_video_page.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/constants/theme.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/page/video_history_page.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/service/credits_service.dart';
import 'package:ai_video/page/histories_page.dart';
import 'package:ai_video/page/purchase_history_page.dart';
import 'package:ai_video/service/locale_service.dart';
import 'package:ai_video/page/mine_page.dart';

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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const AIVideo(),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingPage(),
    ),
    GoRoute(
      path: '/subscribe',
      builder: (context, state) => const SubscribePage(),
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
    GoRoute(
      path: '/mine',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const MinePage(),
      ),
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
          title: 'ai_video',
          theme: AppTheme.getDarkTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: _router,
        );
      },
    );
  }
}
