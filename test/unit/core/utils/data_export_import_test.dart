import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chat_app/core/utils/data_export_import.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'dart:convert';

@GenerateMocks([StorageService])
import 'data_export_import_test.mocks.dart';

void main() {
  group('DataExportImport', () {
    late DataExportImport exportImport;
    late MockStorageService mockStorage;

    setUp(() {
      mockStorage = MockStorageService();
      exportImport = DataExportImport(mockStorage);
    });

    group('数据导出', () {
      test('应该成功导出所有数据', () async {
        // Arrange
        final conversations = [
          {'id': 'conv1', 'title': '会话1'},
          {'id': 'conv2', 'title': '会话2'},
        ];
        final apiConfigs = [
          {'id': 'api1', 'name': 'API配置1'},
        ];

        when(mockStorage.getAllConversations()).thenReturn(conversations);
        when(
          mockStorage.getAllApiConfigs(),
        ).thenAnswer((_) async => apiConfigs);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        expect(result, isNotEmpty);
        final data = jsonDecode(result);
        expect(data['version'], '1.0.0');
        expect(data['conversations'], equals(conversations));
        expect(data['apiConfigs'], equals(apiConfigs));
      });

      test('应该包含导出日期', () async {
        // Arrange
        when(mockStorage.getAllConversations()).thenReturn([]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        final data = jsonDecode(result);
        expect(data['exportDate'], isNotNull);
        expect(data['exportDate'], isA<String>());
      });

      test('应该导出空数据', () async {
        // Arrange
        when(mockStorage.getAllConversations()).thenReturn([]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        final data = jsonDecode(result);
        expect(data['conversations'], isEmpty);
        expect(data['apiConfigs'], isEmpty);
      });

      test('应该返回有效的 JSON 字符串', () async {
        // Arrange
        when(mockStorage.getAllConversations()).thenReturn([
          {'id': 'conv1', 'title': '测试'},
        ]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        expect(() => jsonDecode(result), returnsNormally);
      });
    });

    group('数据导入', () {
      test('应该成功导入会话数据', () async {
        // Arrange
        final jsonData = jsonEncode({
          'version': '1.0.0',
          'conversations': [
            {'id': 'conv1', 'title': '会话1'},
            {'id': 'conv2', 'title': '会话2'},
          ],
        });

        when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isTrue);
        expect(result['conversationsCount'], 2);
        verify(mockStorage.saveConversation('conv1', any)).called(1);
        verify(mockStorage.saveConversation('conv2', any)).called(1);
      });

      test('应该成功导入 API 配置', () async {
        // Arrange
        final jsonData = jsonEncode({
          'version': '1.0.0',
          'apiConfigs': [
            {'id': 'api1', 'name': 'API配置1'},
          ],
        });

        when(mockStorage.saveApiConfig(any, any)).thenAnswer((_) async {});

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isTrue);
        expect(result['apiConfigsCount'], 1);
        verify(mockStorage.saveApiConfig('api1', any)).called(1);
      });

      test('应该导入所有类型的数据', () async {
        // Arrange
        final jsonData = jsonEncode({
          'version': '1.0.0',
          'conversations': [
            {'id': 'conv1', 'title': '会话1'},
          ],
          'apiConfigs': [
            {'id': 'api1', 'name': 'API配置1'},
            {'id': 'api2', 'name': 'API配置2'},
          ],
        });

        when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});
        when(mockStorage.saveApiConfig(any, any)).thenAnswer((_) async {});

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isTrue);
        expect(result['conversationsCount'], 1);
        expect(result['apiConfigsCount'], 2);
      });

      test('应该处理空数据导入', () async {
        // Arrange
        final jsonData = jsonEncode({'version': '1.0.0'});

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isTrue);
        expect(result['conversationsCount'], 0);
        expect(result['apiConfigsCount'], 0);
      });

      test('应该在无效 JSON 时返回错误', () async {
        // Arrange
        const invalidJson = 'invalid json';

        // Act
        final result = await exportImport.importData(invalidJson);

        // Assert
        expect(result['success'], isFalse);
        expect(result['error'], isNotNull);
      });

      test('应该处理格式错误的数据', () async {
        // Arrange
        final jsonData = jsonEncode({
          'conversations': 'not a list', // 应该是列表
        });

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isFalse);
      });
    });

    group('导出导入循环测试', () {
      test('应该能够导出后再导入相同的数据', () async {
        // Arrange
        final originalConversations = [
          {'id': 'conv1', 'title': '会话1'},
        ];
        final originalApiConfigs = [
          {'id': 'api1', 'name': 'API配置1'},
        ];

        when(
          mockStorage.getAllConversations(),
        ).thenReturn(originalConversations);
        when(
          mockStorage.getAllApiConfigs(),
        ).thenAnswer((_) async => originalApiConfigs);
        when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});
        when(mockStorage.saveApiConfig(any, any)).thenAnswer((_) async {});

        // Act - 导出
        final exported = await exportImport.exportAllData();

        // Act - 导入
        final result = await exportImport.importData(exported);

        // Assert
        expect(result['success'], isTrue);
        expect(result['conversationsCount'], 1);
        expect(result['apiConfigsCount'], 1);
      });
    });

    group('数据完整性', () {
      test('应该保留所有字段', () async {
        // Arrange
        final conversation = {
          'id': 'conv1',
          'title': '测试会话',
          'createdAt': '2025-01-17T12:00:00.000Z',
          'messages': [
            {'role': 'user', 'content': '你好'},
          ],
        };

        final jsonData = jsonEncode({
          'version': '1.0.0',
          'conversations': [conversation],
        });

        Map<String, dynamic>? savedConversation;
        when(mockStorage.saveConversation(any, any)).thenAnswer((
          invocation,
        ) async {
          savedConversation =
              invocation.positionalArguments[1] as Map<String, dynamic>;
        });

        // Act
        await exportImport.importData(jsonData);

        // Assert
        expect(savedConversation, isNotNull);
        expect(savedConversation!['id'], 'conv1');
        expect(savedConversation!['title'], '测试会话');
        expect(savedConversation!['createdAt'], isNotNull);
        expect(savedConversation!['messages'], isNotNull);
      });

      test('应该正确处理特殊字符', () async {
        // Arrange
        final conversation = {
          'id': 'conv1',
          'title': '特殊字符: @#\$%^&*() 中文 😀',
          'content': 'Line1\nLine2\tTab',
        };

        when(mockStorage.getAllConversations()).thenReturn([conversation]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);
        when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});

        // Act
        final exported = await exportImport.exportAllData();
        final result = await exportImport.importData(exported);

        // Assert
        expect(result['success'], isTrue);
      });
    });

    group('版本兼容性', () {
      test('应该在导出数据中包含版本号', () async {
        // Arrange
        when(mockStorage.getAllConversations()).thenReturn([]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        final data = jsonDecode(result);
        expect(data['version'], isNotNull);
        expect(data['version'], '1.0.0');
      });

      test('应该能够导入带版本号的数据', () async {
        // Arrange
        final jsonData = jsonEncode({
          'version': '1.0.0',
          'conversations': [],
          'apiConfigs': [],
        });

        // Act
        final result = await exportImport.importData(jsonData);

        // Assert
        expect(result['success'], isTrue);
      });
    });

    group('边界情况', () {
      test('应该处理大量数据', () async {
        // Arrange
        final conversations = List.generate(
          1000,
          (i) => {'id': 'conv$i', 'title': '会话$i'},
        );

        when(mockStorage.getAllConversations()).thenReturn(conversations);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);

        // Act
        final result = await exportImport.exportAllData();

        // Assert
        final data = jsonDecode(result);
        expect(data['conversations'].length, 1000);
      });

      test('应该处理嵌套数据结构', () async {
        // Arrange
        final conversation = {
          'id': 'conv1',
          'messages': [
            {
              'id': 'msg1',
              'content': 'Hello',
              'metadata': {'key': 'value'},
            },
          ],
          'settings': {
            'theme': 'dark',
            'options': ['opt1', 'opt2'],
          },
        };

        when(mockStorage.getAllConversations()).thenReturn([conversation]);
        when(mockStorage.getAllApiConfigs()).thenAnswer((_) async => []);
        when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});

        // Act
        final exported = await exportImport.exportAllData();
        final result = await exportImport.importData(exported);

        // Assert
        expect(result['success'], isTrue);
      });
    });
  });
}
