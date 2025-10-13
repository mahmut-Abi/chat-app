#!/bin/bash

echo "====================================="
echo "验证历史会话修复情况"
echo "====================================="
echo ""

echo "1. 检查最近的提交"
echo "-------------------------------------"
git log --oneline -3

echo ""
echo "2. 检查关键修改"
echo "-------------------------------------"
echo "a) ChatRepository.createConversation 是否立即保存:"
grep -A 3 "保存空对话到存储" lib/features/chat/data/chat_repository.dart

echo ""
echo "b) HomeScreen._createNewConversation 是否重新加载:"
grep -A 2 "重新加载所有对话" lib/features/chat/presentation/home_screen.dart

echo ""
echo "c) 检查 UUID 生成器:"
grep "_uuid" lib/features/chat/data/chat_repository.dart | head -3

echo ""
echo "3. 运行测试验证"
echo "-------------------------------------"
flutter test test/unit/conversation_creation_test.dart 2>&1 | head -30

echo ""
echo "4. 检查存储实现"
echo "-------------------------------------"
echo "StorageService.saveConversation:"
grep -A 5 "Future<void> saveConversation" lib/core/storage/storage_service.dart

