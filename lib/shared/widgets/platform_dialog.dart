import 'dart:io';
 import '../../core/utils/platform_utils.dart';
 import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 根据平台自动选择 Material 或 Cupertino 风格的 Dialog
class PlatformDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? content;
  final Widget? contentWidget;
  final List<PlatformDialogAction> actions;
  final Widget? icon;

  const PlatformDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.content,
    this.contentWidget,
    this.actions = const [],
    this.icon,
  }) : assert(
         (title != null || titleWidget != null),
         'Either title or titleWidget must be provided',
       ),
       assert(
         (content != null || contentWidget != null),
         'Either content or contentWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
   if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
      return _buildCupertinoDialog(context);
    }
    return _buildMaterialDialog(context);
  }

  Widget _buildCupertinoDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: actions
          .map((action) => action.toCupertinoAction(context))
          .toList(),
    );
  }

  Widget _buildMaterialDialog(BuildContext context) {
    return AlertDialog(
      icon: icon,
      title: titleWidget ?? (title != null ? Text(title!) : null),
      content: contentWidget ?? (content != null ? Text(content!) : null),
      actions: actions
          .map((action) => action.toMaterialAction(context))
          .toList(),
    );
  }
}

/// Dialog 按钮配置
class PlatformDialogAction {
  final String text;
  final VoidCallback onPressed;
  final bool isDefaultAction;
  final bool isDestructiveAction;

  const PlatformDialogAction({
    required this.text,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  Widget toCupertinoAction(BuildContext context) {
    return CupertinoDialogAction(
      isDefaultAction: isDefaultAction,
      isDestructiveAction: isDestructiveAction,
      onPressed: onPressed,
      child: Text(text),
    );
  }

  Widget toMaterialAction(BuildContext context) {
    if (isDestructiveAction) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text(text),
      );
    }
    if (isDefaultAction) {
      return FilledButton(onPressed: onPressed, child: Text(text));
    }
    return TextButton(onPressed: onPressed, child: Text(text));
  }
}

/// 显示平台风格的对话框
Future<T?> showPlatformDialog<T>({
  required BuildContext context,
  required Widget dialog,
  bool barrierDismissible = true,
}) {
  if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => dialog,
    );
  }
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => dialog,
  );
}

/// 显示平台风格的确认对话框
Future<bool> showPlatformConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = '确定',
  String cancelText = '取消',
  bool isDestructive = false,
}) async {
  final result = await showPlatformDialog<bool>(
    context: context,
    dialog: PlatformDialog(
      title: title,
      content: content,
      actions: [
        PlatformDialogAction(
          text: cancelText,
          onPressed: () => Navigator.pop(context, false),
        ),
        PlatformDialogAction(
          text: confirmText,
          onPressed: () => Navigator.pop(context, true),
          isDefaultAction: true,
          isDestructiveAction: isDestructive,
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 显示平台风格的输入对话框
Future<String?> showPlatformInputDialog({
  required BuildContext context,
  required String title,
  String? content,
  String? initialValue,
  String? placeholder,
  String confirmText = '确定',
  String cancelText = '取消',
  int? maxLength,
  TextInputType? keyboardType,
}) async {
  final controller = TextEditingController(text: initialValue);

  if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
    return showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Column(
          children: [
            if (content != null) ...[
              const SizedBox(height: 8),
              Text(content),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLength: maxLength,
              keyboardType: keyboardType,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: placeholder,
          border: const OutlineInputBorder(),
        ),
        maxLength: maxLength,
        keyboardType: keyboardType,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// 显示平台风格的选择对话框
Future<T?> showPlatformActionSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required List<PlatformSheetAction<T>> actions,
  String cancelText = '取消',
}) async {
  if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
    return showCupertinoModalPopup<T>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title != null ? Text(title) : null,
        message: message != null ? Text(message) : null,
        actions: actions
            .map(
              (action) => CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(context, action.value),
                isDestructiveAction: action.isDestructive,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (action.icon != null) ...[
                      Icon(
                        action.icon,
                        size: 20,
                        color: action.isDestructive
                            ? CupertinoColors.systemRed
                            : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(action.text),
                  ],
                ),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(cancelText),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || message != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (title != null)
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ...actions.map(
          (action) => ListTile(
            leading: action.icon != null
                ? Icon(
                    action.icon,
                    color: action.isDestructive
                        ? Theme.of(context).colorScheme.error
                        : null,
                  )
                : null,
            title: Text(
              action.text,
              style: TextStyle(
                color: action.isDestructive
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
            onTap: () => Navigator.pop(context, action.value),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          title: Text(
            cancelText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// ActionSheet 选项
class PlatformSheetAction<T> {
  final String text;
  final T value;
  final IconData? icon;
  final bool isDestructive;

  const PlatformSheetAction({
    required this.text,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });
}

/// 显示平台风格的加载对话框
Future<void> showPlatformLoadingDialog({
  required BuildContext context,
  String message = '加载中...',
}) {
  if (PlatformUtils.isIOS || PlatformUtils.isMacOS) {
    return showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Text(message),
        ],
      ),
    ),
  );
}
