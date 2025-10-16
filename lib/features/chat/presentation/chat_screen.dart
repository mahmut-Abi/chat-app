import 'package:flutter/material.dart';
import '../../../shared/widgets/platform_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/background_container.dart';
import 'widgets/enhanced_sidebar.dart';
import 'package:go_router/go_router.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_input_section.dart';
import '../../../features/agent/domain/agent_tool.dart';
import '../../../features/mcp/domain/mcp_config.dart';
import '../../../features/models/domain/model.dart';

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
  final ModelConfig _currentConfig = const ModelConfig(model: 'gpt-3.5-turbo');
  List<File> _selectedImages = [];
  List<File> _selectedFiles = [];
  AgentConfig? _selectedAgent;
  McpConfig? _selectedMcp;
  AiModel? _selectedModel;
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
    // Token 统计已移至 token_usage 功能模块
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
        // 如果对话不存在，说明这是一个临时对话，需要创建并保存
        if (kDebugMode) {
          print('ChatScreen: 对话不存在，创建新对话');
        }
        conversation = Conversation(
          id: widget.conversationId,
          title: '新建对话',
          messages: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isTemporary: false, // 已经有消息，不再是临时对话
        );
      }

      // 更新对话消息列表并保存（会自动将 isTemporary 设为 false）
      await chatRepo.saveConversation(
        conversation.copyWith(messages: _messages, updatedAt: DateTime.now()),
      );

      // 刷新侧边栏对话列表（如果这是第一条消息，现在会显示在侧边栏）
      _loadAllConversations();

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
          messages: const [],
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
        messages: const [],
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
        messages: const [],
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
      child: GestureDetector(
        onTap: () {
          // 点击空白区域隐藏键盘
          FocusScope.of(context).unfocus();
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
                        if (mounted && context.mounted) {
                          context.go('/chat/${conversation.id}');
                        }
                      },
                      onDeleteConversation: (id) async {
                        final chatRepo = ref.read(chatRepositoryProvider);
                        await chatRepo.deleteConversation(id);
                        _loadAllConversations();
                        if (id == widget.conversationId) {
                          if (mounted && context.mounted) {
                            context.go('/');
                          }
                        }
                      },
                      onRenameConversation: (conversation) async {
                        final result = await showPlatformInputDialog(
                          context: context,
                          title: '重命名对话',
                          initialValue: conversation.title,
                          placeholder: '对话标题',
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
                      child: ChatMessageList(
                        messages: _messages,
                        scrollController: _scrollController,
                        isMobile: isMobile,
                        onDeleteMessage: _deleteMessage,
                        onRegenerateMessage: _regenerateMessage,
                        onEditMessage: _editMessage,
                      ),
                    ),
                    ChatInputSection(
                      messageController: _messageController,
                      selectedImages: _selectedImages,
                      selectedFiles: _selectedFiles,
                      isLoading: _isLoading,
                      onSend: _sendMessage,
                      onImagesSelected: (images) {
                        setState(() {
                          _selectedImages = images;
                        });
                      },
                      onFilesSelected: (files) {
                        setState(() {
                          _selectedFiles = files;
                        });
                      },
                      selectedAgent: _selectedAgent,
                      selectedMcp: _selectedMcp,
                      selectedModel: _selectedModel,
                      onAgentSelected: (agent) {
                        setState(() {
                          _selectedAgent = agent;
                        });
                      },
                      onMcpSelected: (mcp) {
                        setState(() {
                          _selectedMcp = mcp;
                        });
                      },
                      onModelSelected: (model) {
                        setState(() {
                          _selectedModel = model;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
