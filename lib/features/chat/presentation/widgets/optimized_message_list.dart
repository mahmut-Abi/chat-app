import 'package:flutter/material.dart';

/// 优化的消息列表 - 我妀1滚动和性能优化
class OptimizedMessageList extends StatefulWidget {
  final List<Widget> messages;
  final ScrollController? scrollController;
  
  const OptimizedMessageList({
    required this.messages,
    this.scrollController,
    Key? key,
  }) : super(key: key);
  
  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      cacheExtent: 500, // 预加载 500 像素
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: widget.messages[index],
        );
      },
    );
  }
}
