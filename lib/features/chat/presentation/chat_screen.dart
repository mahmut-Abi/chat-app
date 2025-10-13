import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'package:uuid/uuid.dart';
import 'widgets/message_bubble.dart';
import '../../../core/utils/token_counter.dart';
import 'widgets/image_picker_widget.dart';
import 'dart:io';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/background_container.dart';
import 'widgets/enhanced_sidebar.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/glass_container.dart';

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
  List<File> _selectedImages = [];
  List<Conversation> _conversations = [];
  List<ConversationGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadAllConversations();
    Future.microtask(() => _calculateTokens());
  }

  void _loadAllConversations() {
    final chatRepo = ref.read(chatRepositoryProvider);
    setState(() {
      _conversations = chatRepo.getAllConversations();
      _groups = chatRepo.getAllGroups();
    });
  }

  void _loadConversation() {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = chatRepo.getConversation(widget.conversationId);
    if (kDebugMode) {
      print('ChatScreen._loadConversation:');
      print('  conversationId: ${widget.conversationId}');
      print('  conversation: ${conversation?.title}');
      print('  messages count: ${conversation?.messages.length ?? 0}');
      print('  current _messages count: ${_messages.length}');
    }
    if (conversation != null) {
      setState(() {
        _messages.clear(); // 清空旧消息避免累积
        _messages.addAll(conversation.messages);
      });
      if (kDebugMode) {
        print('  loaded _messages count: ${_messages.length}');
      }
    } else {
      if (kDebugMode) {
        print('  警告: 对话不存在!');
      }
    }
  }

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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    // 处理图片附件
    List<ImageAttachment>? imageAttachments;
    if (_selectedImages.isNotEmpty) {
      imageAttachments = [];
      for (final imageFile in _selectedImages) {
        try {
          final base64Data = await ImageUtils.imageToBase64(imageFile);
          final mimeType = ImageUtils.getImageMimeType(imageFile.path);
          imageAttachments.add(
            ImageAttachment(
              path: imageFile.path,
              base64Data: base64Data,
              mimeType: mimeType,
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('图片处理失败: $e')));
          }
        }
      }
    }

    final userMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
      images: imageAttachments,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _selectedImages = []; // 清空已选择的图片
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
          final index = _messages.indexWhere(
            (m) => m.id == assistantMessage.id,
          );
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

      // 获取对话并保存
      var conversation = chatRepo.getConversation(widget.conversationId);
      if (conversation == null) {
        // 如果对话不存在,创建一个新对话
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('错误: 对话不存在')));
        }
        conversation = Conversation(
          id: widget.conversationId,
          title: '未知对话',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 更新对话消息列表并保存
      await chatRepo.saveConversation(
        conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
      );

      _calculateTokens();
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
          final index = _messages.indexWhere(
            (m) => m.id == assistantMessage.id,
          );
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

      // 获取对话并保存
      var conversation = chatRepo.getConversation(widget.conversationId);
      if (conversation == null) {
        // 如果对话不存在,创建一个新对话
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('错误: 对话不存在(重新生成)')));
        }
        conversation = Conversation(
          id: widget.conversationId,
          title: '未知对话',
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 更新对话消息列表并保存
      await chatRepo.saveConversation(
        conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
      );
      _calculateTokens();
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

    // 获取对话并保存
    var conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('错误: 对话不存在(删除消息)')));
      }
      conversation = Conversation(
        id: widget.conversationId,
        title: '未知对话',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // 更新对话消息列表并保存
    await chatRepo.saveConversation(
      conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
    );
    _calculateTokens();
  }

  Future<void> _editMessage(int messageIndex, String newContent) async {
    if (newContent.trim().isEmpty) return;

    setState(() {
      _messages[messageIndex] = _messages[messageIndex].copyWith(
        content: newContent,
      );
    });

    final chatRepo = ref.read(chatRepositoryProvider);

    // 获取对话并保存
    var conversation = chatRepo.getConversation(widget.conversationId);
    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('错误: 对话不存在(编辑消息)')));
      }
      conversation = Conversation(
        id: widget.conversationId,
        title: '未知对话',
        messages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // 更新对话消息列表并保存
    await chatRepo.saveConversation(
      conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
    );
    _calculateTokens();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // 移动端：禁用右划手势返回，但保留 AppBar 返回按钮
    // 桌面端/设置页面：允许正常返回
    return PopScope(
      canPop: !isMobile,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // 移动端：canPop=false 会阻止右划手势，但 AppBar 返回按钮依然可用
      },
      child: BackgroundContainer(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: false,
          appBar: isMobile
              ? null
              : AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text('Chat'),
                ),
          drawer: isMobile
              ? Drawer(
                  backgroundColor: Theme.of(context).cardColor,
                  child: EnhancedSidebar(
                    conversations: _conversations,
                    groups: _groups,
                    selectedConversation: _conversations
                        .where((c) => c.id == widget.conversationId)
                        .firstOrNull,
                    onConversationSelected: (conversation) {
                      Navigator.of(context).pop();
                      context.go('/chat/${conversation.id}');
                    },
                    onCreateConversation: () async {
                      Navigator.of(context).pop();
                      final chatRepo = ref.read(chatRepositoryProvider);
                      final conversation = await chatRepo.createConversation(
                        title: '新建对话',
                      );
                      if (mounted) {
                        context.go('/chat/${conversation.id}');
                      }
                    },
                    onDeleteConversation: (id) async {
                      final chatRepo = ref.read(chatRepositoryProvider);
                      await chatRepo.deleteConversation(id);
                      _loadAllConversations();
                      if (id == widget.conversationId) {
                        if (mounted) {
                          context.go('/');
                        }
                      }
                    },
                    onRenameConversation: (conversation) async {
                      final controller = TextEditingController(
                        text: conversation.title,
                      );
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('重命名对话'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: '对话标题',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('取消'),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(controller.text),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );
                      if (result != null && result.isNotEmpty) {
                        final chatRepo = ref.read(chatRepositoryProvider);
                        final updated = conversation.copyWith(title: result);
                        await chatRepo.saveConversation(updated);
                        _loadAllConversations();
                      }
                    },
                    onUpdateTags: (conversation, tags) async {
                      final chatRepo = ref.read(chatRepositoryProvider);
                      final updated = conversation.copyWith(tags: tags);
                      await chatRepo.saveConversation(updated);
                      _loadAllConversations();
                    },
                    onManageGroups: () {
                      // 暂不处理
                    },
                    onSearch: () {
                      // 暂不处理
                    },
                  ),
                )
              : null,
          body: Stack(
            children: [
              Column(
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
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: isMobile ? 60 : 16,
                              bottom: 16,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return MessageBubble(
                                message: message,
                                onDelete: () => _deleteMessage(index),
                                onRegenerate:
                                    message.role == MessageRole.assistant
                                    ? () => _regenerateMessage(index)
                                    : null,
                                onEdit: (newContent) =>
                                    _editMessage(index, newContent),
                              );
                            },
                          ),
                  ),
                  _buildInputArea(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return GlassContainer(
      blur: 15.0,
      opacity: 0.15,
      padding: const EdgeInsets.all(16),
      border: Border(
        top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图片选择器
          if (_selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ImagePickerWidget(
                selectedImages: _selectedImages,
                onImagesSelected: (images) {
                  setState(() {
                    _selectedImages = images;
                  });
                },
              ),
            ),
          Row(
            children: [
              // 图片按钮
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: _selectedImages.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: '添加图片',
                onPressed: () async {
                  final images = await ImageUtils.pickImages();
                  if (images != null && images.isNotEmpty) {
                    setState(() {
                      _selectedImages.addAll(images);
                    });
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
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
