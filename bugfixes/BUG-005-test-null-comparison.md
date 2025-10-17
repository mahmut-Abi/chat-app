# BUG-005: 测试文件中的不必要的 null 比较

## 问题描述
test/unit/stdio_mcp_client_health_check_test.dart 中存在多个不必要的 null 比较。

## 错误信息
```
warning • The operand can't be 'null', so the condition is always 'true'
warning • The operand must be 'null', so the condition is always 'false' 
```

## 根本原因
测试中对非空值进行 null 检查，或对必定为 null 的值进行 null 检查。

## 修复方案
重写测试用例使用可空类型并正确初始化。

## 状态
✅ 已修复
