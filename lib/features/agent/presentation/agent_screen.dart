import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/agent_tab.dart';
import 'widgets/tools_tab.dart';
import '../../../shared/widgets/background_container.dart';

/// Agent 管理界面
class AgentScreen extends ConsumerWidget {
  const AgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Agent 管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agent', icon: Icon(Icons.smart_toy)),
              Tab(text: '工具', icon: Icon(Icons.build)),
            ],
          ),
        ),
        body: const BackgroundContainer(
          child: TabBarView(children: [AgentTab(), ToolsTab()]),
        ),
      ),
    );
  }
}
