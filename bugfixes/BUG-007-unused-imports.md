# BUG-007: 未使用的导入

## 问题描述
测试文件中存在未使用的导入语句。

## 错误信息
```
warning • Unused import
```

## 影响文件
- `test/unit/app_theme_test.dart:1` - package:flutter/material.dart
- `test/unit/http_mcp_client_sse_test.dart:3` - package:mockito/mockito.dart

## 根本原因
测试文件重构后，这些导入不再需要。

## 修复方案
移除未使用的导入语句。

## 修复内容
- 从 app_theme_test.dart 移除 flutter/material.dart 导入
- 从 http_mcp_client_sse_test.dart 移除 mockito/mockito.dart 导入

## 验证
```bash
flutter analyze | grep -E 'Unused import'
# 应该没有相关警告
```

## 优先级
🟡 中等 (Warning)

## 状态
✅ 已修复
