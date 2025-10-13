import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/providers/providers.dart';

class BackgroundSettingsDialog extends ConsumerStatefulWidget {
  const BackgroundSettingsDialog({super.key});

  @override
  ConsumerState<BackgroundSettingsDialog> createState() =>
      _BackgroundSettingsDialogState();
}

class _BackgroundSettingsDialogState
    extends ConsumerState<BackgroundSettingsDialog> {
  // 默认背景图片
  static const List<Map<String, String>> defaultBackgrounds = [
    {'name': '渐变蓝紫', 'path': 'assets/backgrounds/gradient_1.jpg'},
    {'name': '渐变粉蓝', 'path': 'assets/backgrounds/gradient_2.jpg'},
    {'name': '渐变黄绿', 'path': 'assets/backgrounds/gradient_3.jpg'},
    {'name': '渐变紫粉', 'path': 'assets/backgrounds/gradient_4.jpg'},
    {'name': '渐变蓝绿', 'path': 'assets/backgrounds/gradient_5.jpg'},
    {'name': '抽象艺术', 'path': 'assets/backgrounds/abstract_1.jpg'},
  ];

  String? _selectedBackground;
  double _opacity = 0.3;
  bool _enableBlur = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _selectedBackground = settings.backgroundImage;
    _opacity = settings.backgroundOpacity;
    _enableBlur = settings.enableBackgroundBlur;
  }

  Future<void> _pickCustomImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedBackground = result.files.single.path;
      });
    }
  }

  Future<void> _saveSettings() async {
    final currentSettings = ref.read(appSettingsProvider);

    final newSettings = currentSettings.copyWith(
      backgroundImage: _selectedBackground,
      clearBackgroundImage: _selectedBackground == null,
      backgroundOpacity: _opacity,
      enableBackgroundBlur: _enableBlur,
    );

    if (kDebugMode) {
      print('Saving settings:');
      print('  backgroundImage: $_selectedBackground');
      print('  backgroundOpacity: $_opacity');
      print('  enableBackgroundBlur: $_enableBlur');
      print('  newSettings: ${newSettings.toJson()}');
    }

    // updateSettings 会自动保存到本地存储并更新状态
    await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _clearBackground() {
    setState(() {
      _selectedBackground = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('背景设置'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 预览区域
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_selectedBackground != null)
                        _buildBackgroundPreview()
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '未选择背景',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 默认背景选择
              Text('默认背景', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: defaultBackgrounds.length,
                  itemBuilder: (context, index) {
                    final bg = defaultBackgrounds[index];
                    final isSelected = _selectedBackground == bg['path'];

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBackground = bg['path'];
                          });
                        },
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  bg['path']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    color: Colors.black.withValues(alpha: 0.5),
                                    child: Text(
                                      bg['name']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 自定义背景
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('自定义背景', style: Theme.of(context).textTheme.titleMedium),
                  ElevatedButton.icon(
                    onPressed: _pickCustomImage,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('上传图片'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 透明度设置
              Text(
                '透明度: ${(_opacity * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _opacity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(_opacity * 100).toInt()}%',
                onChanged: (value) {
                  setState(() {
                    _opacity = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 模糊效果设置
              SwitchListTile(
                title: const Text('启用模糊效果'),
                subtitle: const Text('为背景添加模糊效果,提高文字可读性'),
                value: _enableBlur,
                onChanged: (value) {
                  setState(() {
                    _enableBlur = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_selectedBackground != null)
          TextButton(onPressed: _clearBackground, child: const Text('清除背景')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _saveSettings, child: const Text('保存')),
      ],
    );
  }

  Widget _buildBackgroundPreview() {
    Widget imageWidget;

    if (_selectedBackground!.startsWith('assets/')) {
      imageWidget = Image.asset(
        _selectedBackground!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error)),
          );
        },
      );
    } else {
      imageWidget = Image.file(
        File(_selectedBackground!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Center(child: Icon(Icons.error)),
          );
        },
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Container(color: Colors.white.withValues(alpha: 1 - _opacity)),
        if (_enableBlur)
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: Text(
                '模糊效果预览',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
