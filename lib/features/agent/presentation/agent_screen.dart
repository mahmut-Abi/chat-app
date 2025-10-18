import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/agent_tab.dart';
import 'widgets/tools_tab.dart';

/// Agent 管理界面
class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Agent 管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agent', icon: Icon(Icons.smart_toy)),
              Tab(text: '工具', icon: Icon(Icons.build)),
            ],
          ),
      ),
      body: const TabBarView(children: [AgentTab(), ToolsTab()]),
      ),
    );
  }
}
