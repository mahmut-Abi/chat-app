#!/bin/bash

echo "测试对话创建和保存功能"
echo "============================"
echo ""

# 创建测试脚本
cat > test_storage.dart << 'DARTEOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/storage/storage_service.dart';
import 'package:chat_app/features/chat/data/chat_repository.dart';
import 'package:chat_app/core/network/openai_api_client.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'conversation_creation_test.mocks.dart';

@GenerateMocks([OpenAIApiClient, StorageService])
void main() {
  test('验证对话ID唯一性', () async {
    final mockApiClient = MockOpenAIApiClient();
    final mockStorage = MockStorageService();
    final repo = ChatRepository(mockApiClient, mockStorage);
    
    // 模拟保存
    when(mockStorage.saveConversation(any, any)).thenAnswer((_) async {});
    
    // 创建多个对话
    final conv1 = await repo.createConversation(title: '对话1');
    final conv2 = await repo.createConversation(title: '对话2');
    final conv3 = await repo.createConversation(title: '对话3');
    
    print('对话1 ID: \${conv1.id}');
    print('对话2 ID: \${conv2.id}');
    print('对话3 ID: \${conv3.id}');
    
    // 验证ID唯一性
    expect(conv1.id != conv2.id, true, reason: '对话1和对话2的ID不应该相同');
    expect(conv2.id != conv3.id, true, reason: '对话2和对话3的ID不应该相同');
    expect(conv1.id != conv3.id, true, reason: '对话1和对话3的ID不应该相同');
    
    // 验证保存被调用
    verify(mockStorage.saveConversation(conv1.id, any)).called(1);
    verify(mockStorage.saveConversation(conv2.id, any)).called(1);
    verify(mockStorage.saveConversation(conv3.id, any)).called(1);
  });
}
DARTEOF

echo "测试脚本已创建: test_storage.dart"
echo "请运行: flutter test test_storage.dart"
