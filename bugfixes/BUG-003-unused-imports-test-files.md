# BUG-003: 测试文件中的未使用导入

## 问题描述
多个测试文件包含未使用的导入：
- `test/unit/stdio_mcp_client_health_check_test.dart` - `import 'dart:io'`
- `test/unit/stdio_mcp_client_test.dart` - `import 'package:mockito/mockito.dart'`, `import 'package:mockito/annotations.dart'`, `import 'package:dio/dio.dart'`

## 错误信息
```
warning • Unused import: 'dart:io'
warning • Unused import: 'package:mockito/mockito.dart'
warning • Unused import: 'package:mockito/annotations.dart'
warning • Unused import: 'package:dio/dio.dart'
```

## 根本原因
测试代码重构后，这些导入不再需要。

## 修复方案
移除未使用的导入。

## 修复内容
- 从 `stdio_mcp_client_health_check_test.dart` 移除 `dart:io` 导入
- 从 `stdio_mcp_client_test.dart` 移除 3 个未使用的导入

## 验证
```bash
flutter analyze test/unit/stdio_mcp_client_health_check_test.dart test/unit/stdio_mcp_client_test.dart
```

## 状态
✅ 已修复
