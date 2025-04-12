import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ai_video/page/ai_video.dart';
import 'package:ai_video/page/login_page.dart';
import 'package:ai_video/page/register_page.dart';
import 'package:ai_video/page/setting_page.dart';
import 'package:ai_video/page/subscribe_page.dart';
import 'package:ai_video/page/img_to_video_page.dart';
import 'package:ai_video/page/text_to_video_page.dart';
import 'package:provider/provider.dart' as provider;
import 'package:ai_video/constants/theme.dart';
import 'package:ai_video/providers/theme_provider.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/service/auth_service.dart';
import 'package:ai_video/service/user_service.dart';
import 'package:ai_video/page/coin_logs.dart';
import 'package:ai_video/service/locale_service.dart';
import 'package:ai_video/page/mine_page.dart';
import 'package:ai_video/service/apple_payment_service.dart';
import 'package:ai_video/page/theme_detail_page.dart';
import 'package:ai_video/page/make_collage_page.dart';
import 'package:video_player/video_player.dart';
import 'package:ai_video/page/buy_coins_page.dart';
import 'package:ai_video/page/splash_screen.dart';
import 'package:ai_video/page/video_processing_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:ai_video/page/refer_friends_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 删除数据库 测试用
  // await DatabaseService().deleteDatabase();

  // 初始化数据库
  await DatabaseService().database;

  // 检查认证状态
  await AuthService().checkAuth();

  // 加载用户金币
  await UserService().initUser();

  // 加载语言设置
  await LocaleService().loadLocale();

  // 初始化苹果支付
  ApplePaymentService().initialize();

  runApp(
    ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
          provider.ChangeNotifierProvider(create: (_) => AuthService()),
          provider.ChangeNotifierProvider(create: (_) => UserService()),
          provider.ChangeNotifierProvider(create: (_) => LocaleService()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (state.uri.path == '/') {
      return null;
    }

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
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return child;
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const AIVideo(),
          ),
        ),
        GoRoute(
          path: '/mine',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const MinePage(),
          ),
        ),
      ],
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
      path: '/buy-coins',
      builder: (context, state) => const BuyCoinsPage(),
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
      path: '/coin-logs',
      builder: (context, state) => const CoinLogsPage(),
    ),
    GoRoute(
      path: '/theme-detail',
      pageBuilder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        return NoTransitionPage(
          child: ThemeDetailPage(
            title: extra['title'] as String? ?? '',
            imagePath: extra['imagePath'] as String? ?? '',
            videoUrl: extra['videoUrl'] as String?,
            preloadedController:
                extra['preloadedController'] as VideoPlayerController?,
            imgNum: extra['imgNum'] as int? ?? 1,
            prompt: extra['prompt'] as String? ?? '',
            sampleId: extra['sampleId'] as int? ?? 0,
          ),
        );
      },
    ),
    GoRoute(
      path: '/make-collage',
      pageBuilder: (context, state) => NoTransitionPage(
        child: MakeCollagePage(
          imgNum: (state.extra as Map<String, dynamic>)['imgNum'] ?? 1,
          sampleId: (state.extra as Map<String, dynamic>)['sampleId'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: '/processing',
      builder: (context, state) => const VideoProcessingPage(),
    ),
    GoRoute(
      path: '/refer-friends',
      builder: (context, state) => const ReferFriendsPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.Consumer<ThemeProvider>(
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
