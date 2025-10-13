import '../../domain/agent_tool.dart';
import '../tool_executor.dart';
import 'package:expressions/expressions.dart';

/// 计算器工具增强实现
class EnhancedCalculatorTool extends ToolExecutor {
  @override
  AgentToolType get type => AgentToolType.calculator;

  @override
  Future<ToolExecutionResult> execute(
    AgentTool tool,
    Map<String, dynamic> input,
  ) async {
    try {
      final expression = input['expression'] as String?;
      if (expression == null || expression.isEmpty) {
        return ToolExecutionResult(
          success: false,
          error: '缺少表达式参数',
        );
      }

      // 使用 expressions 包进行安全的表达式计算
      final result = _evaluateExpression(expression);
      
      return ToolExecutionResult(
        success: true,
        result: '计算结果:\n$expression = $result',
        metadata: {
          'expression': expression,
          'result': result,
        },
      );
    } catch (e) {
      return ToolExecutionResult(
        success: false,
        error: '计算错误: $e',
      );
    }
  }
  
  /// 评估数学表达式
  dynamic _evaluateExpression(String expression) {
    try {
      // 移除空格
      final cleanExpr = expression.replaceAll(' ', '');
      
      // 解析表达式
      final expr = Expression.parse(cleanExpr);
      
      // 计算结果
      const evaluator = ExpressionEvaluator();
      final result = evaluator.eval(expr, {});
      
      return result;
    } catch (e) {
      // 如果 expressions 包不可用，使用基础计算
      return _basicCalculate(expression);
    }
  }
  
  /// 基础计算器（备用）
  double _basicCalculate(String expression) {
    // 简单的计算器实现
    // 只支持基本运算
    final cleanExpr = expression.replaceAll(' ', '');
    
    // 这里只是示例，实际应该使用更安全的解析器
    if (cleanExpr.contains('+')) {
      final parts = cleanExpr.split('+');
      return double.parse(parts[0]) + double.parse(parts[1]);
    } else if (cleanExpr.contains('-')) {
      final parts = cleanExpr.split('-');
      return double.parse(parts[0]) - double.parse(parts[1]);
    } else if (cleanExpr.contains('*')) {
      final parts = cleanExpr.split('*');
      return double.parse(parts[0]) * double.parse(parts[1]);
    } else if (cleanExpr.contains('/')) {
      final parts = cleanExpr.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    } else {
      return double.parse(cleanExpr);
    }
  }
}
