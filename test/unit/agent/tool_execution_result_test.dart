import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/features/agent/domain/agent_tool.dart';

void main() {
  group('ToolExecutionResult Tests', () {
    group('Success Results', () {
      test('should create successful result', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Calculation completed',
          error: null,
          metadata: {
            'duration_ms': 100,
            'execution_time': '2025-01-20T10:00:00Z',
          },
        );

        expect(result.success, true);
        expect(result.result, 'Calculation completed');
        expect(result.error, null);
        expect(result.metadata, isNotNull);
      });

      test('should handle empty result', () {
        final result = ToolExecutionResult(
          success: true,
          result: '',
          error: null,
        );

        expect(result.success, true);
        expect(result.result, '');
      });

      test('should store metadata', () {
        final metadata = {
          'tool_name': 'calculator',
          'operation': 'addition',
          'operands': [2, 3],
          'result': 5,
        };

        final result = ToolExecutionResult(
          success: true,
          result: '5',
          metadata: metadata,
        );

        expect(result.metadata?['tool_name'], 'calculator');
        expect(result.metadata?['operands'], [2, 3]);
      });
    });

    group('Error Results', () {
      test('should create failed result with error', () {
        final result = ToolExecutionResult(
          success: false,
          result: null,
          error: 'Invalid expression',
          metadata: {'error_code': 'INVALID_SYNTAX'},
        );

        expect(result.success, false);
        expect(result.error, 'Invalid expression');
        expect(result.result, null);
      });

      test('should handle error with detailed metadata', () {
        final errorMetadata = {
          'error_type': 'SyntaxError',
          'error_line': 5,
          'error_column': 12,
          'suggestion': 'Check parentheses',
        };

        final result = ToolExecutionResult(
          success: false,
          error: 'Syntax error at line 5',
          metadata: errorMetadata,
        );

        expect(result.success, false);
        expect(result.metadata?['error_type'], 'SyntaxError');
        expect(result.metadata?['suggestion'], isNotNull);
      });
    });

    group('Metadata Handling', () {
      test('should store complex metadata', () {
        final metadata = {
          'execution_stats': {
            'duration_ms': 250,
            'cpu_usage': 15.5,
            'memory_kb': 512,
          },
          'tool_version': '1.2.0',
          'cache_hit': true,
        };

        final result = ToolExecutionResult(
          success: true,
          result: 'Done',
          metadata: metadata,
        );

        expect(result.metadata?['tool_version'], '1.2.0');
        expect(result.metadata?['cache_hit'], true);
      });

      test('should handle null metadata', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Done',
          metadata: null,
        );

        expect(result.metadata, null);
      });

      test('should handle empty metadata', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Done',
          metadata: {},
        );

        expect(result.metadata, isEmpty);
      });
    });

    group('Result Validation', () {
      test('should validate success with result', () {
        final result = ToolExecutionResult(
          success: true,
          result: 'Success message',
        );

        expect(result.success, true);
        expect(result.result != null, true);
      });

      test('should validate failure with error', () {
        final result = ToolExecutionResult(
          success: false,
          error: 'Tool failed',
        );

        expect(result.success, false);
        expect(result.error != null, true);
      });

      test('should handle edge case: success without result', () {
        final result = ToolExecutionResult(
          success: true,
          result: null,
        );

        expect(result.success, true);
        expect(result.result, null);
      });
    });

    group('Large Result Handling', () {
      test('should handle large text result', () {
        final largeText = 'A' * 10000; // 10KB text
        final result = ToolExecutionResult(
          success: true,
          result: largeText,
        );

        expect(result.result?.length, 10000);
      });

      test('should handle large metadata', () {
        final largeMetadata = <String, dynamic>{};
        for (int i = 0; i < 1000; i++) {
          largeMetadata['key_$i'] = 'value_$i';
        }

        final result = ToolExecutionResult(
          success: true,
          result: 'Done',
          metadata: largeMetadata,
        );

        expect(result.metadata?.length, 1000);
      });
    });
  });
}
