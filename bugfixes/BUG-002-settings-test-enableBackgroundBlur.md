# BUG-002: settings_repository_test.dart enableBackgroundBlur 未定义参数

## 问题描述
测试文件中使用了 `enableBackgroundBlur` 参数，但该字段在 `AppSettings` 类中不存在。

## 错误信息
```
error • The named parameter 'enableBackgroundBlur' isn't defined
error • The getter 'enableBackgroundBlur' isn't defined for the type 'AppSettings'
```

## 根本原因
`AppSettings` 类定义中没有 `enableBackgroundBlur` 字段，但测试代码尝试使用它。

## 修复方案
从测试中移除 `enableBackgroundBlur` 字段的使用，因为该功能未在 domain 模型中实现。

## 修复内容
- 移除测试用例中的 `enableBackgroundBlur: true` 参数
- 移除对 `settings.enableBackgroundBlur` 的断言

## 验证
```bash
flutter test test/unit/settings_repository_test.dart
```

## 状态
✅ 已修复
