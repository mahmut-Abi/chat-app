import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/settings/presentation/widgets/api_config_basic_section.dart';

void main() {
  group('ApiConfigBasicSection Widget 测试', () {
    late TextEditingController nameController;
    late TextEditingController baseUrlController;
    late TextEditingController apiKeyController;
    late TextEditingController organizationController;

    setUp(() {
      nameController = TextEditingController();
      baseUrlController = TextEditingController();
      apiKeyController = TextEditingController();
      organizationController = TextEditingController();
    });

    tearDown(() {
      nameController.dispose();
      baseUrlController.dispose();
      apiKeyController.dispose();
      organizationController.dispose();
    });

    testWidgets('应该正确显示所有输入字段', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: ApiConfigBasicSection(
                nameController: nameController,
                baseUrlController: baseUrlController,
                apiKeyController: apiKeyController,
                organizationController: organizationController,
                selectedProvider: 'OpenAI',
                onProviderChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // 验证标题
      expect(find.text('基本配置'), findsOneWidget);

      // 验证输入字段
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // 验证标签
      expect(find.text('配置名称 *'), findsOneWidget);
      expect(find.text('API 提供商'), findsOneWidget);
      expect(find.text('Base URL *'), findsOneWidget);
      expect(find.text('API Key *'), findsOneWidget);
      expect(find.text('组织 ID (可选)'), findsOneWidget);
    });

    testWidgets('应该验证必填字段', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: ApiConfigBasicSection(
                nameController: nameController,
                baseUrlController: baseUrlController,
                apiKeyController: apiKeyController,
                organizationController: organizationController,
                selectedProvider: 'OpenAI',
                onProviderChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // 尝试验证空表单
      final isValid = formKey.currentState!.validate();
      expect(isValid, false);

      await tester.pump();

      // 应该显示错误信息
      expect(find.text('请输入配置名称'), findsOneWidget);
      expect(find.text('请输入 Base URL'), findsOneWidget);
      expect(find.text('请输入 API Key'), findsOneWidget);
    });

    testWidgets('应该正确触发提供商变更回调', (WidgetTester tester) async {
      String? changedProvider;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: ApiConfigBasicSection(
                nameController: nameController,
                baseUrlController: baseUrlController,
                apiKeyController: apiKeyController,
                organizationController: organizationController,
                selectedProvider: 'OpenAI',
                onProviderChanged: (provider) {
                  changedProvider = provider;
                },
              ),
            ),
          ),
        ),
      );

      // 点击下拉框
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // 选择 Azure OpenAI
      await tester.tap(find.text('Azure OpenAI').last);
      await tester.pumpAndSettle();

      expect(changedProvider, 'Azure OpenAI');
    });
  });
}
