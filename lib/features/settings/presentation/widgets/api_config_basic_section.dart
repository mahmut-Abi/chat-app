import 'package:flutter/material.dart';

class ApiConfigBasicSection extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController baseUrlController;
  final TextEditingController apiKeyController;
  final TextEditingController organizationController;
  final String selectedProvider;
  final Function(String?) onProviderChanged;

  const ApiConfigBasicSection({
    super.key,
    required this.nameController,
    required this.baseUrlController,
    required this.apiKeyController,
    required this.organizationController,
    required this.selectedProvider,
    required this.onProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('基本配置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '配置名称 *',
                hintText: '例如: 我的 OpenAI',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入配置名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedProvider,
              decoration: const InputDecoration(
                labelText: 'API 提供商',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cloud),
              ),
              items: const [
                DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI')),
                DropdownMenuItem(
                  value: 'Azure OpenAI',
                  child: Text('Azure OpenAI'),
                ),
                DropdownMenuItem(value: 'Ollama', child: Text('Ollama')),
                DropdownMenuItem(value: 'Custom', child: Text('自定义')),
              ],
              onChanged: onProviderChanged,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: baseUrlController,
              decoration: const InputDecoration(
                labelText: 'Base URL *',
                hintText: 'https://api.openai.com/v1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 Base URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: apiKeyController,
              decoration: const InputDecoration(
                labelText: 'API Key *',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入 API Key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: organizationController,
              decoration: const InputDecoration(
                labelText: '组织 ID (可选)',
                hintText: 'org-...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
