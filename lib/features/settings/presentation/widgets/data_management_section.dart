import 'package:flutter/material.dart';
import '../../../../core/services/log_service.dart';

/// 改进的数据管理区域
class ImprovedDataManagementSection extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onExportPdf;
  final VoidCallback onImportData;
  final VoidCallback onClearData;
  final bool isExporting;
  final bool isImporting;

  const ImprovedDataManagementSection({
    super.key,
    required this.onExportData,
    required this.onExportPdf,
    required this.onImportData,
    required this.onClearData,
    this.isExporting = false,
    this.isImporting = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final log = LogService();

    return Column(
      children: [
        _buildInfoBanner(context),
        const SizedBox(height: 8),
        _buildActionTile(
          context: context,
          icon: Icons.download_outlined,
          iconColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer,
          title: '导出数据',
          subtitle: '导出所有对话和配置',
          isLoading: isExporting,
          onTap: isExporting
              ? null
              : () {
                  log.info('用户点击导出数据');
                  onExportData();
                },
        ),
        _buildActionTile(
          context: context,
          icon: Icons.picture_as_pdf_outlined,
          iconColor: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer,
          title: '导出为 PDF',
          subtitle: '将对话导出为 PDF 文件',
          onTap: () {
            log.info('用户点击导出PDF');
            onExportPdf();
          },
        ),
        _buildActionTile(
          context: context,
          icon: Icons.upload_outlined,
          iconColor: colorScheme.tertiary,
          backgroundColor: colorScheme.tertiaryContainer,
          title: '导入数据',
          subtitle: '从文件恢复数据',
          isLoading: isImporting,
          onTap: isImporting
              ? null
              : () {
                  log.info('用户点击导入数据');
                  onImportData();
                },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 32),
        ),
        _buildDangerTile(
          context: context,
          icon: Icons.delete_outline,
          title: '清除所有数据',
          subtitle: '警告：此操作不可恢复',
          onTap: () {
            log.warning('用户点击清除数据');
            onClearData();
          },
        ),
      ],
    );
  }

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '导出的数据包含所有对话、配置和设置',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        enabled: onTap != null && !isLoading,
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildDangerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.errorContainer,
          child: Icon(icon, color: colorScheme.error),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.error,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colorScheme.error.withOpacity(0.7)),
        ),
        trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.error),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
