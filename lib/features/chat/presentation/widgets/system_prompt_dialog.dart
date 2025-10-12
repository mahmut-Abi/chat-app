import 'package:flutter/material.dart';

class SystemPromptDialog extends StatefulWidget {
  final String? initialPrompt;

  const SystemPromptDialog({super.key, this.initialPrompt});

  @override
  State<SystemPromptDialog> createState() => _SystemPromptDialogState();
}

class _SystemPromptDialogState extends State<SystemPromptDialog> {
  late TextEditingController _controller;
  final List<String> _presets = [
    '你是一个乐于助人的AI助手。',
    '你是一个专业的编程助手，擅长各种编程语言和框架。',
    '你是一个创意写作助手，擅长文案创作和内容策划。',
    '你是一个数据分析师，擅长解读和分析复杂数据。',
    '你是一个产品经理，擅长产品设计和用户研究。',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrompt ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('系统提示词'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '输入系统提示词...',
                helperText: '系统提示词将在每次对话中自动添加',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '常用预设',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((preset) {
                return ActionChip(
                  label: Text(
                    preset,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.text = preset;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _controller.clear();
          },
          child: const Text('清空'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
