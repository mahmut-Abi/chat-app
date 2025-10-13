#!/bin/bash

echo "===================================="
echo "对话创建和保存调试脚本"
echo "===================================="
echo ""

echo "1. 检查 StorageService 实现"
echo "-----------------------------------"
grep -A 10 "saveConversation" lib/core/storage/storage_service.dart

echo ""
echo "2. 检查 ChatRepository.createConversation"
echo "-----------------------------------"
grep -A 20 "Future<Conversation> createConversation" lib/features/chat/data/chat_repository.dart

echo ""
echo "3. 检查 HomeScreen 创建对话逻辑"
echo "-----------------------------------"
grep -A 15 "_createNewConversation" lib/features/chat/presentation/home_screen.dart | head -20

echo ""
echo "4. 检查路由配置"
echo "-----------------------------------"
grep -A 5 "path: '/chat/:id'" lib/core/routing/app_router.dart

