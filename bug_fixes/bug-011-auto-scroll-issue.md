# Bug #11: 自动滚动问题

## 问题描述
- 大模型回答时，界面会自动滚动到最新内容
- **需求**：回答过程中不要自动滚动，让用户可以查看之前的对话
- 建议：添加「滚动到底部」悬浮按钮，用户可以手动点击

## 原因分析

检查 `lib/features/chat/presentation/chat_screen.dart`:

当前代码在多个地方调用了 `_scrollToBottom()`:
1. `_sendMessage()` 发送消息后
2. `_handleStreamResponse()` 流式响应时
3. 消息更新时

这导致用户在查看历史消息时被强制滚动到底部。

## 修复方案

### 1. 添加用户滚动状态追踪

追踪用户是否手动滚动到了历史消息位置：

```dart
bool _userScrolledUp = false;
bool _showScrollToBottomButton = false;

void _initScrollListener() {
  _scrollController.addListener(() {
    final isAtBottom = _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100;
    
    setState(() {
      _userScrolledUp = !isAtBottom;
      _showScrollToBottomButton = _userScrolledUp;
    });
  });
}
```

### 2. 修改自动滚动逻辑

只在用户没有手动滚动时才自动滚动：

```dart
void _scrollToBottom({bool force = false}) {
  if (!force && _userScrolledUp) {
    // 用户手动滚动到历史消息，不自动滚动
    return;
  }
  
  if (_scrollController.hasClients) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        setState(() {
          _userScrolledUp = false;
          _showScrollToBottomButton = false;
        });
      }
    });
  }
}
```

### 3. 添加滚动到底部按钮

在界面右下角添加悬浮按钮：

```dart
Widget build(BuildContext context) {
  return Scaffold(
    // ... 其他代码
    body: Stack(
      children: [
        // 原有的消息列表
        Column(
          children: [
            Expanded(
              child: ChatMessageList(
                messages: _messages,
                scrollController: _scrollController,
              ),
            ),
            ChatInputSection(
              // ...
            ),
          ],
        ),
        
        // 滚动到底部按钮
        if (_showScrollToBottomButton)
          Positioned(
            right: 16,
            bottom: 80,
            child: FloatingActionButton.small(
              onPressed: () => _scrollToBottom(force: true),
              child: const Icon(Icons.arrow_downward),
              tooltip: '滚动到底部',
            ),
          ),
      ],
    ),
  );
}
```

### 4. 更新流式响应逻辑

在流式响应时，只有用户在底部才自动滚动：

```dart
void _handleStreamResponse(Stream<String> stream) {
  // ...
  
  stream.listen(
    (chunk) {
      setState(() {
        // 更新消息
      });
      
      // 只在用户在底部时自动滚动
      _scrollToBottom();
    },
  );
}
```

## 实现代码

完整的修改如下：


## 实际实现

### 1. 添加状态变量

```dart
bool _userScrolledUp = false;
bool _showScrollToBottomButton = false;
```

### 2. 初始化滚动监听器

```dart
void _initScrollListener() {
  _scrollController.addListener(() {
    if (!_scrollController.hasClients) return;
    
    final isAtBottom = _scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100;
    
    if (_userScrolledUp != !isAtBottom || _showScrollToBottomButton != !isAtBottom) {
      setState(() {
        _userScrolledUp = !isAtBottom;
        _showScrollToBottomButton = !isAtBottom && _messages.isNotEmpty;
      });
    }
  });
}
```

### 3. 修改滚动方法

```dart
void _scrollToBottom({bool force = false}) {
  // 如果用户手动滚动到历史消息，不自动滚动
  if (!force && _userScrolledUp) {
    return;
  }
  
  if (_scrollController.hasClients) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        if (mounted) {
          setState(() {
            _userScrolledUp = false;
            _showScrollToBottomButton = false;
          });
        }
      }
    });
  }
}
```

### 4. 添加 UI 按钮

```dart
body: Stack(
  children: [
    Column(
      children: [
        // 消息列表
        Expanded(
          child: ChatMessageList(...),
        ),
        // 输入框
        ChatInputSection(...),
      ],
    ),
    // 滚动到底部按钮
    if (_showScrollToBottomButton)
      Positioned(
        right: 16,
        bottom: 80,
        child: FloatingActionButton.small(
          onPressed: () => _scrollToBottom(force: true),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.arrow_downward),
          tooltip: '滚动到底部',
        ),
      ),
  ],
),
```

## 测试验证

1. **基本功能**:
   - [x] 发送消息后自动滚动到底部
   - [x] 大模型回复时，如果用户在底部则自动滚动
   - [x] 如果用户滚动到历史消息，不自动滚动

2. **悬浮按钮**:
   - [x] 用户不在底部时显示按钮
   - [x] 点击按钮后滚动到底部
   - [x] 滚动到底部后隐藏按钮

3. **边界条件**:
   - [x] 没有消息时不显示按钮
   - [x] 快速滚动时按钮状态正确更新
   - [x] 流式响应时逻辑正确

## 相关文件
- `lib/features/chat/presentation/chat_screen.dart`

## 修复日期
2025-01-XX

## 状态
✅ 已完成

## 用户体验改进

修复后的体验：
1. 用户可以自由查看历史消息，不会被强制滚动
2. 当用户想要回到底部时，只需点击悬浮按钮
3. 当用户在底部时，新消息仍然会自动显示
