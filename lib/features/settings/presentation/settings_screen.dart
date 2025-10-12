import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../domain/api_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<ApiConfig> _apiConfigs = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: 'API Configuration',
            children: [
              ..._apiConfigs.map((config) => _buildApiConfigTile(config)),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add API Configuration'),
                onTap: _showAddApiConfigDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Theme'),
                subtitle: const Text('System default'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement theme picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('Font Size'),
                subtitle: const Text('Medium'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement font size picker
                },
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export Data'),
                onTap: () {
                  // TODO: Implement export
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload),
                title: const Text('Import Data'),
                onTap: () {
                  // TODO: Implement import
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Clear All Data',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: _showClearDataDialog,
              ),
            ],
          ),
          const Divider(),
          _buildSection(
            title: 'About',
            children: [
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Licenses'),
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildApiConfigTile(ApiConfig config) {
    return ListTile(
      leading: Icon(
        config.isActive ? Icons.check_circle : Icons.circle_outlined,
        color: config.isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).disabledColor,
      ),
      title: Text(config.name),
      subtitle: Text('${config.provider} - ${config.baseUrl}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          if (!config.isActive)
            const PopupMenuItem(
              value: 'activate',
              child: Text('Set as Active'),
            ),
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) async {
          if (value == 'activate') {
            final settingsRepo = ref.read(settingsRepositoryProvider);
            await settingsRepo.setActiveApiConfig(config.id);
            _loadApiConfigs();
          } else if (value == 'edit') {
            _showEditApiConfigDialog(config);
          } else if (value == 'delete') {
            final confirm = await _showDeleteConfirmDialog();
            if (confirm == true) {
              final settingsRepo = ref.read(settingsRepositoryProvider);
              await settingsRepo.deleteApiConfig(config.id);
              _loadApiConfigs();
            }
          }
        },
      ),
      onTap: () async {
        final settingsRepo = ref.read(settingsRepositoryProvider);
        await settingsRepo.setActiveApiConfig(config.id);
        _loadApiConfigs();
      },
    );
  }

  Future<void> _showAddApiConfigDialog() async {
    final nameController = TextEditingController();
    final baseUrlController = TextEditingController(
      text: 'https://api.openai.com/v1',
    );
    final apiKeyController = TextEditingController();
    String selectedProvider = 'OpenAI';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add API Configuration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: ['OpenAI', 'Azure OpenAI', 'Ollama', 'Custom']
                      .map((provider) => DropdownMenuItem(
                            value: provider,
                            child: Text(provider),
                          ),)
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, {
                  'name': nameController.text,
                  'provider': selectedProvider,
                  'baseUrl': baseUrlController.text,
                  'apiKey': apiKeyController.text,
                });
              },
              child: const Text('Add'),
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
      );
      _loadApiConfigs();
    }

    nameController.dispose();
    baseUrlController.dispose();
    apiKeyController.dispose();
  }

  Future<void> _showEditApiConfigDialog(ApiConfig config) async {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit not implemented yet')),
    );
  }

  Future<bool?> _showDeleteConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Configuration'),
        content: const Text('Are you sure you want to delete this configuration?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all conversations and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = ref.read(storageServiceProvider);
      await storage.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }
}
