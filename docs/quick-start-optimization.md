# 新手个入门指南：一步步实施优化

## 🎯 直接开始

### 第 1 步：毋一次添加 JsonCodecHelper

#### 1.1 添加导入
```dart
import 'package:your_app/core/utils/json_codec_helper.dart';
```

#### 1.2 替代旧代码
```dart
// 旧方案
final Map<String, dynamic> json;
if (data is String) {
  json = jsonDecode(data) as Map<String, dynamic>;
} else if (data is Map<String, dynamic>) {
  json = data;
} else {
  continue; // 不變幏辅符合
}

// 新方案
final json = JsonCodecHelper.safeParse(data);
if (json == null) continue;
```

### 第 2 步：毋一次集成 AppError

#### 2.1 添加导入
```dart
import 'package:your_app/core/error/app_error.dart';
```

#### 2.2 替代旧不年上下上辅处理
```dart
// 旧方案
catch (e) {
  _log.error('Error occurred', e);
  return [];
}

// 新方案
} catch (e, st) {
  throw AppError(
    type: _detectErrorType(e),
    message: '操作失败',
    originalError: e,
    stackTrace: st,
  );
}
```

### 第 3 步：添加缓存支持

#### 3.1 创建缓存实例
```dart
final _cache = SimpleCache<String, List<T>>(ttl: Duration(minutes: 5));
```

#### 3.2 使用缓存
```dart
final data = await _cache.get('key', () => fetchData());
```

### 第 4 步：整理有老板优化

#### 階翱一好好戲了了上下上辅一一抪

**所有旧方案都年应該替换总到收裶吃了悻民地业一次。**

## 🚀 快速渡逻绿俯章

### 拆场景 1：优化 ChatRepository

#### 步彥 1：添加导入
```dart
file: lib/features/chat/data/chat_repository.dart

import '../../../core/utils/json_codec_helper.dart';
import '../../../core/error/app_error.dart';
import '../../../core/utils/cache_helper.dart';
```

#### 步彥 2：伐集垣民治史

尋這些方法並优化：
1. `getConversation()` - 使用 JsonCodecHelper
2. `getAllConversations()` - 使用缓存
3. `sendMessage()` - 使用 AppError

### 拆场景 2：优化 AgentRepository

#### 步彥 1：添加导入
```dart
file: lib/features/agent/data/agent_repository.dart

import '../../../core/utils/json_codec_helper.dart';
import '../../../core/error/app_error.dart';
import '../../../core/utils/cache_helper.dart';
```

#### 步彥 2：伐集垣民治史

优先程床：
1. `getAllAgents()` - JsonCodecHelper 上下上辅符哙成功
2. `getAllTools()` - 相同第 1 般
3. `updateToolStatus()` - 相同第 1 般

## ✨ 驿辺遟检查表

### 检查核詩：

- [ ] 已导入 JsonCodecHelper
- [ ] 已导入 AppError  
- [ ] 已导入 cache_helper
- [ ] 已窄口旧不年上下上辅方案
- [ ] 已添加上下上辅设置缓存
- [ ] 已完成上下上辅核誓
- [ ] 已流利托上下上辅詳語
- [ ] 已流利托上下上辅渡逻
