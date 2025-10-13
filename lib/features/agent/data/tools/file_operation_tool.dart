import 'dart:io';
import '../../domain/agent_tool.dart';
import '../tool_executor.dart';
import 'package:path/path.dart' as path;

/// 文件操作工具
class FileOperationTool extends ToolExecutor {
  @override
  AgentToolType get type => AgentToolType.fileOperation;

  @override
  Future<ToolExecutionResult> execute(
    AgentTool tool,
    Map<String, dynamic> input,
  ) async {
    final operation = input['operation'] as String?;
    final filePath = input['path'] as String?;

    if (operation == null || filePath == null) {
      return ToolExecutionResult(
        success: false,
        error: '缺少必要参数: operation 和 path',
      );
    }

    try {
      switch (operation.toLowerCase()) {
        case 'read':
          return await _readFile(filePath);
        case 'write':
          final content = input['content'] as String?;
          if (content == null) {
            return ToolExecutionResult(
              success: false,
              error: '写入操作需要 content 参数',
            );
          }
          return await _writeFile(filePath, content);
        case 'list':
          return await _listDirectory(filePath);
        case 'info':
          return await _getFileInfo(filePath);
        default:
          return ToolExecutionResult(
            success: false,
            error: '不支持的操作: $operation',
          );
      }
    } catch (e) {
      return ToolExecutionResult(success: false, error: '文件操作失败: $e');
    }
  }

  Future<ToolExecutionResult> _readFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ToolExecutionResult(success: false, error: '文件不存在: $filePath');
      }

      final content = await file.readAsString();
      return ToolExecutionResult(
        success: true,
        result: '文件内容 ($filePath):\n```\n$content\n```',
        metadata: {'path': filePath, 'size': content.length},
      );
    } catch (e) {
      return ToolExecutionResult(success: false, error: '读取文件失败: $e');
    }
  }

  Future<ToolExecutionResult> _writeFile(
    String filePath,
    String content,
  ) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);

      return ToolExecutionResult(
        success: true,
        result: '文件写入成功: $filePath',
        metadata: {'path': filePath, 'size': content.length},
      );
    } catch (e) {
      return ToolExecutionResult(success: false, error: '写入文件失败: $e');
    }
  }

  Future<ToolExecutionResult> _listDirectory(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        return ToolExecutionResult(success: false, error: '目录不存在: $dirPath');
      }

      final entities = await dir.list().toList();
      final buffer = StringBuffer('目录内容 ($dirPath):\n\n');

      for (final entity in entities) {
        final name = path.basename(entity.path);
        final type = entity is File ? '📄' : '📁';
        buffer.writeln('$type $name');
      }

      return ToolExecutionResult(
        success: true,
        result: buffer.toString(),
        metadata: {'path': dirPath, 'count': entities.length},
      );
    } catch (e) {
      return ToolExecutionResult(success: false, error: '列出目录失败: $e');
    }
  }

  Future<ToolExecutionResult> _getFileInfo(String filePath) async {
    try {
      final entity = FileSystemEntity.typeSync(filePath);

      if (entity == FileSystemEntityType.notFound) {
        return ToolExecutionResult(success: false, error: '文件不存在: $filePath');
      }

      final stat = await FileStat.stat(filePath);
      final buffer = StringBuffer('文件信息:\n\n');
      buffer.writeln('路径: $filePath');
      buffer.writeln('类型: ${entity.toString()}');
      buffer.writeln('大小: ${stat.size} bytes');
      buffer.writeln('修改时间: ${stat.modified}');
      buffer.writeln('访问时间: ${stat.accessed}');

      return ToolExecutionResult(
        success: true,
        result: buffer.toString(),
        metadata: {
          'path': filePath,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        },
      );
    } catch (e) {
      return ToolExecutionResult(success: false, error: '获取文件信息失败: $e');
    }
  }
}
