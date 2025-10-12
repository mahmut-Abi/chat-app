import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'package:uuid/uuid.dart';
import 'widgets/model_config_dialog.dart';
import 'widgets/message_bubble.dart';
import '../../../core/utils/token_counter.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  final _uuid = const Uuid();
  ModelConfig _currentConfig = const ModelConfig(model: 'gpt-3.5-turbo');
  int _totalTokens = 0;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    Future.microtask(() => _calculateTokens());
  }

  void _loadConversation() {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation != null) {
      setState(() {
        _messages.addAll(conversation.messages);
      });

  void _calculateTokens() {
    int total = 0;
    for (final message in _messages) {
      if (message.tokenCount != null) {
        total += message.tokenCount!;
      } else {
        total += TokenCounter.estimate(message.content);
      }
    }
    if (mounted) {
      setState(() {
        _totalTokens = total;
      });
    }
  }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _showModelConfigDialog() async {
    final config = await showDialog<ModelConfig>(
      context: context,
      builder: (context) => ModelConfigDialog(initialConfig: _currentConfig),
    );

    if (config != null) {
      setState(() {
        _currentConfig = config;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('模型已切换为: ${config.model}')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final assistantMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    final chatRepo = ref.read(chatRepositoryProvider);

    try {
      final stream = chatRepo.sendMessageStream(
        conversationId: widget.conversationId,
        content: userMessage.content,
        config: _currentConfig,
        conversationHistory: _messages.where((m) => !m.isStreaming).toList(),
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent += chunk;
        setState(() {
          final index =
              _messages.indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _messages[index] = assistantMessage.copyWith(
              content: fullContent,
            );
          }
        });
        _scrollToBottom();
      }

      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isStreaming: false,
          );
        }
        _isLoading = false;
      });

      final conversation = chatRepo.getConversation(widget.conversationId);
      if (conversation != null) {
        await chatRepo.saveConversation(
          conversation.copyWith(
            messages: _messages,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = assistantMessage.copyWith(
            content: '错误: ${e.toString()}',
            hasError: true,
            isStreaming: false,
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _regenerateMessage(int messageIndex) async {
    if (messageIndex < 1) return;

    final userMessage = _messages[messageIndex - 1];
    if (userMessage.role != MessageRole.user) return;

    setState(() {
      _messages.removeAt(messageIndex);
      _isLoading = true;
    });

    final assistantMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.insert(messageIndex, assistantMessage);
    });

    final chatRepo = ref.read(chatRepositoryProvider);

    try {
      final history = _messages
          .sublist(0, messageIndex)
          .where((m) => !m.isStreaming)
          .toList();
      final stream = chatRepo.sendMessageStream(
        conversationId: widget.conversationId,
        content: userMessage.content,
        config: _currentConfig,
        conversationHistory: history,
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent += chunk;
        setState(() {
          final index =
              _messages.indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _messages[index] = assistantMessage.copyWith(content: fullContent);
          }
        });
        _scrollToBottom();
      }

      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        }
        _isLoading = false;
      });

      final conversation = chatRepo.getConversation(widget.conversationId);
      if (conversation != null) {
        await chatRepo.saveConversation(
          conversation.copyWith(
            messages: _messages,
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = assistantMessage.copyWith(
            content: '错误: ${e.toString()}',
            hasError: true,
            isStreaming: false,
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMessage(int messageIndex) async {
    setState(() {
      _messages.removeAt(messageIndex);
    });

    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation != null) {
      await chatRepo.saveConversation(
        conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
      );
    }
  }

  Future<void> _editMessage(int messageIndex, String newContent) async {
    if (newContent.trim().isEmpty) return;

    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        content: newContent,
      );
    });

    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation != null) {
      await chatRepo.saveConversation(
        conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: '模型配置',
            onPressed: _showModelConfigDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '开始新对话',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '输入消息开始与 AI 交流',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(
                        message: message,
                        onDelete: () => _deleteMessage(index),
                        onRegenerate: message.role == MessageRole.assistant
                            ? () => _regenerateMessage(index)
                            : null,
                        onEdit: (newContent) => _editMessage(index, newContent),
                      );
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            onPressed: _isLoading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

