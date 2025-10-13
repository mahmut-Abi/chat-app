import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/mcp_config.dart';
import 'mcp_client_base.dart';
import 'package:flutter/foundation.dart';

/// Stdio 模式的 MCP 客户端
/// 通过启动外部进程并通过 stdin/stdout 通信
class StdioMcpClient extends McpClientBase {
  Process? _process;
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  int _requestId = 0;

  StdioMcpClient({required super.config});

  @override
  Future<bool> connect() async {
    try {
      status = McpConnectionStatus.connecting;

      if (kDebugMode) {
        print('StdioMcpClient: 启动进程 ${config.endpoint}');
      }

      // 启动外部进程
      _process = await Process.start(
        config.endpoint,
        config.args ?? [],
        environment: config.env,
        runInShell: true,
      );

      // 监听 stdout
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleStdout,
            onError: (error) {
              if (kDebugMode) {
                print('StdioMcpClient stdout error: $error');
              }
              status = McpConnectionStatus.error;
            },
          );

      // 监听 stderr
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (kDebugMode) {
              print('StdioMcpClient stderr: $line');
            }
          });

      // 等待进程启动
      await Future.delayed(const Duration(milliseconds: 500));

      // 发送初始化请求
      final initialized = await _sendRequest('initialize', {
        'protocolVersion': '1.0',
        'capabilities': {},
      });

      if (initialized != null) {
        status = McpConnectionStatus.connected;
        return true;
      } else {
        status = McpConnectionStatus.error;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('StdioMcpClient connect error: $e');
      }
      status = McpConnectionStatus.error;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _process?.kill();
    _process = null;
    _pendingRequests.clear();
    status = McpConnectionStatus.disconnected;
  }

  @override
  Future<Map<String, dynamic>?> getContext(String contextId) async {
    return await _sendRequest('context/get', {'contextId': contextId});
  }

  @override
  Future<bool> pushContext(
    String contextId,
    Map<String, dynamic> context,
  ) async {
    final result = await _sendRequest('context/push', {
      'contextId': contextId,
      'context': context,
    });
    return result != null;
  }

  @override
  Future<Map<String, dynamic>?> callTool(
    String toolName,
    Map<String, dynamic> params,
  ) async {
    return await _sendRequest('tools/call', {
      'name': toolName,
      'arguments': params,
    });
  }

  @override
  Future<List<Map<String, dynamic>>?> listTools() async {
    final result = await _sendRequest('tools/list', {});
    if (result != null && result['tools'] is List) {
      return (result['tools'] as List).cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// 发送 JSON-RPC 请求
  Future<Map<String, dynamic>?> _sendRequest(
    String method,
    Map<String, dynamic> params,
  ) async {
    if (_process == null) {
      return null;
    }

    final id = _requestId++;
    final request = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id.toString()] = completer;

    try {
      final jsonStr = jsonEncode(request);
      _process!.stdin.writeln(jsonStr);
      await _process!.stdin.flush();

      // 超时 30 秒
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _pendingRequests.remove(id.toString());
          throw TimeoutException('Request timeout');
        },
      );
    } catch (e) {
      _pendingRequests.remove(id.toString());
      if (kDebugMode) {
        print('StdioMcpClient _sendRequest error: $e');
      }
      return null;
    }
  }

  /// 处理 stdout 输出
  void _handleStdout(String line) {
    if (line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line) as Map<String, dynamic>;

      // 处理响应
      if (json.containsKey('id')) {
        final id = json['id'].toString();
        final completer = _pendingRequests.remove(id);

        if (completer != null) {
          if (json.containsKey('result')) {
            completer.complete(json['result'] as Map<String, dynamic>);
          } else if (json.containsKey('error')) {
            completer.completeError(Exception(json['error']));
          }
        }
      }
      // 处理通知和事件
      else if (json.containsKey('method')) {
        if (kDebugMode) {
          print('StdioMcpClient notification: ${json['method']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('StdioMcpClient _handleStdout error: $e, line: $line');
      }
    }
  }

  @override
  void dispose() {
    disconnect();
  }
}
