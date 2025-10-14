import 'package:flutter/material.dart';

/// 数据管理区域
class DataManagementSection extends StatelessWidget {
  final VoidCallback onExportData;
  final VoidCallback onExportPdf;
  final VoidCallback onImportData;
  final VoidCallback onClearData;
  final bool isExporting;
  final bool isImporting;

  const DataManagementSection({
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
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('导出数据'),
          subtitle: const Text('导出所有对话和配置'),
          trailing: isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isExporting ? null : onExportData,
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('导出为 PDF'),
          subtitle: const Text('将对话导出为 PDF 文件'),
          onTap: onExportPdf,
        ),
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('导入数据'),
          subtitle: const Text('从文件恢复数据'),
          trailing: isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: isImporting ? null : onImportData,
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
          onTap: onClearData,
        ),
      ],
    );
  }
}
