# Bug #29: Token 统计持久化

## 问题描述
- Token 统计只需要统计全局总消耗量即可
- 不需要对每次对话单独统计
- Token 统计数据需要持久化到 Hive
- 确保统计数据在应用重启后仍然保留

## 修复方案

### 1. 创建 Token 统计数据模型

```dart
@JsonSerializable()
class TokenUsageStats {
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final int totalTokens;
  final DateTime lastUpdated;
  
  const TokenUsageStats({
    this.totalPromptTokens = 0,
    this.totalCompletionTokens = 0,
    this.totalTokens = 0,
    required this.lastUpdated,
  });
  
  factory TokenUsageStats.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageStatsFromJson(json);
  
  Map<String, dynamic> toJson() => _$TokenUsageStatsToJson(this);
  
  TokenUsageStats addUsage({
    required int promptTokens,
    required int completionTokens,
  }) {
    return TokenUsageStats(
      totalPromptTokens: totalPromptTokens + promptTokens,
      totalCompletionTokens: totalCompletionTokens + completionTokens,
      totalTokens: totalTokens + promptTokens + completionTokens,
      lastUpdated: DateTime.now(),
    );
  }
}
```

### 2. 持久化逻辑

在 `StorageService` 中添加：

```dart
class StorageService {
  // ...
  
  Future<void> saveTokenUsageStats(TokenUsageStats stats) async {
    await _settingsBoxInstance.put('token_usage_stats', jsonEncode(stats.toJson()));
  }
  
  Future<TokenUsageStats> getTokenUsageStats() async {
    final data = _settingsBoxInstance.get('token_usage_stats');
    if (data == null) {
      return TokenUsageStats(lastUpdated: DateTime.now());
    }
    return TokenUsageStats.fromJson(jsonDecode(data as String));
  }
  
  Future<void> resetTokenUsageStats() async {
    await _settingsBoxInstance.delete('token_usage_stats');
  }
}
```

### 3. Provider 实现

```dart
final tokenUsageStatsProvider = StateNotifierProvider<TokenUsageNotifier, TokenUsageStats>((ref) {
  return TokenUsageNotifier(ref.read(storageServiceProvider));
});

class TokenUsageNotifier extends StateNotifier<TokenUsageStats> {
  final StorageService _storage;
  
  TokenUsageNotifier(this._storage) : super(TokenUsageStats(lastUpdated: DateTime.now())) {
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    state = await _storage.getTokenUsageStats();
  }
  
  Future<void> addUsage({
    required int promptTokens,
    required int completionTokens,
  }) async {
    state = state.addUsage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
    );
    await _storage.saveTokenUsageStats(state);
  }
  
  Future<void> reset() async {
    state = TokenUsageStats(lastUpdated: DateTime.now());
    await _storage.resetTokenUsageStats();
  }
}
```

### 4. 在 API 响应中记录 Token 使用

在 `ChatRepository` 中，每次 API 响应后记录 token 使用：

```dart
Future<void> _sendMessage() async {
  // ...
  
  final response = await apiClient.sendMessage(...);
  
  // 记录 token 使用
  if (response.usage != null) {
    await ref.read(tokenUsageStatsProvider.notifier).addUsage(
      promptTokens: response.usage!.promptTokens,
      completionTokens: response.usage!.completionTokens,
    );
  }
}
```

### 5. UI 显示

在 Token Usage Screen 中显示总统计：

```dart
class TokenUsageScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(tokenUsageStatsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token 使用统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tokenUsageStatsProvider.notifier).reset();
            },
            tooltip: '重置统计',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            context,
            '总 Token 数',
            stats.totalTokens.toString(),
            Icons.token,
          ),
          _buildStatCard(
            context,
            '输入 Token',
            stats.totalPromptTokens.toString(),
            Icons.input,
          ),
          _buildStatCard(
            context,
            '输出 Token',
            stats.totalCompletionTokens.toString(),
            Icons.output,
          ),
          _buildStatCard(
            context,
            '最后更新',
            _formatDate(stats.lastUpdated),
            Icons.update,
          ),
        ],
      ),
    );
  }
}
```

## 测试验证

- [ ] 创建数据模型
- [ ] 实现持久化逻辑
- [ ] 创建 Provider
- [ ] 在 API 响应中记录
- [ ] 更新 UI 显示
- [ ] 测试数据持久化
- [ ] 测试重置功能

## 状态
⏳ 待实现

## 相关文件
- `lib/features/token_usage/domain/token_usage_stats.dart` (需要创建)
- `lib/core/storage/storage_service.dart`
- `lib/core/providers/providers.dart`
- `lib/features/token_usage/presentation/token_usage_screen.dart`
- `lib/features/chat/data/chat_repository.dart`
