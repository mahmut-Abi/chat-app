import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/providers.dart';
import '../../../agent/domain/agent_tool.dart';
import '../../../mcp/domain/mcp_config.dart';
import '../../../models/domain/model.dart';
import 'dart:io';
import '../../../../core/utils/image_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/message_utils.dart';

/// 聊天功能菜单组件
class ChatFunctionMenu extends ConsumerStatefulWidget {
  final Function(List<File>) onImagesSelected;
  final Function(List<File>) onFilesSelected;
  final Function(AgentConfig?)? onAgentSelected;
  final Function(McpConfig?)? onMcpSelected;
  final Function(AiModel)? onModelSelected;
  final Function(bool)? onWebSearchToggled;
  final AgentConfig? selectedAgent;
  final McpConfig? selectedMcp;
  final AiModel? selectedModel;
  final bool enableWebSearch;
  final Function(bool)? onModelThinkingToggled;
  final bool enableModelThinking;

  const ChatFunctionMenu({
    super.key,
    required this.onImagesSelected,
    required this.onFilesSelected,
    this.onAgentSelected,
    this.onMcpSelected,
    this.onModelSelected,
    this.onWebSearchToggled,
    this.selectedAgent,
    this.selectedMcp,
    this.selectedModel,
    this.enableWebSearch = false,
    this.onModelThinkingToggled,
    this.enableModelThinking = false,
  });

  @override
  ConsumerState<ChatFunctionMenu> createState() => _ChatFunctionMenuState();
}

class _ChatFunctionMenuState extends ConsumerState<ChatFunctionMenu> {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle_outline),
      tooltip: '功能菜单',
      offset: const Offset(0, -10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'image',
          child: Row(
            children: [
              Icon(
                Icons.image_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('图片上传'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'file',
          child: Row(
            children: [
              Icon(
                Icons.attach_file,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('文件上传'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'web_search',
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: widget.enableWebSearch
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.enableWebSearch ? '网络搜索: 开启' : '网络搜索: 关闭'),
              const Spacer(),
              Switch(
                value: widget.enableWebSearch,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (widget.onWebSearchToggled != null) {
                    widget.onWebSearchToggled!(value);
                  }
                },
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'model_thinking',
          child: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: widget.enableModelThinking
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(widget.enableModelThinking ? '模型思考: 开启' : '模型思考: 关闭'),
              const Spacer(),
              Switch(
                value: widget.enableModelThinking,
                onChanged: (value) {
                  Navigator.pop(context);
                  if (widget.onModelThinkingToggled != null) {
                    widget.onModelThinkingToggled!(value);
                  }
                },
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'agent',
          child: Row(
            children: [
              Icon(
                Icons.smart_toy_outlined,
                color: widget.selectedAgent != null
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.selectedAgent != null
                    ? '智能体: ${widget.selectedAgent!.name}'
                    : '选择智能体',
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'mcp',
          child: Row(
            children: [
              Icon(
                Icons.extension_outlined,
                color: widget.selectedMcp != null
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.selectedMcp != null
                    ? 'MCP: ${widget.selectedMcp!.name}'
                    : '选择MCP',
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'model',
          child: Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: widget.selectedModel != null
                    ? Theme.of(context).colorScheme.secondary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.selectedModel != null
                    ? '模型: ${widget.selectedModel!.name}'
                    : '选择模型',
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'web_search':
            // Handled by the switch in the menu item
            break;
          case 'image':
            _pickImages();
            break;
          case 'file':
            _pickFiles();
            break;
          case 'agent':
            _showAgentSelector();
            break;
          case 'mcp':
            _showMcpSelector();
            break;
          case 'model':
            _showModelSelector();
            break;
        }
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImageUtils.pickImages();
      if (images != null && images.isNotEmpty) {
        widget.onImagesSelected(images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('图片选择失败')));
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (result != null && result.files.isNotEmpty) {
        final files = result.files.map((file) => File(file.path!)).toList();
        widget.onFilesSelected(files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('文件选择失败')));
      }
    }
  }

  Future<void> _showAgentSelector() async {
    // 强制刷新 Agent 列表，确保获取最新数据
    if (kDebugMode) {
      print('[ChatFunctionMenu] 开始显示 Agent 选择器');
    }
    ref.invalidate(agentConfigsProvider);

    // 等待 Agent 列表加载完成
    if (kDebugMode) {
      print('[ChatFunctionMenu] 等待 Agent 列表加载...');
    }
    final agents = await ref.read(agentConfigsProvider.future);
    if (kDebugMode) {
      print('[ChatFunctionMenu] Agent 列表加载完成: ${agents.length} 个配置');
      for (final agent in agents) {
        print(
          '[ChatFunctionMenu]   - ${agent.name} (enabled: ${agent.enabled})',
        );
      }
    }

    if (!mounted) return;

    final selected = await showDialog<AgentConfig?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择智能体'),
        content: SizedBox(
          width: double.maxFinite,
          child: agents.isEmpty
              ? const Center(child: Text('暂无智能体配置，请先在设置中创建'))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('不使用智能体'),
                      leading: const Icon(Icons.clear),
                      selected: widget.selectedAgent == null,
                      onTap: () => Navigator.pop(context, null),
                    ),
                    const Divider(),
                    ...agents.map(
                      (agent) => ListTile(
                        title: Text(agent.name),
                        subtitle: agent.description != null
                            ? Text(agent.description!)
                            : null,
                        leading: Icon(
                          Icons.smart_toy,
                          color: agent.enabled
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        trailing: agent.enabled
                            ? null
                            : const Chip(
                                label: Text('已禁用'),
                                visualDensity: VisualDensity.compact,
                              ),
                        selected: widget.selectedAgent?.id == agent.id,
                        enabled: agent.enabled,
                        onTap: agent.enabled
                            ? () => Navigator.pop(context, agent)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (widget.onAgentSelected != null) {
      widget.onAgentSelected!(selected);
    }
  }

  Future<void> _showMcpSelector() async {
    // 强制刷新 MCP 列表，确保获取最新数据
    if (kDebugMode) {
      print('[ChatFunctionMenu] 开始显示 MCP 选择器');
    }
    ref.invalidate(mcpConfigsProvider);

    // 等待 MCP 列表加载完成
    if (kDebugMode) {
      print('[ChatFunctionMenu] 等待 MCP 列表加载...');
    }
    final mcpsAsync = await ref.read(mcpConfigsProvider.future);
    final mcps = mcpsAsync;
    if (kDebugMode) {
      print('[ChatFunctionMenu] MCP 列表加载完成: ${mcps.length} 个配置');
      for (final mcp in mcps) {
        print('[ChatFunctionMenu]   - ${mcp.name} (enabled: ${mcp.enabled})');
      }
    }

    if (!mounted) return;

    final selected = await showDialog<McpConfig?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择MCP'),
        content: SizedBox(
          width: double.maxFinite,
          child: mcps.isEmpty
              ? const Center(child: Text('暂无MCP配置,请先在设置中创建'))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: const Text('不使用MCP'),
                      leading: const Icon(Icons.clear),
                      selected: widget.selectedMcp == null,
                      onTap: () => Navigator.pop(context, null),
                    ),
                    const Divider(),
                    ...mcps.map(
                      (mcp) => ListTile(
                        title: Text(mcp.name),
                        subtitle: mcp.description != null
                            ? Text(mcp.description!)
                            : null,
                        leading: Icon(
                          Icons.extension,
                          color: mcp.enabled
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        trailing: mcp.enabled
                            ? null
                            : const Chip(
                                label: Text('已禁用'),
                                visualDensity: VisualDensity.compact,
                              ),
                        selected: widget.selectedMcp?.id == mcp.id,
                        enabled: mcp.enabled,
                        onTap: mcp.enabled
                            ? () => Navigator.pop(context, mcp)
                            : null,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (widget.onMcpSelected != null) {
      widget.onMcpSelected!(selected);
    }
  }

  Future<void> _showModelSelector() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final apiConfigs = await settingsRepo.getAllApiConfigs();
    final modelsRepo = ref.read(modelsRepositoryProvider);

    print('开始获取模型列表...');
    print('API 配置数量: ${apiConfigs.length}');

    List<AiModel> models;

    try {
      // 先尝试从本地存储加载模型
      models = await modelsRepo.getCachedModels();
      print('从本地存储加载模型: ${models.length} 个');

      // 如果本地没有模型，尝试从 API 获取
      if (models.isEmpty && apiConfigs.isNotEmpty) {
        print('本地没有模型，从 API 获取...');
        models = await modelsRepo.getAvailableModels(apiConfigs);
        print('从 API 获取到 ${models.length} 个模型');

        // 自动缓存获取到的模型
        if (models.isNotEmpty) {
          await modelsRepo.cacheModels(models);
          print('已将 ${models.length} 个模型缓存到本地');
        }
      }
    } catch (e) {
      print('获取模型失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('获取模型列表失败: $e')));
      }
      return;
    }

    if (!mounted) return;

    final selected = await showDialog<AiModel?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择模型'),
        content: SizedBox(
          width: double.maxFinite,
          child: models.isEmpty
              ? const Center(child: Text('暂无可用模型'))
              : ListView(
                  shrinkWrap: true,
                  children: models
                      .map(
                        (model) => ListTile(
                          title: Text(model.name),
                          subtitle: Text(model.description ?? ''),
                          leading: Icon(
                            Icons.psychology,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (model.supportsVision)
                                const Icon(Icons.visibility, size: 16),
                              if (model.supportsFunctions)
                                const Icon(Icons.functions, size: 16),
                            ],
                          ),
                          selected: widget.selectedModel?.id == model.id,
                          onTap: () => Navigator.pop(context, model),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (selected != null && widget.onModelSelected != null) {
      widget.onModelSelected!(selected);
    }
  }
}
