import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/features/chat/presentation/widgets/tool_execution_widget.dart';

void main() {
  group('ToolExecutionWidget Tests', () {
    testWidgets('renders tool execution results', (WidgetTester tester) async {
      // Arrange
      final toolResults = [
        {
          'success': true,
          'result': 'Execution result',
          'metadata': {'duration': '100ms'},
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolExecutionWidget(
              toolResults: toolResults,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Tool Execution (1)'), findsOneWidget);
      expect(find.byIcon(Icons.build_circle_outlined), findsOneWidget);
    });

    testWidgets('displays error results', (WidgetTester tester) async {
      // Arrange
      final toolResults = [
        {
          'success': false,
          'error': 'Tool execution failed',
          'metadata': {},
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolExecutionWidget(
              toolResults: toolResults,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Tool Execution (1)'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('expands and collapses results', (WidgetTester tester) async {
      // Arrange
      final toolResults = [
        {
          'success': true,
          'result': 'Test result',
          'metadata': {},
        },
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolExecutionWidget(
              toolResults: toolResults,
            ),
          ),
        ),
      );

      // Find and tap the expand button
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - after expanding, we should see more content
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
    });
  });
}
