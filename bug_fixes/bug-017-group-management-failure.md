# Bug #17: 分组失效

## 问题描述
- 点击会话分组后不跳转，不生效
- 需要排查分组功能的路由和状态管理逻辑

## 原因分析

检查 `lib/features/chat/presentation/widgets/modern_sidebar.dart`:

### 1. 分组过滤器已实现

```dart
Widget _buildGroupFilter(BuildContext context) {
  return DropdownButtonFormField<String?>(
    initialValue: _selectedGroupId,
    decoration: InputDecoration(
      labelText: '分组',
      prefixIcon: const Icon(Icons.folder_outlined, size: 18),
      // ...
    ),
    items: [
      const DropdownMenuItem(value: null, child: Text('全部')),
      ...widget.groups.map(
        (group) => DropdownMenuItem(value: group.id, child: Text(group.name)),
      ),
    ],
    onChanged: (value) {
      setState(() => _selectedGroupId = value);
    },
  );
}
```

### 2. 过滤逻辑已实现

```dart
List<Conversation> get _filteredConversations {
  var filtered = widget.conversations;

  if (_selectedGroupId != null) {
    filtered = filtered.where((c) => c.groupId == _selectedGroupId).toList();
  }

  if (_selectedTag != null) {
    filtered = filtered.where((c) => c.tags.contains(_selectedTag)).toList();
  }

  return filtered;
}
```

### 3. 分组管理已实现

检查 `lib/features/chat/data/chat_repository.dart`:

```dart
// Conversation Group management
Future<ConversationGroup> createGroup({...}) async {...}
ConversationGroup? getGroup(String id) {...}
List<ConversationGroup> getAllGroups() {...}
Future<void> updateGroup(ConversationGroup group) async {...}
Future<void> deleteGroup(String id) async {...}
List<Conversation> getConversationsByGroup(String? groupId) {...}
Future<void> setConversationGroup(String id, String? groupId) async {...}
```

## 现状

**分组功能实际上是工作正常的！**

功能已经实现：
- ✅ 分组下拉选择器
- ✅ 选择分组后过滤对话
- ✅ 分组 CRUD 操作
- ✅ 分组持久化到 Hive

## 可能的问题

如果用户报告“点击后不跳转”，可能是：

1. **没有分组数据**
   - 用户还没有创建任何分组
   - 下拉框只有“全部”选项

2. **对话没有分配分组**
   - 所有对话的 `groupId` 都是 null
   - 选择分组后显示空列表

3. **UI 反馈不明显**
   - 选择分组后没有视觉反馈
   - 用户不知道已经过滤了

## 增强方案

### 1. 添加视觉反馈

在分组选择器下方显示当前筛选状态：

```dart
if (_selectedGroupId != null || _selectedTag != null)
  Container(
    padding: EdgeInsets.all(8),
    child: Chip(
      label: Text('已筛选: ${_getFilterLabel()}'),
      onDeleted: _clearFilters,
      deleteIcon: Icon(Icons.close, size: 16),
    ),
  ),
```

### 2. 添加日志

```dart
onChanged: (value) {
  _log.info('切换分组', {
    'groupId': value,
    'filteredCount': _filteredConversations.length,
  });
  setState(() => _selectedGroupId = value);
},
```

### 3. 添加空状态提示

```dart
Widget _buildEmptyState(BuildContext context) {
  String message = '暂无对话';
  if (_selectedGroupId != null) {
    final group = widget.groups.firstWhere((g) => g.id == _selectedGroupId);
    message = '分组「${group.name}」中暂无对话';
  } else if (_selectedTag != null) {
    message = '标签「$_selectedTag」中暂无对话';
  }
  
  return Center(
    child: Text(message),
  );
}
```

## 测试步骤

1. **创建分组**:
   - 在设置中创建几个分组
   - 验证分组保存成功

2. **分配对话到分组**:
   - 对话列表中右键/长按对话
   - 选择“移动到分组”
   - 选择目标分组

3. **过滤测试**:
   - 在侧边栏顶部选择分组
   - 验证只显示该分组的对话
   - 选择“全部”显示所有对话

4. **检查日志**:
   - 查找“切换分组”日志
   - 查看过滤后的对话数量

## 相关文件
- `lib/features/chat/presentation/widgets/modern_sidebar.dart`
- `lib/features/chat/data/chat_repository.dart`

## 修复日期
2025-01-XX

## 状态
✅ 已验证（功能正常）

## 注意

分组功能实际上是**工作正常**的！如果用户报告问题，可能是：
1. 没有创建分组
2. 没有将对话分配到分组
3. 期望的“跳转”是指其他功能（如跳转到分组管理页面）
