# MCP Platform Abstraction Layer

This directory contains platform-specific MCP (Model Context Protocol) client implementations and platform detection logic.

## Files

### Core Components
- **platform_config.dart** - Platform detection and capability queries
- **mcp_platform_adapter.dart** - Platform-aware MCP client factory
- **web_mcp_client.dart** - Web-optimized HTTP MCP client
- **mobile_mcp_client.dart** - Mobile-optimized HTTP MCP client

## Quick Start

### Detect Current Platform
```dart
import 'platform/platform_config.dart';

// Check platform
if (PlatformConfig.isWeb) {
  print('Running on Web');
} else if (PlatformConfig.isMobile) {
  print('Running on Mobile (iOS/Android)');
} else if (PlatformConfig.isDesktop) {
  print('Running on Desktop (Windows/macOS/Linux)');
}

// Get supported MCP modes
final modes = PlatformConfig.supportedMcpModes;
print('Supported modes: \$modes');
```

### Create Platform-Aware MCP Client
```dart
import 'platform/mcp_platform_adapter.dart';

final config = McpConfig(
  id: 'my-mcp',
  name: 'My MCP Server',
  connectionType: McpConnectionType.http,
  endpoint: 'https://mcp.example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// Automatically selects best client for current platform
final client = McpPlatformAdapter.createClientForPlatform(config);
final success = await client.connect();
```

### Validate Configuration
```dart
// Check if configuration is compatible with current platform
if (!McpPlatformAdapter.isConfigCompatibleWithPlatform(config)) {
  print('Configuration not supported on this platform');
  
  // Get supported types
  final types = McpPlatformAdapter.getSupportedConnectionTypes();
  print('Supported types: \$types');
}
```

## Platform-Specific Behavior

### Web (WebMcpClient)
- Uses HTTP only (Stdio not supported)
- CORS-aware implementation
- Auto-reconnect with max 5 attempts
- 30-second health check interval
- 10-second connection timeout
- Good for remote MCP servers

### Mobile (MobileMcpClient)
- Uses HTTP only (Stdio not supported)
- Battery-optimized health checks (60 seconds)
- 8-second connection timeout
- Connection loss detection
- Quick failure recovery
- Suitable for WiFi and cellular

### Desktop (HttpMcpClient/StdioMcpClient)
- Supports HTTP, Stdio, and WebSocket
- Can spawn local processes (Stdio)
- 30-second health check interval
- 30-second connection timeout
- Full feature support

## Timeout Configuration

```dart
// Get platform-specific defaults
final timeout = PlatformConfig.defaultTimeoutMs;  // 15000ms for mobile, 30000ms for others
final maxConnections = PlatformConfig.maxConcurrentConnections;  // 3 for web, 10 for others
```

## Error Handling Example

```dart
try {
  final client = McpPlatformAdapter.createClientForPlatform(config);
  final success = await client.connect();
  
  if (!success) {
    print('Connection failed: \${client.lastError}');
    
    // Check platform for guidance
    if (PlatformConfig.isWeb) {
      print('Tip: Make sure the server supports CORS');
    } else if (PlatformConfig.isMobile) {
      print('Tip: Check your WiFi or network connection');
    } else if (PlatformConfig.isDesktop) {
      print('Tip: Check if the process or server is running');
    }
  }
} catch (e) {
  print('Error: \$e');
}
```

## Platform Detection Matrix

| Property | Web | iOS | Android | Windows | macOS | Linux |
|----------|-----|-----|---------|---------|-------|-------|
| isMobile | No | Yes | Yes | No | No | No |
| isDesktop | No | No | No | Yes | Yes | Yes |
| isWeb | Yes | No | No | No | No | No |
| supportsStdioMode | No | No | No | Yes | Yes | Yes |
| supportsHttpMode | Yes | Yes | Yes | Yes | Yes | Yes |
| supportedMcpModes | http, ws | http, ws | http, ws | http, stdio, ws | http, stdio, ws | http, stdio, ws |

## Implementation Notes

1. **Platform Detection**: Uses Flutter's `kIsWeb` and `Platform` class
2. **Fallbacks**: Web/Mobile automatically fall back to HTTP for unsupported configs
3. **Timeouts**: Adjusted per platform to optimize for network conditions
4. **Health Checks**: Mobile uses longer intervals to conserve battery
5. **Reconnection**: Web retries up to 5 times with exponential backoff

## Adding Support for New Platforms

To add a new platform:

1. Add platform type to `PlatformType` enum
2. Add detection logic to `PlatformConfig.currentPlatform`
3. Add capabilities to `PlatformConfig` getters
4. Create platform-specific client if needed (extends `McpClientBase`)
5. Add case to `McpPlatformAdapter.createClientForPlatform()`

## Testing

Test platform detection:
```dart
test('Platform detection', () {
  expect(PlatformConfig.currentPlatform != PlatformType.unknown, true);
  expect(PlatformConfig.isMobile || PlatformConfig.isDesktop || PlatformConfig.isWeb, true);
});

test('MCP platform adapter', () {
  final config = McpConfig(
    id: 'test',
    name: 'Test',
    connectionType: McpConnectionType.http,
    endpoint: 'http://localhost:3000',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final client = McpPlatformAdapter.createClientForPlatform(config);
  expect(client, isNotNull);
  expect(McpPlatformAdapter.isConfigCompatibleWithPlatform(config), true);
});
```

## References

- Flutter Platform Detection: https://docs.flutter.dev/testing/platform-specific-behaviors
- Dart Platform Class: https://api.dart.dev/stable/latest/dart-io/Platform-class.html
- Model Context Protocol: https://modelcontextprotocol.io/
