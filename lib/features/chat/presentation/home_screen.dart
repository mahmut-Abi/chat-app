import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../domain/conversation.dart';
import 'chat_screen.dart';
import 'widgets/enhanced_sidebar.dart';
import 'widgets/group_management_dialog.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../core/utils/desktop_utils.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../../../shared/widgets/background_container.dart';

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
    setState(() {
      _conversations = chatRepo.getAllConversations();
      _groups = chatRepo.getAllGroups();
      if (_conversations.isNotEmpty && _selectedConversation == null) {
        _selectedConversation = _conversations.first;
      }
    });
  }

  Future<void> _createNewConversation() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversation = await chatRepo.createConversation(title: '新建对话');

    setState(() {
      _conversations.insert(0, conversation);
      _selectedConversation = conversation;
    });

    if (mounted) {
      context.push('/chat/${conversation.id}');
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
    final controller = TextEditingController(text: conversation.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名对话'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '标题',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.updateConversationTitle(conversation.id, result);
      _loadData();
    }

    controller.dispose();
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
              context.push('/chat/${conversation.id}');
            },
            onCreateConversation: _createNewConversation,
            onDeleteConversation: _deleteConversation,
            onRenameConversation: _showRenameDialog,
            onUpdateTags: _updateConversationTags,
            onManageGroups: _showGroupManagement,
          ),
          Expanded(
            child: _selectedConversation == null
                ? BackgroundContainer(child: _buildWelcomeScreen())
                : ChatScreen(conversationId: _selectedConversation!.id),
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

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: const Text('确定要删除这个对话吗?此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
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
        appBar: AppBar(
          title: Text(_selectedConversation?.title ?? 'Chat App'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [],
        ),
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
              context.push('/chat/${conversation.id}');
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
        body: _selectedConversation == null
            ? BackgroundContainer(child: _buildWelcomeScreen())
            : ChatScreen(conversationId: _selectedConversation!.id),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: ConversationSearchDelegate(
        conversations: _conversations,
        onConversationSelected: (conversation) {
          setState(() {
            _selectedConversation = conversation;
          });
          context.push('/chat/${conversation.id}');
        },
      ),
    );
  }
}

class ConversationSearchDelegate extends SearchDelegate<Conversation?> {
  final List<Conversation> conversations;
  final Function(Conversation) onConversationSelected;

  ConversationSearchDelegate({
    required this.conversations,
    required this.onConversationSelected,
  });

  @override
  String get searchFieldLabel => '搜索对话...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = conversations.where((conv) {
      final searchLower = query.toLowerCase();
      return conv.title.toLowerCase().contains(searchLower) ||
          conv.messages.any(
            (msg) => msg.content.toLowerCase().contains(searchLower),
          );
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('没有找到相关对话'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final conversation = results[index];
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(conversation.title),
          subtitle: Text(
            '${conversation.messages.length} 条消息',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, conversation);
            onConversationSelected(conversation);
          },
        );
      },
    );
  }
}
