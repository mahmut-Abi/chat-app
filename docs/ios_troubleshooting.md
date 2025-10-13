# iOS 闪退问题排查指南

如果 iOS 应用出现闪退,请按以下步骤排查:

## 1. 查看调试日志

连接设备后,在 Xcode 中查看 Console 日志:

```bash
flutter run -d <设备ID> --verbose
```

或者在 Xcode 中:
1. 打开 `ios/Runner.xcworkspace`
2. 运行应用
3. 查看 Console 输出的错误信息

## 2. 常见闪退原因

### 问题 1: 资源加载失败

**症状**: 应用启动后立即闪退

**原因**: 背景图片等资源未正确加载

**解决方法**:
```bash
flutter clean
flutter pub get
flutter run
```

确保 `pubspec.yaml` 中包含:
```yaml
flutter:
  assets:
    - assets/backgrounds/
```

### 问题 2: Hive 存储初始化失败

**症状**: 应用启动时闪退,日志显示 "HiveError"

**原因**: iOS 沙盒权限或存储路径问题

**解决方法**:
1. 卸载应用重新安装
2. 清理构建缓存:
```bash
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

### 问题 3: Flutter Secure Storage 权限问题

**症状**: 首次启动闪退

**原因**: Keychain 访问权限未配置

**解决方法**:
检查 `ios/Runner/Runner.entitlements` 是否包含:
```xml
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)com.aichat.app</string>
</array>
```

### 问题 4: 代码签名问题

**症状**: 安装到真机后闪退

**解决方法**:
1. 在 Xcode 中检查 Signing & Capabilities
2. 确保选择了正确的 Development Team
3. 确保 Bundle ID 唯一且已配置

## 3. 应用已添加的错误处理

### 全局错误捕获

`lib/main.dart` 使用 `runZonedGuarded` 捕获未处理的异常:
```dart
runZonedGuarded(() async {
  // 应用初始化
}, (error, stack) {
  debugPrint('应用错误: $error');
});
```

### 存储初始化容错

`lib/core/storage/storage_service.dart` 添加了 try-catch:
```dart
try {
  await Hive.initFlutter();
  // ...
} catch (e) {
  print('存储初始化失败: $e');
}
```

### 设置加载容错

`lib/core/providers/providers.dart` 的 `AppSettingsNotifier`:
```dart
try {
  return settingsRepo.getSettings();
} catch (e) {
  return const AppSettings(); // 返回默认设置
}
```

### 背景图片加载容错

`lib/shared/widgets/background_container.dart` 添加了详细的错误日志。

## 4. 调试技巧

### 使用 Xcode Console

1. 打开 Xcode
2. Window → Devices and Simulators
3. 选择你的设备
4. 查看 Device Logs
5. 搜索 "flutter" 或 "Runner" 查看应用日志

### 使用 Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

然后在应用运行时访问 DevTools 查看详细日志。

### 启用 Verbose 日志

```bash
flutter run -d <device> -v
```

## 5. 常用命令

```bash
# 清理并重新构建
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run -d <device>

# 查看设备列表
flutter devices

# 构建 iOS (不签名)
flutter build ios --debug --no-codesign

# 在真机上运行
flutter run -d 00008110-000C24813446801E
```

## 6. 如果问题仍未解决

1. 检查 iOS 系统版本是否兼容 (最低 iOS 12.0)
2. 检查 Xcode 版本是否最新
3. 检查 Flutter 版本: `flutter doctor`
4. 查看 GitHub Issues 是否有类似问题
5. 提供完整的错误日志和堆栈信息

## 7. 已知的兼容性问题

- **flutter_secure_storage**: iOS 需要 Keychain 权限
- **hive**: iOS 沙盒路径限制
- **window_manager**: 仅支持 desktop 平台
- **tray_manager**: 仅支持 desktop 平台

应用已针对这些问题添加了平台检测和容错处理。
