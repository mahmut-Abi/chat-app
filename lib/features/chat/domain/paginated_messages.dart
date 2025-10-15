import 'message.dart';

/// 分页消息状态
class PaginatedMessages {
  final List<Message> messages;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;

  const PaginatedMessages({
    required this.messages,
    this.currentPage = 0,
    this.pageSize = 50,
    this.hasMore = true,
    this.isLoading = false,
  });

  PaginatedMessages copyWith({
    List<Message>? messages,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
  }) {
    return PaginatedMessages(
      messages: messages ?? this.messages,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// 获取当前页的消息
  List<Message> getPagedMessages(List<Message> allMessages) {
    final startIndex = currentPage * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= allMessages.length) {
      return [];
    }

    return allMessages.sublist(
      startIndex,
      endIndex > allMessages.length ? allMessages.length : endIndex,
    );
  }

  /// 检查是否还有更多消息
  bool checkHasMore(List<Message> allMessages) {
    final nextStartIndex = (currentPage + 1) * pageSize;
    return nextStartIndex < allMessages.length;
  }
}
