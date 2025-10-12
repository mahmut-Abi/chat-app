import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppShortcuts {
  static Map<ShortcutActivator, Intent> get shortcuts => {
    // 新建对话
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): const NewConversationIntent(),
    // 搜索
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): const SearchIntent(),
    // 设置
    const SingleActivator(LogicalKeyboardKey.comma, control: true): const SettingsIntent(),
    // 发送消息
    const SingleActivator(LogicalKeyboardKey.enter, control: true): const SendMessageIntent(),
    // 关闭当前对话
    const SingleActivator(LogicalKeyboardKey.keyW, control: true): const CloseConversationIntent(),
  };

  static Map<Type, Action<Intent>> get actions => {
    NewConversationIntent: CallbackAction<NewConversationIntent>(
      onInvoke: (intent) => intent.callback?.call(),
    ),
    SearchIntent: CallbackAction<SearchIntent>(
      onInvoke: (intent) => intent.callback?.call(),
    ),
    SettingsIntent: CallbackAction<SettingsIntent>(
      onInvoke: (intent) => intent.callback?.call(),
    ),
    SendMessageIntent: CallbackAction<SendMessageIntent>(
      onInvoke: (intent) => intent.callback?.call(),
    ),
    CloseConversationIntent: CallbackAction<CloseConversationIntent>(
      onInvoke: (intent) => intent.callback?.call(),
    ),
  };
}

class NewConversationIntent extends Intent {
  final VoidCallback? callback;
  const NewConversationIntent({this.callback});
}

class SearchIntent extends Intent {
  final VoidCallback? callback;
  const SearchIntent({this.callback});
}

class SettingsIntent extends Intent {
  final VoidCallback? callback;
  const SettingsIntent({this.callback});
}

class SendMessageIntent extends Intent {
  final VoidCallback? callback;
  const SendMessageIntent({this.callback});
}

class CloseConversationIntent extends Intent {
  final VoidCallback? callback;
  const CloseConversationIntent({this.callback});
}
