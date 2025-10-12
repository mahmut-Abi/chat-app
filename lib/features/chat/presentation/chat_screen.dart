import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'package:uuid/uuid.dart';
import '../../../shared/widgets/markdown_message.dart';

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

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  void _loadConversation() {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation != null) {
      setState(() {
        _messages.addAll(conversation.messages);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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

    // Create streaming assistant message
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
    const config = ModelConfig(model: 'gpt-3.5-turbo');

    try {
      final stream = chatRepo.sendMessageStream(
        conversationId: widget.conversationId,
        content: userMessage.content,
        config: config,
        conversationHistory: _messages
            .where((m) => !m.isStreaming)
            .toList(),
      );

      String fullContent = '';
      await for (final chunk in stream) {
        fullContent += chunk;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
          if (index != -1) {
            _messages[index] = assistantMessage.copyWith(
              content: fullContent,
            );
          }
        });
        _scrollToBottom();
      }

      // Mark as complete
      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isStreaming: false,
          );
        }
        _isLoading = false;
      });

      // Save conversation
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
            content: 'Error: ${e.toString()}',
            hasError: true,
            isStreaming: false,
          );
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return MessageBubble(message: message);
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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
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

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(context, isUser),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.hasError)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  else if (message.role == MessageRole.assistant)
                    MarkdownMessage(
                      content: message.content,
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    )
                  else
                    SelectableText(
                      message.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) _buildAvatar(context, isUser),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }
}
