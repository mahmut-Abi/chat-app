import 'package:flutter/material.dart';
import '../../domain/conversation.dart';

class ModelConfigDialog extends StatefulWidget {
  final ModelConfig initialConfig;

  const ModelConfigDialog({super.key, required this.initialConfig});

  @override
  State<ModelConfigDialog> createState() => _ModelConfigDialogState();
}

class _ModelConfigDialogState extends State<ModelConfigDialog> {
  late TextEditingController _modelController;
  late double _temperature;
  late int _maxTokens;
  late double _topP;
  late double _frequencyPenalty;
  late double _presencePenalty;

  @override
  void initState() {
    super.initState();
    _modelController = TextEditingController(text: widget.initialConfig.model);
    _temperature = widget.initialConfig.temperature;
    _maxTokens = widget.initialConfig.maxTokens;
    _topP = widget.initialConfig.topP;
    _frequencyPenalty = widget.initialConfig.frequencyPenalty;
    _presencePenalty = widget.initialConfig.presencePenalty;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('模型参数配置'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: '模型名称',
                  border: OutlineInputBorder(),
                  helperText: '例如: gpt-4, gpt-3.5-turbo',
                ),
              ),
              const SizedBox(height: 24),
              _buildSlider(
                label: 'Temperature',
                value: _temperature,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) => setState(() => _temperature = value),
                helperText: '控制响应的随机性 (0-2)',
              ),
              const SizedBox(height: 24),
              _buildNumberField(
                label: 'Max Tokens',
                value: _maxTokens,
                onChanged: (value) => setState(() => _maxTokens = value),
                helperText: '生成的最大令牌数',
              ),
              const SizedBox(height: 24),
              _buildSlider(
                label: 'Top P',
                value: _topP,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => setState(() => _topP = value),
                helperText: '核采样参数 (0-1)',
              ),
              const SizedBox(height: 24),
              _buildSlider(
                label: 'Frequency Penalty',
                value: _frequencyPenalty,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) => setState(() => _frequencyPenalty = value),
                helperText: '降低重复词汇的惩罚 (0-2)',
              ),
              const SizedBox(height: 24),
              _buildSlider(
                label: 'Presence Penalty',
                value: _presencePenalty,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                onChanged: (value) => setState(() => _presencePenalty = value),
                helperText: '鼓励新话题的惩罚 (0-2)',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final config = ModelConfig(
              model: _modelController.text,
              temperature: _temperature,
              maxTokens: _maxTokens,
              topP: _topP,
              frequencyPenalty: _frequencyPenalty,
              presencePenalty: _presencePenalty,
            );
            Navigator.pop(context, config);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Text(
              value.toStringAsFixed(2),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
        if (helperText != null)
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    String? helperText,
  }) {
    final controller = TextEditingController(text: value.toString());
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: helperText,
      ),
      keyboardType: TextInputType.number,
      controller: controller,
      onChanged: (text) {
        final number = int.tryParse(text);
        if (number != null && number > 0) {
          onChanged(number);
        }
      },
    );
  }

  @override
  void dispose() {
    _modelController.dispose();
    super.dispose();
  }
}
