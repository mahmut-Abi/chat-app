import 'package:flutter/material.dart';

class ApiConfigProxySection extends StatelessWidget {
  final bool enableProxy;
  final TextEditingController proxyUrlController;
  final TextEditingController proxyUsernameController;
  final TextEditingController proxyPasswordController;
  final Function(bool?) onProxyChanged;

  const ApiConfigProxySection({
    super.key,
    required this.enableProxy,
    required this.proxyUrlController,
    required this.proxyUsernameController,
    required this.proxyPasswordController,
    required this.onProxyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('代理配置', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Switch(value: enableProxy, onChanged: onProxyChanged),
              ],
            ),
            if (enableProxy) ..._buildProxyFields(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProxyFields() {
    return [
      const SizedBox(height: 16),
      TextFormField(
        controller: proxyUrlController,
        decoration: const InputDecoration(
          labelText: '代理地址',
          hintText: 'http://proxy.example.com:8080',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.dns),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: proxyUsernameController,
        decoration: const InputDecoration(
          labelText: '代理用户名 (可选)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: proxyPasswordController,
        decoration: const InputDecoration(
          labelText: '代理密码 (可选)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.lock),
        ),
        obscureText: true,
      ),
    ];
  }
}
