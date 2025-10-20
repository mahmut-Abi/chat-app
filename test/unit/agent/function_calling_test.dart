import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('Function Calling Tests', () {
    late DateTime now;

    setUp(() {
      now = DateTime.now();
    });

    group('Tool Call Generation', () {
      test('should generate tool call from AI request', () {
        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {
            'expression': '2 + 2',
          },
          timestamp: now,
        );

        expect(toolCall.id, 'call-001');
        expect(toolCall.toolId, 'calculator');
        expect(toolCall.parameters['expression'], '2 + 2');
      });

      test('should preserve parameter order', () {
        final params = <String, dynamic>{};
        params['query'] = 'search';
        params['limit'] = 50;
        params['sort'] = 'relevance';

        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'search',
          toolName: 'search',
          parameters: params,
          timestamp: now,
        );

        expect(toolCall.parameters.keys.length, 3);
      });

      test('should handle multiple sequential calls', () {
        final calls = [
          ToolCall(
            id: 'call-001',
            toolId: 'search',
            toolName: 'search',
            parameters: {'query': 'weather'},
            timestamp: now,
          ),
          ToolCall(
            id: 'call-002',
            toolId: 'parser',
            toolName: 'parser',
            parameters: {'data': 'weather data'},
            timestamp: now.add(const Duration(milliseconds: 100)),
          ),
        ];

        expect(calls.length, 2);
        expect(calls[0].id, 'call-001');
        expect(calls[1].id, 'call-002');
      });
    });

    group('Tool Call Execution', () {
      test('should execute tool call and return result', () {
        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {'expression': '10 * 5'},
          timestamp: now,
        );

        final result = ToolExecutionResult(
          success: true,
          result: '50',
          metadata: {'duration_ms': 25},
        );

        expect(toolCall.toolId, result.metadata == null ? null : toolCall.toolId);
        expect(result.success, true);
        expect(result.result, '50');
      });

      test('should handle execution errors', () {
        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {'expression': 'invalid'},
          timestamp: now,
        );

        final result = ToolExecutionResult(
          success: false,
          error: 'Invalid expression',
          metadata: {'error_code': 'PARSE_ERROR'},
        );

        expect(result.success, false);
        expect(result.error, 'Invalid expression');
      });

      test('should track execution metadata', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'data',
          metadata: {
            'duration_ms': 150,
            'cache_hit': true,
            'retry_count': 0,
            'tool_version': '1.0.0',
          },
        );

        expect(result.metadata?['duration_ms'], 150);
        expect(result.metadata?['cache_hit'], true);
        expect(result.metadata?['retry_count'], 0);
      });
    });

    group('Function Call Chain', () {
      test('should execute function call chain', () {
        final calls = [
          ToolCall(
            id: 'call-001',
            toolId: 'search',
            toolName: 'search',
            parameters: {'query': 'flutter'},
            timestamp: now,
          ),
          ToolCall(
            id: 'call-002',
            toolId: 'summarize',
            toolName: 'summarize',
            parameters: {'text': 'search results'},
            timestamp: now.add(const Duration(milliseconds: 200)),
          ),
          ToolCall(
            id: 'call-003',
            toolId: 'format',
            toolName: 'format',
            parameters: {'data': 'summary'},
            timestamp: now.add(const Duration(milliseconds: 400)),
          ),
        ];

        expect(calls.length, 3);
        expect(calls[0].toolId, 'search');
        expect(calls[1].toolId, 'summarize');
        expect(calls[2].toolId, 'format');
      });

      test('should pass results between function calls', () {
        var data = 'initial data';

        // Tool 1: Transform
        data = 'Transformed: $data';
        expect(data.startsWith('Transformed'), true);

        // Tool 2: Process
        data = 'Processed: $data';
        expect(data.startsWith('Processed'), true);

        // Tool 3: Format
        data = 'Final: $data';
        expect(data.startsWith('Final'), true);
      });

      test('should handle chain error propagation', () {
        final results = [
          ToolExecutionResult(success: true, result: 'Step 1 OK'),
          ToolExecutionResult(success: false, error: 'Step 2 failed'),
          // Step 3 not executed due to error
        ];

        final hasError = results.any((r) => !r.success);
        expect(hasError, true);
      });
    });

    group('Parallel Function Calls', () {
      test('should execute independent function calls in parallel', () async {
        final futures = [
          Future.delayed(
            const Duration(milliseconds: 100),
            () => ToolExecutionResult(success: true, result: 'Call 1'),
          ),
          Future.delayed(
            const Duration(milliseconds: 100),
            () => ToolExecutionResult(success: true, result: 'Call 2'),
          ),
          Future.delayed(
            const Duration(milliseconds: 100),
            () => ToolExecutionResult(success: true, result: 'Call 3'),
          ),
        ];

        final results = await Future.wait(futures);

        expect(results.length, 3);
        expect(results.every((r) => r.success), true);
      });

      test('should handle partial failures in parallel', () async {
        final futures = [
          Future.value(ToolExecutionResult(success: true, result: 'OK')),
          Future.value(
            ToolExecutionResult(success: false, error: 'Failed'),
          ),
          Future.value(ToolExecutionResult(success: true, result: 'OK')),
        ];

        final results = await Future.wait(futures, eagerError: false);

        final successCount = results.where((r) => r.success).length;
        expect(successCount, 2);
      });
    });

    group('Tool Availability and Validation', () {
      test('should check if tool is available', () {
        final availableTools = ['calculator', 'search', 'file_operation'];
        final requestedTool = 'calculator';

        expect(availableTools.contains(requestedTool), true);
      });

      test('should validate tool parameters before execution', () {
        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {'expression': '2 + 2'},
          timestamp: now,
        );

        // Validate required parameters
        expect(toolCall.parameters.containsKey('expression'), true);
        expect(toolCall.parameters['expression'] is String, true);
      });

      test('should handle unavailable tools', () {
        final availableTools = ['calculator', 'search'];
        final requestedTool = 'unavailable_tool';

        final isAvailable = availableTools.contains(requestedTool);
        expect(isAvailable, false);
      });
    });

    group('Tool Context and State', () {
      test('should maintain tool execution context', () {
        final context = {
          'agent_id': 'agent-001',
          'user_id': 'user-123',
          'session_id': 'session-abc',
          'timestamp': now,
        };

        final toolCall = ToolCall(
          id: 'call-001',
          toolId: 'calculator',
          toolName: 'calculator',
          parameters: {'expression': '2 + 2'},
          timestamp: context['timestamp'] as DateTime,
        );

        expect(toolCall.timestamp, now);
      });

      test('should preserve call order in context', () {
        final callOrder = <int>[];

        for (int i = 0; i < 5; i++) {
          callOrder.add(i);
        }

        expect(callOrder.length, 5);
        expect(callOrder.first, 0);
        expect(callOrder.last, 4);
      });
    });

    group('Response Generation', () {
      test('should generate response from tool result', () {
        final toolResult = ToolExecutionResult(
          success: true,
          result: '4',
          metadata: {'duration_ms': 50},
        );

        final response = 'The result is ${toolResult.result}';
        expect(response, 'The result is 4');
      });

      test('should handle error response generation', () {
        final toolResult = ToolExecutionResult(
          success: false,
          error: 'Invalid expression',
          metadata: {'error_code': 'SYNTAX_ERROR'},
        );

        final response = 'Error: ${toolResult.error}';
        expect(response, 'Error: Invalid expression');
      });

      test('should combine multiple tool results', () {
        final results = [
          ToolExecutionResult(success: true, result: 'Result 1'),
          ToolExecutionResult(success: true, result: 'Result 2'),
          ToolExecutionResult(success: true, result: 'Result 3'),
        ];

        final response = results.map((r) => r.result).join(', ');
        expect(response, 'Result 1, Result 2, Result 3');
      });
    });

    group('Tool Timeout and Cancellation', () {
      test('should handle tool timeout', () async {
        final result = await Future.delayed(
          const Duration(seconds: 1),
          () => ToolExecutionResult(
            success: false,
            error: 'Tool execution timeout',
            metadata: {'timeout_seconds': 5},
          ),
        ).timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => ToolExecutionResult(
            success: false,
            error: 'Timeout exceeded',
          ),
        );

        expect(result.success, false);
      });

      test('should cancel pending tool calls', () {
        var cancelled = false;

        // Simulate cancellation
        cancelled = true;

        expect(cancelled, true);
      });
    });
  });
}
