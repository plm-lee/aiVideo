import 'package:flutter_test/flutter_test.dart';
import 'package:ai_video/service/credits_service.dart';
import 'package:ai_video/service/database_service.dart';
import 'package:ai_video/models/user_config.dart';
import 'package:ai_video/models/user.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([MockSpec<DatabaseService>()])
import 'credits_service_test.mocks.dart';

void main() {
  late CreditsService creditsService;
  late MockDatabaseService mockDatabaseService;

  setUp(() {
    mockDatabaseService = MockDatabaseService();
    // 重新创建 CreditsService 实例，而不是使用单例
    creditsService = CreditsService.test();
    creditsService.databaseService = mockDatabaseService;
  });

  group('CreditsService Tests', () {
    test('loadCredits should load credits from database', () async {
      // 准备测试数据
      final testConfig = UserConfig(key: 'user_credits', value: '1000');
      when(mockDatabaseService.getConfig('user_credits'))
          .thenAnswer((_) async => testConfig);

      // 执行测试
      await creditsService.loadCredits();

      // 验证结果
      expect(creditsService.credits, 1000);
      verify(mockDatabaseService.getConfig('user_credits')).called(1);
    });

    test('addCredits should increase credits and save to database', () async {
      // 准备测试数据
      when(mockDatabaseService.saveConfig(any)).thenAnswer((_) async => 1);

      // 执行测试
      await creditsService.addCredits(500);

      // 验证结果
      expect(creditsService.credits, 500);
      verify(mockDatabaseService.saveConfig(any)).called(1);
    });

    test('useCredits should decrease credits if sufficient balance', () async {
      when(mockDatabaseService.saveConfig(any)).thenAnswer((_) async => 1);

      // 使用公开的 setter
      creditsService.credits = 1000;

      final result = await creditsService.useCredits(500);

      // 验证结果
      expect(result, true);
      expect(creditsService.credits, 500);
      verify(mockDatabaseService.saveConfig(any)).called(1);
    });

    test('useCredits should fail if insufficient balance', () async {
      // 使用公开的 setter
      creditsService.credits = 100;

      final result = await creditsService.useCredits(500);

      // 验证结果
      expect(result, false);
      expect(creditsService.credits, 100);
      verifyNever(mockDatabaseService.saveConfig(any));
    });

    test('addCreditsToUser should add credits to specific user', () async {
      // 准备测试数据
      final testUser = User(
        id: 1,
        email: 'test@example.com',
        token: 'test_token',
        loginTime: DateTime.now(),
      );
      when(mockDatabaseService.saveConfig(any)).thenAnswer((_) async => 1);
      when(mockDatabaseService.getConfig('user_credits_${testUser.id}'))
          .thenAnswer((_) async => UserConfig(
                key: 'user_credits_${testUser.id}',
                value: '100',
              ));

      // 执行测试
      await creditsService.addCreditsToUser(testUser.id!, 500);

      // 验证结果
      verify(mockDatabaseService.getConfig('user_credits_${testUser.id}'))
          .called(1);
      verify(mockDatabaseService.saveConfig(any)).called(1);

      // 验证保存的金币数量是否正确
      final captured =
          verify(mockDatabaseService.saveConfig(captureAny)).captured;
      final savedConfig = captured.first as UserConfig;
      expect(savedConfig.value, '600'); // 原有100 + 新增500
    });
  });
}
