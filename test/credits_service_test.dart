import 'package:flutter_test/flutter_test.dart';
import 'package:bigchanllger/service/credits_service.dart';
import 'package:bigchanllger/service/database_service.dart';
import 'package:bigchanllger/models/user_config.dart';
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
      // 准备测试数据
      when(mockDatabaseService.saveConfig(any)).thenAnswer((_) async => 1);

      // 直接设置初始金币数量，而不是通过 addCredits
      creditsService._credits = 1000;

      // 执行测试
      final result = await creditsService.useCredits(500);

      // 验证结果
      expect(result, true);
      expect(creditsService.credits, 500);
      verify(mockDatabaseService.saveConfig(any)).called(1);
    });

    test('useCredits should fail if insufficient balance', () async {
      // 直接设置初始金币数量
      creditsService._credits = 100;

      // 执行测试
      final result = await creditsService.useCredits(500);

      // 验证结果
      expect(result, false);
      expect(creditsService.credits, 100);
      verifyNever(mockDatabaseService.saveConfig(any));
    });
  });
}
