# BUG-006: 未使用的局部变量

## 问题描述
多个文件中存在定义但未使用的局部变量，导致代码警告。

## 错误信息
```
warning • The value of the local variable 'xxx' isn't used
```

## 影响文件
- `lib/shared/widgets/background_container.dart:49` - maskOpacity
- `test/unit/auto_scroll_logic_test.dart:14,25,26` - isAtBottom (3处)
- `test/unit/message_bubble_layout_test.dart:127,139` - modelName (2处)
- `test/unit/http_mcp_client_sse_test.dart:14,173` - client, timeout
- `test/unit/api_provider_support_test.dart:193` - baseUrl

## 根本原因
这些变量被定义后没有被使用，是重构代码时遗留的未清理代码。

## 修复方案
移除所有未使用的变量定义。

## 修复内容
- 从 background_container.dart 移除 maskOpacity
- 从 auto_scroll_logic_test.dart 移除 3 个未使用的 isAtBottom
- 从 message_bubble_layout_test.dart 移除 2 个未使用的 modelName
- 从 http_mcp_client_sse_test.dart 移除 client 和 timeout
- 从 api_provider_support_test.dart 移除 baseUrl

## 验证
```bash
flutter analyze | grep -E 'warning.*unused'
# 修复前: 10个警告
# 修复后: 0个相关警告
```

## 优先级
🟡 中等 (Warning)

## 状态
✅ 已修复
