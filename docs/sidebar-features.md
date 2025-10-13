# 侧边栏功能入口

## 概述

在 `EnhancedSidebar` 组件的底部添加了所有功能模块的快捷入口，使用网格布局展示。

## 功能入口

### 1. 模型管理 (`/models`)
- **图标**: `Icons.memory`
- **描述**: 管理和配置 AI 模型
- **功能**: 查看可用模型、配置模型参数

### 2. 提示词模板 (`/prompts`)
- **图标**: `Icons.lightbulb`
- **描述**: 管理提示词模板
- **功能**: 创建、编辑、删除提示词模板，快速使用预设提示词

### 3. AI 智能体 (`/agent`)
- **图标**: `Icons.smart_toy`
- **描述**: AI Agent 功能
- **功能**: 配置和使用 AI 智能体

### 4. MCP 服务 (`/mcp`)
- **图标**: `Icons.extension`
- **描述**: Model Context Protocol 服务
- **功能**: 管理和配置 MCP 服务

### 5. Token 使用统计 (`/token-usage`)
- **图标**: `Icons.access_time`
- **描述**: Token 使用情况统计
- **功能**: 查看 Token 使用历史和统计信息

### 6. 设置 (`/settings`)
- **图标**: `Icons.settings`
- **描述**: 应用设置
- **功能**: 主题、字体、背景、API 配置等

## UI 设计

### 布局
- 使用 3 列网格布局
- 每个功能卡片包含图标和标签
- 卡片采用圆角设计，支持点击水波纹效果

### 样式
- 图标大小: 24px
- 标签字体: 11px
- 卡片间距: 4px
- 卡片宽高比: 1.2

## 代码结构

### 路由配置 (`lib/core/routing/app_router.dart`)
```dart
GoRoute(path: '/models', builder: (context, state) => const ModelsScreen()),
GoRoute(path: '/prompts', builder: (context, state) => const PromptsScreen()),
GoRoute(path: '/agent', builder: (context, state) => const AgentScreen()),
GoRoute(path: '/mcp', builder: (context, state) => const McpScreen()),
GoRoute(path: '/token-usage', builder: (context, state) => const TokenUsageScreen()),
GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
```

### 侧边栏组件 (`lib/features/chat/presentation/widgets/enhanced_sidebar.dart`)

**功能卡片组件**:
```dart
Widget _buildFeatureCard({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    ),
  );
}
```

**功能网格**:
```dart
GridView.count(
  crossAxisCount: 3,
  children: [
    _buildFeatureCard(icon: Icons.memory, label: '模型', onTap: () => context.push('/models')),
    _buildFeatureCard(icon: Icons.lightbulb, label: '提示词', onTap: () => context.push('/prompts')),
    // ... 其他功能卡片
  ],
)
```

## 使用方式

1. **桌面端**: 侧边栏始终可见，直接点击底部的功能卡片
2. **移动端**: 
   - 点击左上角菜单按钮打开侧边栏
   - 或从左边缘向右滑动打开侧边栏
   - 点击功能卡片后自动关闭侧边栏

## 扩展性

如需添加新功能入口:

1. 在 `app_router.dart` 中添加路由
2. 在 `_buildFooter()` 的 `GridView.count` 中添加新的 `_buildFeatureCard()`
3. 考虑调整 `crossAxisCount` 以保持布局美观

## 注意事项

- 所有功能入口使用 `context.push()` 进行导航
- 卡片数量应为 3 的倍数以保持网格对齐
- 标签文字应简短，避免溢出
- 图标应具有代表性，便于用户识别
