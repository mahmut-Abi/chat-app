import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/mcp_config.dart';
import 'mcp_repository.dart';
import '../../../core/providers/providers.dart';

/// MCP 配置列表 Provider
final mcpConfigsProvider = FutureProvider<List<McpConfig>>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final repository = McpRepository(storage);
  return await repository.getAllConfigs();
});

/// MCP Repository Provider
final mcpRepositoryProvider = Provider<McpRepository>((ref) {
  final storage = ref.read(storageServiceProvider);
  return McpRepository(storage);
});

/// MCP 连接状态 Provider
final mcpConnectionStatusProvider =
    Provider.family<McpConnectionStatus, String>((ref, configId) {
      final repository = ref.watch(mcpRepositoryProvider);
      return repository.getConnectionStatus(configId) ??
          McpConnectionStatus.disconnected;
    });
