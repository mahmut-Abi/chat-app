#!/bin/bash

echo "=========================================="
echo "深度分析历史会话问题"
echo "=========================================="
echo ""

echo "1. 检查 ChatScreen 初始化流程"
echo "------------------------------------------"
echo "ChatScreen.initState():"
grep -A 10 "void initState()" lib/features/chat/presentation/chat_screen.dart

echo ""
echo "2. 检查 _loadConversation 实现"
echo "------------------------------------------"
grep -A 10 "void _loadConversation()" lib/features/chat/presentation/chat_screen.dart

echo ""
echo "3. 检查路由参数传递"
echo "------------------------------------------"
grep -A 3 "ChatScreen" lib/core/routing/app_router.dart

echo ""
echo "4. 检查状态管理"
echo "------------------------------------------"
echo "_messages 变量:"
grep "_messages" lib/features/chat/presentation/chat_screen.dart | head -5

echo ""
echo "5. 验证实际的 Hive 存储"
echo "------------------------------------------"
echo "getAllConversations 实现:"
grep -A 5 "List<Map<String, dynamic>> getAllConversations" lib/core/storage/storage_service.dart

