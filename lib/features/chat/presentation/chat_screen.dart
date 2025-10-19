import 'package:flutter/material.dart';
import '../../../shared/widgets/platform_dialog.dart';
import '../../../shared/widgets/page_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import '../domain/message.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/token_counter.dart';
import 'dart:io';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/image_upload_validator.dart';
import '../../../core/utils/platform_utils.dart';
import 'widgets/modern_sidebar.dart';
import 'package:go_router/go_router.dart';
import 'widgets/chat_message_list.dart';
import 'widgets/chat_input_section.dart';
import 'widgets/conversation_search_screen.dart';
import 'widgets/group_management_dialog.dart';
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
  final FocusNode _inputFocusNode = FocusNode();
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _userScrolledUp = false;
  bool _showScrollToBottomButton = false;
  final _uuid = const Uuid();
  List<File> _selectedImages = [];
  List<File> _selectedFiles = [];
  AgentConfig? _selectedAgent;
  McpConfig? _selectedMcp;
  AiModel? _selectedModel;
  List<Conversation> _conversations = [];
  List<ConversationGroup> _groups = [];
  bool _hasListenersRegistered = false;
  bool _enableWebSearch = false;
  bool _enableModelThinking = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _loadAllConversations();
    _initScrollListener();
    Future.microtask(() {
      _calculateTokens();
      _initializeDefaultModel();
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 监听 provider 变化并自动刷新对话列表
    
    // 只注册一次监听器避免重复注册
    if (_hasListenersRegistered) return;
    _hasListenersRegistered = true;
    ref.listen(conversationsProvider, (previous, next) {
      next.whenData((conversations) {
    print('🔍 ChatScreen: 注册 provider 监听器');
        if (mounted) {
      print('🔄 ChatScreen: 对话列表更新: ${conversations.length} 个对话');
          setState(() {
            _conversations = conversations;
          });
        }
      });
    });
    
    ref.listen(conversationGroupsProvider, (previous, next) {
      next.whenData((groups) {
        if (mounted) {
      print('🔄 ChatScreen: 对话分组更新: ${groups.length} 个分组');
          setState(() {
            _groups = groups;
          });
        }
      });
    });
  }
  // 初始化默认模型
  void _initializeDefaultModel() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final activeApiConfig = await settingsRepo.getActiveApiConfig();

    if (activeApiConfig != null && _selectedModel == null) {
      final modelsRepo = ref.read(modelsRepositoryProvider);
      try {
        final apiConfigs = await settingsRepo.getAllApiConfigs();
        final availableModels = await modelsRepo.getAvailableModels(apiConfigs);

        // 查找默认模型
        if (availableModels.isNotEmpty) {
          final defaultModel = availableModels.firstWhere(
            (model) => model.id == activeApiConfig.defaultModel,
            orElse: () => availableModels.first,
          );

          if (mounted) {
            setState(() {
              _selectedModel = defaultModel;
            });
          }
        }
      } catch (e) {
        print('初始化默认模型失败: $e');
      }
    }
  }

  void _initScrollListener() {
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      final isAtBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;

      if (_userScrolledUp != !isAtBottom ||
          _showScrollToBottomButton != !isAtBottom) {
        setState(() {
          _userScrolledUp = !isAtBottom;
          _showScrollToBottomButton = !isAtBottom && _messages.isNotEmpty;
        });
      }
    });
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
    if (conversation != null) {
      setState(() {
        _messages.clear(); // 清空旧消息避免累积
        _messages.addAll(conversation.messages);
      });
    }
  }

  void _calculateTokens() {
    // Token 统计已移至 token_usage 功能模块
  }

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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    // 检查是否配置了 API
    if (kDebugMode) {
      print('ChatScreen: 检查 API 配置...');
    }
    // 打印调试信息
    final storage = ref.read(storageServiceProvider);
    final settingsRepo = ref.read(settingsRepositoryProvider);
    if (kDebugMode) {
      final allKeys = await storage.getAllKeys();
      print('所有存储的 keys: $allKeys');
      final allConfigs = await settingsRepo.getAllApiConfigs();
      print('所有 API 配置数量: ${allConfigs.length}');
      for (final config in allConfigs) {
        print('  配置: ${config.name}, isActive: ${config.isActive}');
      }
    }
    final activeApiConfig = await ref.read(activeApiConfigProvider.future);
    if (kDebugMode) {
      print('ChatScreen: activeApiConfig = $activeApiConfig');
      print(
        'ChatScreen: activeApiConfig.isActive = ${activeApiConfig?.isActive}',
      );
    }
    if (activeApiConfig == null) {
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('未配置 API'),
            content: const Text(
              '您还没有配置任何 API。\n\n'
              '请先在设置中添加 OpenAI、DeepSeek 或其他 AI 服务的 API 配置。',
            ),
            icon: const Icon(
              Icons.warning_amber,
              color: Colors.orange,
              size: 48,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('前往设置'),
              ),
            ],
          ),
        );

        if (result == true && mounted) {
          context.push('/settings');
        }
      }
      return;
    }

    // 处理图片附件
    List<ImageAttachment>? imageAttachments;
    if (_selectedImages.isNotEmpty) {
      imageAttachments = [];
      for (final imageFile in _selectedImages) {
        try {
          // 验证图片
          final validation = await ImageUploadValidator.validateImage(
            imageFile,
          );
          ImageUploadValidator.printReport(validation);

          if (!validation.isValid) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '图片验证失败: ${validation.messages.where((m) => m.contains("❌") || m.contains("失败")).join(", ")}',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            continue; // 跳过不合格的图片
          }

          final base64Data = await ImageUtils.imageToBase64(imageFile);
          final mimeType = ImageUtils.getImageMimeType(imageFile.path);

          // 记录图片信息
          print('图片信息: ${imageFile.path}');
          print('  MIME: $mimeType');
          print('  Base64 长度: ${base64Data.length}');
          print(
            '  Base64 大小: ${(base64Data.length / 1024 / 1024).toStringAsFixed(2)} MB',
          );

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
      _selectedFiles = []; // 清空已选择的文件
    });

    _messageController.clear();
    _scrollToBottom();

    // 记录响应开始时间
    final responseStartTime = DateTime.now();

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
      // 使用用户选择的模型，如果没有选择则使用 API 配置中的默认模型
      final modelToUse = _selectedModel?.id ?? activeApiConfig.defaultModel;
      if (kDebugMode) {
        print('ChatScreen: 使用模型 = $modelToUse');
        print('ChatScreen: 选择的模型 = ${_selectedModel?.name}');
        print('ChatScreen: API 配置默认模型 = ${activeApiConfig.defaultModel}');
      }
      final config = ModelConfig(
        model: modelToUse,
        temperature: activeApiConfig.temperature,
        maxTokens: activeApiConfig.maxTokens,
        topP: activeApiConfig.topP,
        frequencyPenalty: activeApiConfig.frequencyPenalty,
        presencePenalty: activeApiConfig.presencePenalty,
        enableWebSearch: _enableWebSearch,
        enableModelThinking: _enableModelThinking,
      );

      final stream = chatRepo.sendMessageStream(
        conversationId: widget.conversationId,
        content: userMessage.content,
        config: config,
        conversationHistory: _messages.where((m) => !m.isStreaming).toList(),
        images: imageAttachments,
        files: _selectedFiles.map((f) => f.path).toList(),
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
        // 移除自动滚动，让用户可以查看之前的对话
        // _scrollToBottom();
      }

      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        }
        _isLoading = false;
      });

      // 计算响应时间
      final responseDurationMs = DateTime.now().difference(responseStartTime).inMilliseconds;

      // 使用 TokenCounter 估算 token 数量
      final estimatedTokens = TokenCounter.estimate(fullContent);
      int estimatedPromptTokens = TokenCounter.estimate(userMessage.content);

      // 如果有图片附件，加上图片的 token
      if (imageAttachments != null && imageAttachments.isNotEmpty) {
        final imagePaths = imageAttachments.map((img) => img.path).toList();
        final imageTokens = TokenCounter.estimateImages(imagePaths);
        estimatedPromptTokens += imageTokens;
      }

      if (estimatedTokens > 0) {
        setState(() {
          final index = _messages.indexWhere(
            (m) => m.id == assistantMessage.id,
          );
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              tokenCount: estimatedTokens,
              promptTokens: estimatedPromptTokens,
              completionTokens: estimatedTokens,
              model: modelToUse,
              responseDurationMs: responseDurationMs,
            );


          }
        });

        // 记录 token 使用
        await chatRepo.recordTokenUsage(
          conversationId: widget.conversationId,
          messageId: assistantMessage.id,
          model: modelToUse,
          promptTokens: estimatedPromptTokens,
          completionTokens: estimatedTokens,
          totalTokens: estimatedPromptTokens + estimatedTokens,
          messageContent: userMessage.content,
        );
      }

      // 获取对话并保存
      var conversation = chatRepo.getConversation(widget.conversationId);
      if (conversation == null) {
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

      // 如果是第一次对话（只有2条消息：用户+AI），自动生成标题
      if (_messages.length == 2) {
        await chatRepo.generateConversationTitle(widget.conversationId);
      }

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
      // 获取活动的 API 配置
      final activeApiConfigForRegenerate = await ref.read(
        activeApiConfigProvider.future,
      );
      if (activeApiConfigForRegenerate == null) return;

      // 使用用户选择的模型，如果没有选择则使用 API 配置中的默认模型
      final modelToUseForRegenerate =
          _selectedModel?.id ?? activeApiConfigForRegenerate.defaultModel;
      final configForRegenerate = ModelConfig(
        model: modelToUseForRegenerate,
        temperature: activeApiConfigForRegenerate.temperature,
        maxTokens: activeApiConfigForRegenerate.maxTokens,
        topP: activeApiConfigForRegenerate.topP,
        frequencyPenalty: activeApiConfigForRegenerate.frequencyPenalty,
        presencePenalty: activeApiConfigForRegenerate.presencePenalty,
      );

      final stream = chatRepo.sendMessageStream(
        conversationId: widget.conversationId,
        content: userMessage.content,
        config: configForRegenerate,
        conversationHistory: history,
        images: userMessage.images,
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
        // 移除自动滚动，让用户可以查看之前的对话
        // _scrollToBottom();
      }

      setState(() {
        final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        }
        _isLoading = false;
      });

      // 使用 TokenCounter 估算 token 数量
      final estimatedTokensForRegenerate = TokenCounter.estimate(fullContent);
      if (estimatedTokensForRegenerate > 0) {
        setState(() {
          final index = _messages.indexWhere(
            (m) => m.id == assistantMessage.id,
          );
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              tokenCount: estimatedTokensForRegenerate,
              completionTokens: estimatedTokensForRegenerate,
              model: modelToUseForRegenerate,
            );
          }
        });
      }

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
    return PageBackground(
      child: PopScope(
        canPop: !isMobile,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
        // 移动端：canPop=false 会阻止右划手势，但 AppBar 返回按钮依然可用
        },
        child: GestureDetector(
        onTap: () {
          // 点击空白区域隐藏键盘
          _inputFocusNode.unfocus();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          extendBody: true,
            // 在 iOS 上，监听抽屉状态变化，防止键盘异常弹出
            onDrawerChanged: PlatformUtils.isIOS
                ? (isOpened) {
                    // 抽屉打开或关闭时，移除输入框焦点
                    _inputFocusNode.unfocus();
                  }
                : null,
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
                    child: ModernSidebar(
                      conversations: _conversations,
                      groups: _groups,
                      selectedConversation: _conversations
                          .where((c) => c.id == widget.conversationId)
                          .firstOrNull,
                      onConversationSelected: (conversation) {
                        // 移动端：关闭 Drawer 时移除输入框焦点
                        _inputFocusNode.unfocus();
                        Navigator.of(context).pop();
                        context.go('/chat/${conversation.id}');
                      },
                      onCreateConversation: () async {
                        // 移动端：关闭 Drawer 时移除输入框焦点
                        _inputFocusNode.unfocus();
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
                      onManageGroups: () async {
                        // 打开分组管理对话框
                        await showDialog(
                          context: context,
                          builder: (context) => GroupManagementDialog(
                            groups: _groups,
                            onCreateGroup: (name, color) async {
                              final chatRepo = ref.read(chatRepositoryProvider);
                              final group = await chatRepo.createGroup(
                                name: name,
                                color: color,
                              );
                              setState(() {
                                _groups.add(group);
                              });
                            },
                            onUpdateGroup: (group) async {
                              final chatRepo = ref.read(chatRepositoryProvider);
                              await chatRepo.saveGroup(group);
                              setState(() {
                                final index = _groups.indexWhere(
                                  (g) => g.id == group.id,
                                );
                                if (index != -1) {
                                  _groups[index] = group;
                                }
                              });
                            },
                            onDeleteGroup: (id) async {
                              final chatRepo = ref.read(chatRepositoryProvider);
                              await chatRepo.deleteGroup(id);
                              setState(() {
                                _groups.removeWhere((g) => g.id == id);
                              });
                            },
                          ),
                        );
                      },
                      onSearch: () async {
                        // 弹出对话搜索界面
                        final selectedConv = await Navigator.of(context)
                            .push<Conversation>(
                              MaterialPageRoute(
                                builder: (context) => ConversationSearchScreen(
                                  conversations: _conversations,
                                  onConversationSelected: (conv) =>
                                      Navigator.of(context).pop(conv),
                                ),
                              ),
                            );
                        if (selectedConv != null &&
                            mounted &&
                            context.mounted) {
                          context.go('/chat/${selectedConv.id}');
                        }
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
                        currentModelName: _selectedModel?.name,
                        onDeleteMessage: _deleteMessage,
                        onRegenerateMessage: _regenerateMessage,
                        onEditMessage: _editMessage,
                      ),
                    ),
                    ChatInputSection(
                      messageController: _messageController,
                      focusNode: _inputFocusNode,
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
                      onWebSearchToggled: (enabled) {
                        setState(() {
                          _enableWebSearch = enabled;
                        });
                      },
                      enableWebSearch: _enableWebSearch,
                      onModelThinkingToggled: (enabled) {
                        setState(() {
                          _enableModelThinking = enabled;
                        });
                      },
                      enableModelThinking: _enableModelThinking,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.arrow_downward),
                      tooltip: '滚动到底部',
                    ),
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
    _inputFocusNode.dispose();
    super.dispose();
  }
}
