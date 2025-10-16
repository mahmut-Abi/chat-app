import 'package:flutter/material.dart';

class ApiConfigModelSection extends StatelessWidget {
  final String? selectedModel;
  final List<String> availableModels;
  final bool isLoadingModels;
  final double temperature;
  final int maxTokens;
  final double topP;
  final double frequencyPenalty;
  final double presencePenalty;
  final Function(double) onTemperatureChanged;
  final Function(double) onMaxTokensChanged;
  final Function(double) onTopPChanged;
  final Function(double) onFrequencyPenaltyChanged;
  final Function(double) onPresencePenaltyChanged;
  final Function(String?) onModelChanged;
  final VoidCallback onFetchModels;

  const ApiConfigModelSection({
    super.key,
    required this.selectedModel,
    required this.availableModels,
    required this.isLoadingModels,
    required this.temperature,
    required this.maxTokens,
    required this.topP,
    required this.frequencyPenalty,
    required this.presencePenalty,
    required this.onTemperatureChanged,
    required this.onMaxTokensChanged,
    required this.onTopPChanged,
    required this.onFrequencyPenaltyChanged,
    required this.onPresencePenaltyChanged,
    required this.onModelChanged,
    required this.onFetchModels,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('模型参数', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: availableModels.contains(selectedModel)
                        ? selectedModel
                        : null,
                    decoration: const InputDecoration(
                      labelText: '默认模型',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.memory),
                    ),
                    hint: const Text('选择模型'),
                    items: availableModels.map((model) {
                      return DropdownMenuItem(value: model, child: Text(model));
                    }).toList(),
                    onChanged: onModelChanged,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: isLoadingModels ? null : onFetchModels,
                  icon: isLoadingModels
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  tooltip: '获取可用模型',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSlider(
              context,
              label: 'Temperature',
              value: temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: onTemperatureChanged,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: 'Max Tokens',
              value: maxTokens.toDouble(),
              min: 100,
              max: 4000,
              divisions: 39,
              onChanged: onMaxTokensChanged,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: 'Top P',
              value: topP,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: onTopPChanged,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: 'Frequency Penalty',
              value: frequencyPenalty,
              min: -2.0,
              max: 2.0,
              divisions: 40,
              onChanged: onFrequencyPenaltyChanged,
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: 'Presence Penalty',
              value: presencePenalty,
              min: -2.0,
              max: 2.0,
              divisions: 40,
              onChanged: onPresencePenaltyChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toStringAsFixed(label.contains('Token') ? 0 : 2),
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
      ],
    );
  }
}
