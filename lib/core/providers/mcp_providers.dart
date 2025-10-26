import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/mcp/data/mcp_repository.dart';
import '../../features/mcp/domain/mcp_config.dart';
import 'storage_providers.dart';

/// MCP Providers
/// MCP server and resources related

// ============ MCP Repository ============

/// MCP Repository Provider
final mcpRepositoryProvider = Provider<McpRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return McpRepository(storage);
});

// ============ MCP Configurations ============

/// All MCP Configurations Provider
final mcpConfigsProvider = FutureProvider.autoDispose<List<McpConfig>>((ref) async {
  final repository = ref.watch(mcpRepositoryProvider);
  return await repository.getAllConfigs();
});

/// MCP Connection Status Provider
final mcpConnectionStatusProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, configId) async {
      final repository = ref.watch(mcpRepositoryProvider);
      final status = repository.getConnectionStatus(configId);
      if (status == null) return null;
      return {'connected': true, 'status': status.toString()};
    });

/// MCP Client Provider
final mcpClientProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, configId) async {
  final repository = ref.watch(mcpRepositoryProvider);
  final client = repository.getClient(configId);
  if (client == null) return null;
  return {'connected': true, 'type': client.runtimeType.toString()};
});

/// MCP Resources Provider
final mcpResourcesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, configId) async {
      try {
        // Return empty resources for now
        return {'resources': [], 'count': 0};
      } catch (e) {
        return {'error': e.toString(), 'count': 0};
      }
    });
