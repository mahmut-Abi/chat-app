import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' show Platform;
import '../../../shared/widgets/platform_dialog.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import 'chat_screen.dart';
import 'widgets/enhanced_sidebar.dart';
import 'widgets/conversation_search_screen.dart';
import 'widgets/group_management_dialog.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../core/utils/desktop_utils.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../../../shared/widgets/background_container.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TrayListener, WindowListener {
  List<Conversation> _conversations = [];
  List<ConversationGroup> _groups = [];
  Conversation? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initDesktopFeatures();
  }

  void _initDesktopFeatures() {
    if (DesktopUtils.isDesktop) {
      trayManager.addListener(this);
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (DesktopUtils.isDesktop) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // TrayListener 实现
  @override
  void onTrayIconMouseDown() {
    DesktopUtils.showWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        DesktopUtils.showWindow();
        break;
      case 'new_conversation':
        _createNewConversation();
        break;
      case 'quit':
        DesktopUtils.quitApp();
        break;
    }
  }

  // WindowListener 实现
  @override
  void onWindowClose() async {
    // 关闭窗口时最小化到托盘
    await DesktopUtils.minimizeToTray();
  }

  void _loadData() {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversations = chatRepo.getAllConversations();
    final groups = chatRepo.getAllGroups();

    if (mounted) {
      setState(() {
        _conversations = conversations;
        _groups = groups;
        if (_conversations.isNotEmpty && _selectedConversation == null) {
          _selectedConversation = _conversations.first;
        }
      });
    }
  }

  Future<void> _createNewConversation() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    if (kDebugMode) {
      print('HomeScreen._createNewConversation: 开始创建');
    }

    final conversation = await chatRepo.createConversation(title: '新建对话');

    if (kDebugMode) {
      print('HomeScreen._createNewConversation: 创建完成');
      print('  id: \${conversation.id}');
      print('  title: \${conversation.title}');
      print('  isTemporary: \${conversation.isTemporary}');
    }

    // 不更新 _conversations，因为临时对话不应该显示在侧边栏
    // 直接跳转到聊天界面
    if (mounted) {
      setState(() {
        _selectedConversation = conversation;
      });
    }

    if (kDebugMode) {
      print('HomeScreen._createNewConversation: 状态已更新');
    }

    if (mounted) {
      if (kDebugMode) {
        print(
          'HomeScreen._createNewConversation: 导航到 /chat/${conversation.id}',
        );
      }
      context.go('/chat/${conversation.id}'); // 使用 go 替换路由
    }
  }

  Future<void> _deleteConversation(String id) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.deleteConversation(id);
      _loadData();

      if (_selectedConversation?.id == id) {
        setState(() {
          _selectedConversation = _conversations.isNotEmpty
              ? _conversations.first
              : null;
        });
      }
    }
  }

  Future<void> _showRenameDialog(Conversation conversation) async {
    final result = await showPlatformInputDialog(
      context: context,
      title: '重命名对话',
      initialValue: conversation.title,
      placeholder: '标题',
      confirmText: '保存',
    );

    if (result != null && result.isNotEmpty) {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.updateConversationTitle(conversation.id, result);
      _loadData();
    }
  }

  Future<void> _updateConversationTags(
    Conversation conversation,
    List<String> tags,
  ) async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final updated = conversation.copyWith(tags: tags);
    await chatRepo.saveConversation(updated);
    _loadData();
  }

  Future<void> _showGroupManagement() async {
    await showDialog(
      context: context,
      builder: (context) => GroupManagementDialog(
        groups: _groups,
        onCreateGroup: (name, color) async {
          final chatRepo = ref.read(chatRepositoryProvider);
          await chatRepo.createGroup(name: name, color: color);
          _loadData();
        },
        onUpdateGroup: (group) async {
          final chatRepo = ref.read(chatRepositoryProvider);
          await chatRepo.updateGroup(group);
          _loadData();
        },
        onDeleteGroup: (id) async {
          final chatRepo = ref.read(chatRepositoryProvider);
          await chatRepo.deleteGroup(id);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isMobile) {
      return _buildMobileLayout();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索 (Ctrl+F)',
            onPressed: _showSearch,
          ),
        ],
      ),
      body: Row(
        children: [
          EnhancedSidebar(
            conversations: _conversations,
            groups: _groups,
            selectedConversation: _selectedConversation,
            onConversationSelected: (conversation) {
              setState(() {
                _selectedConversation = conversation;
              });
              context.go('/chat/${conversation.id}');
            },
            onCreateConversation: _createNewConversation,
            onDeleteConversation: _deleteConversation,
            onRenameConversation: _showRenameDialog,
            onUpdateTags: _updateConversationTags,
            onManageGroups: _showGroupManagement,
          ),
          Expanded(
            child: BackgroundContainer(
              child: _selectedConversation == null
                  ? _buildWelcomeScreen()
                  : ChatScreen(conversationId: _selectedConversation!.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '欢迎使用 Chat App',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text('创建一个新对话开始聊天', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createNewConversation,
            icon: const Icon(Icons.add),
            label: const Text('开始新对话'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteDialog() async {
    return await showPlatformConfirmDialog(
      context: context,
      title: '删除对话',
      content: '确定要删除这个对话吗?此操作无法撤销。',
      confirmText: '删除',
      isDestructive: true,
    );
  }

  Widget _buildMobileLayout() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // 阻止默认的返回行为，避免 iOS 右划手势触发路由返回
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawerScrimColor: Colors.black.withValues(alpha: 0.5),
        drawerEnableOpenDragGesture: true,
        endDrawerEnableOpenDragGesture: false,
        drawer: Drawer(
          backgroundColor: Theme.of(context).cardColor,
          child: EnhancedSidebar(
            conversations: _conversations,
            groups: _groups,
            selectedConversation: _selectedConversation,
            onConversationSelected: (conversation) {
              setState(() {
                _selectedConversation = conversation;
              });
              Navigator.of(context).pop();
              context.go('/chat/${conversation.id}');
            },
            onCreateConversation: () {
              Navigator.of(context).pop();
              _createNewConversation();
            },
            onDeleteConversation: _deleteConversation,
            onRenameConversation: _showRenameDialog,
            onUpdateTags: _updateConversationTags,
            onManageGroups: _showGroupManagement,
            onSearch: _showSearch,
          ),
        ),
        body: Stack(
          children: [
            _selectedConversation == null
                ? BackgroundContainer(child: _buildWelcomeScreen())
                : ChatScreen(conversationId: _selectedConversation!.id),
            // 左上角透明菜单按钮 (仅非 iOS 平台显示)
            if (!Platform.isIOS)
              Positioned(
                top: 60,
                left: 16,
                child: Builder(
                  builder: (context) => Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      tooltip: '打开菜单',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationSearchScreen(
          conversations: _conversations,
          onConversationSelected: (conversation) {
            setState(() {
              _selectedConversation = conversation;
            });
            context.go('/chat/\${conversation.id}');
          },
        ),
      ),
    );
  }
}
