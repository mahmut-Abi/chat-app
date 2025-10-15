import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/glass_container.dart';

class SidebarFooter extends StatelessWidget {
  const SidebarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '功能',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.2,
              children: [
                _buildFeatureCard(
                  context,
                  icon: Icons.memory,
                  label: '模型',
                  onTap: () => context.push('/models'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.lightbulb,
                  label: '提示词',
                  onTap: () => context.push('/prompts'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.smart_toy,
                  label: '智能体',
                  onTap: () => context.push('/agent'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.extension,
                  label: 'MCP',
                  onTap: () => context.push('/mcp'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.access_time,
                  label: 'Token',
                  onTap: () => context.push('/token-usage'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.article,
                  label: '日志',
                  onTap: () => context.push('/logs'),
                ),
                _buildFeatureCard(
                  context,
                  icon: Icons.settings,
                  label: '设置',
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      blur: 10.0,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(8),
      enableShadow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
