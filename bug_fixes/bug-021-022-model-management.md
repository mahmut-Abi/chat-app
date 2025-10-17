# Bug #21-22: 模型管理刷新和详细信息

## 问题描述

### Bug #21: 模型管理刷新按钮
- 设置 - 模型管理中需要添加刷新按钮
- 支持手动刷新可用模型列表

### Bug #22: 模型详细信息
- 模型管理需要提供模型详细信息展示
- 包括：上下文长度、支持的功能（工具调用、视觉等）、定价等

## 现状分析

### Bug #21 已实现 ✅

检查 `lib/features/models/presentation/models_screen.dart`:

```dart
appBar: AppBar(
  title: const Text('模型管理'),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: (_isLoading || _isRefreshing) ? null : _refreshModels,
      tooltip: '刷新',
    ),
  ],
),
```

**功能已存在**:
- ✅ 有刷新按钮
- ✅ 点击后调用 `_refreshModels()` 方法
- ✅ 加载中禁用按钮
- ✅ 有加载提示
- ✅ 刷新成功后显示 SnackBar

### Bug #22 需要增强 ⏳

目前模型列表显示信息较少，需要增加：
1. 模型详细信息对话框
2. 显示上下文长度
3. 显示支持的功能
4. 显示定价信息

## 修复方案

### 1. 扩展模型数据结构

**文件**: `lib/features/models/domain/model.dart`

需要添加的字段:
```dart
@JsonSerializable()
class AiModel {
  final String id;
  final String name;
  // ...
  
  // 新增字段
  final int? contextLength;       // 上下文长度
  final bool? supportsVision;     // 支持视觉输入
  final bool? supportsFunctions;  // 支持函数调用
  final String? pricing;          // 定价信息
  final String? description;      // 模型描述
}
```

### 2. 添加模型详情对话框

**文件**: `lib/features/models/presentation/models_screen.dart`

```dart
void _showModelDetails(BuildContext context, AiModel model) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(model.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (model.description != null) ...[
              Text(model.description!),
              const SizedBox(height: 16),
            ],
            _buildInfoRow('模型 ID', model.id),
            if (model.contextLength != null)
              _buildInfoRow('上下文长度', '${model.contextLength} tokens'),
            if (model.supportsVision != null)
              _buildInfoRow('视觉支持', model.supportsVision! ? '支持' : '不支持'),
            if (model.supportsFunctions != null)
              _buildInfoRow('函数调用', model.supportsFunctions! ? '支持' : '不支持'),
            if (model.pricing != null) ...[
              const SizedBox(height: 8),
              const Text('定价信息', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(model.pricing!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label：',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
```

### 3. 修改模型列表项

在模型列表项上添加点击事件，显示详情：

```dart
ListTile(
  title: Text(model.name),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('ID: ${model.id}'),
      if (model.contextLength != null)
        Text('上下文: ${model.contextLength} tokens'),
    ],
  ),
  trailing: const Icon(Icons.info_outline),
  onTap: () => _showModelDetails(context, model),  // 点击显示详情
)
```

## 目前状态

### Bug #21 ✅
刷新按钮已存在并且功能正常！

### Bug #22 ⏳
需要增强模型详情显示功能，但需要：
1. 扩展 AiModel 数据结构
2. API 响应中包含这些信息
3. 创建详情对话框 UI

## 相关文件
- `lib/features/models/presentation/models_screen.dart`
- `lib/features/models/domain/model.dart`
- `lib/features/models/data/models_repository.dart`

## 修复日期
2025-01-XX

## 状态
- Bug #21: ✅ 已存在
- Bug #22: ⏳ 待增强
