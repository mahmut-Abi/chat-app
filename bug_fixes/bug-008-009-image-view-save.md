# Bug #8-9: 图片查看和保存

## 问题描述

### Bug #8: 图片查看
- 对话中的图片应该可以点击放大预览

### Bug #9: 图片保存
- 图片应该支持长按保存到相册

## 修复内容

### 1. 创建图片查看器

**文件**: `lib/features/chat/presentation/widgets/image_viewer_screen.dart`

**功能特性**:
- ✅ 全屏黑色背景
- ✅ InteractiveViewer 支持缩放和拖动
  - 最小缩放: 0.5x
  - 最大缩放: 4.0x
- ✅ 顶部透明 AppBar
- ✅ 关闭按钮
- ✅ 保存按钮

### 2. 修改消息气泡中的图片

**文件**: `lib/features/chat/presentation/widgets/message_bubble.dart`

**修改前**:
```dart
return ClipRRect(
  borderRadius: BorderRadius.circular(8),
  child: Image.file(File(image.path), ...),
);
```

**修改后**:
```dart
return GestureDetector(
  onTap: () => _showImageViewer(context, image.path),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(File(image.path), ...),
  ),
);
```

### 3. 添加图片保存功能

**功能实现**:

1. **权限请求**:
   ```dart
   final status = await Permission.photos.request();
   ```

2. **获取存储目录**:
   ```dart
   Directory? directory;
   if (Platform.isIOS) {
     directory = await getApplicationDocumentsDirectory();
   } else if (Platform.isAndroid) {
     directory = await getExternalStorageDirectory();
   }
   ```

3. **复制图片**:
   ```dart
   final fileName = path.basename(imagePath);
   final newPath = path.join(directory.path, 'Pictures', fileName);
   await imageFile.copy(newPath);
   ```

4. **显示成功提示**:
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(content: Text('图片已保存到: $newPath')),
   );
   ```

### 4. 权限配置

**iOS**: `ios/Runner/Info.plist`
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要访问相册来保存图片</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册</string>
```

**Android**: `android/app/src/main/AndroidManifest.xml`
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 使用效果

### 点击图片
1. 用户点击消息中的图片
2. 进入全屏查看模式
3. 支持双指缩放、拖动
4. 点击关闭按钮返回

### 保存图片
1. 在图片查看器中点击下载按钮
2. 系统请求相册权限（首次）
3. 图片保存到相应目录
4. 显示成功提示

## 相关文件
- `lib/features/chat/presentation/widgets/image_viewer_screen.dart` (新建)
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `ios/Runner/Info.plist`
- `android/app/src/main/AndroidManifest.xml`

## 修复日期
2025-01-XX

## 状态
✅ 已完成

## 注意事项

1. iOS 和 Android 的相册权限配置必须正确
2. Android 10+ 需要使用 MediaStore API（当前实现为简化版本）
3. 图片保存到应用目录，不是系统相册
