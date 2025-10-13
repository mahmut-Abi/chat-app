import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/utils/data_export_import.dart';
import '../../../core/utils/pdf_export.dart';
import '../../chat/domain/conversation.dart';
import '../../../shared/themes/app_theme.dart';
import '../../../core/network/openai_api_client.dart';
import '../../../core/network/dio_client.dart';
import 'background_settings_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<ApiConfig> _apiConfigs = [];
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _loadApiConfigs();
  }

  Future<void> _loadApiConfigs() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final configs = await settingsRepo.getAllApiConfigs();
    setState(() {
      _apiConfigs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSection(
            title: 'API 配置',
            children: [
              ..._apiConfigs.map((config) => _buildApiConfigTile(config)),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('添加 API 配置'),
                onTap: _showAddApiConfigDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '外观',
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('主题模式'),
                subtitle: Text(_getThemeModeText(settings.themeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeDialog,
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('主题颜色'),
                subtitle: Text(settings.themeColor ?? '默认'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showThemeColorDialog,
              ),
              ListTile(
                leading: const Icon(Icons.format_size),
                title: const Text('字体大小'),
                subtitle: Text('${settings.fontSize.toInt()}'),
                trailing: SizedBox(
                  width: 150,
                  child: Slider(
                    value: settings.fontSize,
                    min: 12.0,
                    max: 20.0,
                    divisions: 8,
                    label: settings.fontSize.toInt().toString(),
                    onChanged: (value) {
                      _updateFontSize(value);
                    },
                  ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.code),
                title: const Text('启用 Markdown 渲染'),
                subtitle: const Text('支持文本格式化和代码高亮'),
                value: settings.enableMarkdown,
                onChanged: (value) {
                  _updateMarkdownEnabled(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.highlight),
                title: const Text('启用代码高亮'),
                subtitle: const Text('高亮显示代码块'),
                value: settings.enableCodeHighlight,
                onChanged: (value) {
                  _updateCodeHighlightEnabled(value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.functions),
                title: const Text('启用 LaTeX 数学公式'),
                subtitle: const Text('渲染数学公式（实验性）'),
                value: settings.enableLatex,
                onChanged: (value) {
                  _updateLatexEnabled(value);
                },
              ),
              ListTile(
                leading: const Icon(Icons.wallpaper),
                title: const Text('背景设置'),
                subtitle: const Text('自定义聊天背景'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showBackgroundDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '数据管理',
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('导出数据'),
                subtitle: const Text('导出所有对话和配置'),
                trailing: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isExporting ? null : _exportData,
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('导出为 PDF'),
                subtitle: const Text('将对话导出为 PDF 文件'),
                onTap: _exportToPdf,
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('导入数据'),
                subtitle: const Text('从文件恢复数据'),
                trailing: _isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _isImporting ? null : _importData,
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  '清除所有数据',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: _showClearDataDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: '关于',
            children: [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('版本'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('开源许可'),
                onTap: () {
                  showLicensePage(context: context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildApiConfigTile(ApiConfig config) {
    return ListTile(
      leading: const Icon(Icons.api),
      title: Text(config.name),
      subtitle: Text(config.provider),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            tooltip: '测试连接',
            onPressed: () => _testApiConnection(config),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditApiConfigDialog(config),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteApiConfig(config),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(String mode) {
    switch (mode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }

  Future<void> _showThemeDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('浅色'),
              leading: const Icon(Icons.light_mode),
              onTap: () => Navigator.pop(context, 'light'),
            ),
            ListTile(
              title: const Text('深色'),
              leading: const Icon(Icons.dark_mode),
              onTap: () => Navigator.pop(context, 'dark'),
            ),
            ListTile(
              title: const Text('跟随系统'),
              leading: const Icon(Icons.brightness_auto),
              onTap: () => Navigator.pop(context, 'system'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final storage = ref.read(storageServiceProvider);
      await storage.saveSetting('themeMode', result);
      ref.invalidate(appSettingsProvider);
    }
  }

  void _showBackgroundDialog() {
    showDialog(
      context: context,
      builder: (context) => const BackgroundSettingsDialog(),
    );
  }

  Future<void> _showThemeColorDialog() async {
    final settings = ref.read(appSettingsProvider);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题颜色'),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: AppTheme.predefinedColors.length,
            itemBuilder: (context, index) {
              final entry = AppTheme.predefinedColors.entries.elementAt(index);
              final isSelected = settings.themeColor == entry.key;
              return InkWell(
                onTap: () => Navigator.pop(context, entry.key),
                child: Container(
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                  ),
                  child: isSelected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : null,
                ),
              );
            },
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

    if (result != null) {
      _updateThemeColor(result);
    }
  }

  Future<void> _updateThemeColor(String colorKey) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.updateThemeColor(colorKey);
    ref.invalidate(appSettingsProvider);
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final storage = ref.read(storageServiceProvider);
      final exporter = DataExportImport(storage);
      final jsonData = await exporter.exportAllData();

      final fileName =
          'chat_app_export_${DateTime.now().toIso8601String().split('T')[0]}.json';

      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: '保存导出文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsString(jsonData);

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('数据已导出到: $path')));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('当前平台暂不支持导出功能')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonData = await file.readAsString();

        final storage = ref.read(storageServiceProvider);
        final importer = DataExportImport(storage);
        final importResult = await importer.importData(jsonData);

        if (mounted) {
          if (importResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '成功导入 ${importResult['conversationsCount']} 个对话和 ${importResult['apiConfigsCount']} 个配置',
                ),
              ),
            );
            _loadApiConfigs();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('导入失败: ${importResult['error']}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败: ${e.toString()}')));
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _showAddApiConfigDialog() async {
    final nameController = TextEditingController();
    final baseUrlController = TextEditingController();
    final apiKeyController = TextEditingController();
    final proxyUrlController = TextEditingController();
    final proxyUsernameController = TextEditingController();
    final proxyPasswordController = TextEditingController();
    final modelController = TextEditingController(text: 'gpt-3.5-turbo');
    double temperature = 0.7;
    int maxTokens = 2000;
    double topP = 1.0;
    double frequencyPenalty = 0.0;
    double presencePenalty = 0.0;
    String selectedProvider = 'OpenAI';
    bool enableProxy = false;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('添加 API 配置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '配置名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: '提供商',
                    border: OutlineInputBorder(),
                  ),
                  items: ['OpenAI', 'Azure OpenAI', 'Ollama', 'Custom']
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedProvider = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                // 模型参数设置
                ExpansionTile(
                  title: const Text('模型参数设置'),
                  initiallyExpanded: false,
                  children: [
                    const SizedBox(height: 8),
                    TextField(
                      controller: modelController,
                      decoration: const InputDecoration(
                        labelText: '默认模型',
                        border: OutlineInputBorder(),
                        hintText: 'gpt-3.5-turbo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    StatefulBuilder(
                      builder: (context, setSliderState) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temperature: ${temperature.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: temperature,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            onChanged: (value) {
                              setSliderState(() => temperature = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('Max Tokens: $maxTokens'),
                          Slider(
                            value: maxTokens.toDouble(),
                            min: 100,
                            max: 4000,
                            divisions: 39,
                            onChanged: (value) {
                              setSliderState(() => maxTokens = value.toInt());
                            },
                          ),
                          const SizedBox(height: 8),
                          Text('Top P: ${topP.toStringAsFixed(2)}'),
                          Slider(
                            value: topP,
                            min: 0.0,
                            max: 1.0,
                            divisions: 10,
                            onChanged: (value) {
                              setSliderState(() => topP = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Frequency Penalty: ${frequencyPenalty.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: frequencyPenalty,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            onChanged: (value) {
                              setSliderState(() => frequencyPenalty = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Presence Penalty: ${presencePenalty.toStringAsFixed(2)}',
                          ),
                          Slider(
                            value: presencePenalty,
                            min: 0.0,
                            max: 2.0,
                            divisions: 20,
                            onChanged: (value) {
                              setSliderState(() => presencePenalty = value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用 HTTP 代理'),
                  value: enableProxy,
                  onChanged: (value) {
                    setState(() {
                      enableProxy = value;
                    });
                  },
                ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyUrlController,
                    decoration: const InputDecoration(
                      labelText: '代理地址',
                      border: OutlineInputBorder(),
                      hintText: 'http://proxy.example.com:8080',
                    ),
                  ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyUsernameController,
                    decoration: const InputDecoration(
                      labelText: '代理用户名（可选）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyPasswordController,
                    decoration: const InputDecoration(
                      labelText: '代理密码（可选）',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    baseUrlController.text.isNotEmpty &&
                    apiKeyController.text.isNotEmpty) {
                  final result = <String, String>{
                    'name': nameController.text,
                    'provider': selectedProvider,
                    'baseUrl': baseUrlController.text,
                    'apiKey': apiKeyController.text,
                    'defaultModel': modelController.text,
                    'temperature': temperature.toString(),
                    'maxTokens': maxTokens.toString(),
                    'topP': topP.toString(),
                    'frequencyPenalty': frequencyPenalty.toString(),
                    'presencePenalty': presencePenalty.toString(),
                  };
                  if (enableProxy && proxyUrlController.text.isNotEmpty) {
                    result['proxyUrl'] = proxyUrlController.text;
                    if (proxyUsernameController.text.isNotEmpty) {
                      result['proxyUsername'] = proxyUsernameController.text;
                    }
                    if (proxyPasswordController.text.isNotEmpty) {
                      result['proxyPassword'] = proxyPasswordController.text;
                    }
                  }
                  Navigator.pop(context, result);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.createApiConfig(
        name: result['name']!,
        provider: result['provider']!,
        baseUrl: result['baseUrl']!,
        apiKey: result['apiKey']!,
        proxyUrl: result['proxyUrl'],
        proxyUsername: result['proxyUsername'],
        proxyPassword: result['proxyPassword'],
        defaultModel: result['defaultModel'],
        temperature: double.tryParse(result['temperature'] ?? '0.7'),
        maxTokens: int.tryParse(result['maxTokens'] ?? '2000'),
        topP: double.tryParse(result['topP'] ?? '1.0'),
        frequencyPenalty: double.tryParse(result['frequencyPenalty'] ?? '0.0'),
        presencePenalty: double.tryParse(result['presencePenalty'] ?? '0.0'),
      );
      _loadApiConfigs();
    }

    nameController.dispose();
    baseUrlController.dispose();
    apiKeyController.dispose();
    proxyUrlController.dispose();
    proxyUsernameController.dispose();
    proxyPasswordController.dispose();
    modelController.dispose();
  }

  Future<void> _showEditApiConfigDialog(ApiConfig config) async {
    final nameController = TextEditingController(text: config.name);
    final baseUrlController = TextEditingController(text: config.baseUrl);
    final apiKeyController = TextEditingController(text: config.apiKey);
    final proxyUrlController = TextEditingController(
      text: config.proxyUrl ?? '',
    );
    final proxyUsernameController = TextEditingController(
      text: config.proxyUsername ?? '',
    );
    final proxyPasswordController = TextEditingController(
      text: config.proxyPassword ?? '',
    );
    String selectedProvider = config.provider;
    bool enableProxy = config.proxyUrl != null && config.proxyUrl!.isNotEmpty;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('编辑 API 配置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '配置名称',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: '提供商',
                    border: OutlineInputBorder(),
                  ),
                  items: ['OpenAI', 'Azure OpenAI', 'Ollama', 'Custom']
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedProvider = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('启用 HTTP 代理'),
                  value: enableProxy,
                  onChanged: (value) {
                    setState(() {
                      enableProxy = value;
                    });
                  },
                ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyUrlController,
                    decoration: const InputDecoration(
                      labelText: '代理地址',
                      border: OutlineInputBorder(),
                      hintText: 'http://proxy.example.com:8080',
                    ),
                  ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyUsernameController,
                    decoration: const InputDecoration(
                      labelText: '代理用户名（可选）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (enableProxy) const SizedBox(height: 16),
                if (enableProxy)
                  TextField(
                    controller: proxyPasswordController,
                    decoration: const InputDecoration(
                      labelText: '代理密码（可选）',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final result = <String, String>{
                  'name': nameController.text,
                  'provider': selectedProvider,
                  'baseUrl': baseUrlController.text,
                  'apiKey': apiKeyController.text,
                };
                if (enableProxy && proxyUrlController.text.isNotEmpty) {
                  result['proxyUrl'] = proxyUrlController.text;
                  if (proxyUsernameController.text.isNotEmpty) {
                    result['proxyUsername'] = proxyUsernameController.text;
                  }
                  if (proxyPasswordController.text.isNotEmpty) {
                    result['proxyPassword'] = proxyPasswordController.text;
                  }
                }
                Navigator.pop(context, result);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.updateApiConfig(
        config.id,
        name: result['name']!,
        provider: result['provider']!,
        baseUrl: result['baseUrl']!,
        apiKey: result['apiKey']!,
        proxyUrl: result['proxyUrl'],
        proxyUsername: result['proxyUsername'],
        proxyPassword: result['proxyPassword'],
      );
      _loadApiConfigs();
    }

    nameController.dispose();
    baseUrlController.dispose();
    apiKeyController.dispose();
    proxyUrlController.dispose();
    proxyUsernameController.dispose();
    proxyPasswordController.dispose();
  }

  Future<void> _deleteApiConfig(ApiConfig config) async {
    final confirm = await _showDeleteConfirmDialog();
    if (confirm == true) {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.deleteApiConfig(config.id);
      _loadApiConfigs();
    }
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除 API 配置'),
        content: const Text('确定要删除此配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除所有数据'),
        content: const Text('这将删除所有对话和设置。此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = ref.read(storageServiceProvider);
      if (kDebugMode) {
        print('开始清除所有数据...');
      }

      // 显示加载指示器
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      await storage.clearAll();

      // 重置 Provider 状态
      ref.invalidate(appSettingsProvider);
      ref.invalidate(chatRepositoryProvider);

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('所有数据已清除')));

        // 重新加载 API 配置
        _loadApiConfigs();

        // 返回首页
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _exportToPdf() async {
    final chatRepo = ref.read(chatRepositoryProvider);
    final conversations = chatRepo.getAllConversations();

    if (conversations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有可导出的对话')));
      }
      return;
    }

    final selectedConversations = await _showSelectConversationsDialog(
      conversations,
    );

    if (selectedConversations != null && selectedConversations.isNotEmpty) {
      try {
        if (selectedConversations.length == 1) {
          await PdfExport.exportConversationToPdf(selectedConversations.first);
        } else {
          await PdfExport.exportConversationsToPdf(selectedConversations);
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PDF 导出成功')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('PDF 导出失败: ${e.toString()}')));
        }
      }
    }
  }

  Future<List<Conversation>?> _showSelectConversationsDialog(
    List<Conversation> conversations,
  ) async {
    final selected = <String>{};
    return showDialog<List<Conversation>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('选择要导出的对话'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conv = conversations[index];
                return CheckboxListTile(
                  title: Text(conv.title),
                  subtitle: Text('${conv.messages.length} 条消息'),
                  value: selected.contains(conv.id),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selected.add(conv.id);
                      } else {
                        selected.remove(conv.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (selected.length == conversations.length) {
                    selected.clear();
                  } else {
                    selected.addAll(conversations.map((c) => c.id));
                  }
                });
              },
              child: Text(
                selected.length == conversations.length ? '取消全选' : '全选',
              ),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      final result = conversations
                          .where((c) => selected.contains(c.id))
                          .toList();
                      Navigator.pop(context, result);
                    },
              child: const Text('导出'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFontSize(double fontSize) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.updateFontSize(fontSize);
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(fontSize: fontSize),
        );
  }

  Future<void> _updateMarkdownEnabled(bool enabled) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveSetting('enableMarkdown', enabled);
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableMarkdown: enabled),
        );
  }

  Future<void> _updateCodeHighlightEnabled(bool enabled) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveSetting('enableCodeHighlight', enabled);
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableCodeHighlight: enabled),
        );
  }

  Future<void> _updateLatexEnabled(bool enabled) async {
    final storage = ref.read(storageServiceProvider);
    await storage.saveSetting('enableLatex', enabled);
    ref
        .read(appSettingsProvider.notifier)
        .updateSettings(
          ref.read(appSettingsProvider).copyWith(enableLatex: enabled),
        );
  }

  // 测试 API 连接
  Future<void> _testApiConnection(ApiConfig config) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在测试连接...'),
          ],
        ),
      ),
    );

    try {
      final dioClient = DioClient(
        baseUrl: config.baseUrl,
        apiKey: config.apiKey,
        proxyUrl: config.proxyUrl,
      );
      final apiClient = OpenAIApiClient(dioClient);
      final result = await apiClient.testConnection();

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result.success ? '连接成功' : '连接失败'),
            content: Text(result.message),
            icon: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 48,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('连接失败'),
            content: Text('发生错误: ${e.toString()}'),
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    }
  }
}
