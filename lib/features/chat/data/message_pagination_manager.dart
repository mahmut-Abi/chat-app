import '../domain/message.dart';

/// 消息分页管理器
///
/// 负责管理消息的分页加载，优化大量消息的内存占用和渲染性能。
class MessagePaginationManager {
  static const int defaultPageSize = 50;

  final int pageSize;
  int _currentPage = 0;
  List<Message> _displayedMessages = [];

  MessagePaginationManager({this.pageSize = defaultPageSize});

  /// 初始化分页，加载第一页消息
  List<Message> initialize(List<Message> allMessages) {
    _currentPage = 0;
    _displayedMessages = _loadPage(allMessages, 0);
    return _displayedMessages;
  }

  /// 加载更多消息（向上滚动加载历史消息）
  List<Message> loadMore(List<Message> allMessages) {
    if (!hasMore(allMessages)) {
      return _displayedMessages;
    }

    _currentPage++;
    final newMessages = _loadPage(allMessages, _currentPage);
    _displayedMessages = [...newMessages, ..._displayedMessages];
    return _displayedMessages;
  }

  /// 添加新消息（用于实时消息）
  List<Message> addMessage(Message message) {
    _displayedMessages = [..._displayedMessages, message];
    return _displayedMessages;
  }

  /// 检查是否还有更多消息
  bool hasMore(List<Message> allMessages) {
    final totalLoaded = (_currentPage + 1) * pageSize;
    return totalLoaded < allMessages.length;
  }

  /// 获取当前显示的消息列表
  List<Message> get displayedMessages => _displayedMessages;

  /// 重置分页状态
  void reset() {
    _currentPage = 0;
    _displayedMessages = [];
  }

  /// 加载指定页的消息
  List<Message> _loadPage(List<Message> allMessages, int page) {
    final startIndex = page * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= allMessages.length) {
      return [];
    }

    return allMessages.sublist(
      startIndex,
      endIndex > allMessages.length ? allMessages.length : endIndex,
    );
  }
}
