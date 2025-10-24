/// 整合化的帮助工具模块
/// 
/// 这个模块提供了一系列统一的帮助器类，用于减少项目中的重复代码。
///
/// 主要模块：
/// - **DialogHelper**: 统一管理各種类型的对话框
/// - **FormHelper**: 标准化表单组件构建
/// - **SettingsService**: 统一管理应用设置
/// - **ErrorHandler**: 统一的错误处理
///
/// 使用示例：
/// ```dart
/// // 使用 DialogHelper 显示对话框
/// final result = await DialogHelper.showConfirmDialog(
///   context: context,
///   title: '确认',
///   message: '确定执行此操作？',
/// );
///
/// // 使用 FormHelper 构建表单
/// Widget buttons = FormHelper.buildActionButtons(
///   onCancel: () => Navigator.pop(context),
///   onSave: _save,
/// );
///
/// // 使用 SettingsService 更新设置
/// final service = SettingsService(ref, context);
/// await service.updateAppSettings((s) => s.copyWith(fontSize: 14.0));
/// ```
library consolidated_helpers;

export 'dialog_helper.dart';
export 'form_helper.dart';
