import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/log_service.dart';

/// 改进的背景设置页面
class ImprovedBackgroundSettingsScreen extends ConsumerStatefulWidget {
  const ImprovedBackgroundSettingsScreen({super.key});

  @override
  ConsumerState<ImprovedBackgroundSettingsScreen> createState() =>
      _ImprovedBackgroundSettingsScreenState();
}

class _ImprovedBackgroundSettingsScreenState
    extends ConsumerState<ImprovedBackgroundSettingsScreen> {
  final LogService _log = LogService();

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _log.info('初始化背景设置页面');
    final settings = ref.read(appSettingsProvider);
    _selectedBackground = settings.backgroundImage;
    _opacity = settings.backgroundOpacity;
    _enableBlur = settings.enableBackgroundBlur;
    _log.debug('加载现有设置', {
      'hasBackground': _selectedBackground != null,
      'opacity': _opacity,
    });
  }

  Future<void> _pickCustomImage() async {
    _log.info('用户开始选择自定义图片');
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedBackground = result.files.single.path;
        });
        _log.info('自定义图片选择成功', {'path': result.files.single.path});
      } else {
        _log.debug('用户取消选择图片');
      }
    } catch (e, stack) {
      _log.error('选择图片失败', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择图片失败：${e.toString()}')));
      }
    }
  }

  Future<void> _saveSettings() async {
    _log.info('开始保存背景设置', {
      'background': _selectedBackground,
      'opacity': _opacity,
    });

    setState(() {
      _isSaving = true;
    });

    try {
      final currentSettings = ref.read(appSettingsProvider);
      final newSettings = currentSettings.copyWith(
        backgroundImage: _selectedBackground,
        clearBackgroundImage: _selectedBackground == null,
        backgroundOpacity: _opacity,
        enableBackgroundBlur: _enableBlur,
      );

      await ref.read(appSettingsProvider.notifier).updateSettings(newSettings);
      _log.info('背景设置保存成功');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置已保存')));
        Navigator.of(context).pop();
      }
    } catch (e, stack) {
      _log.error('保存背景设置失败', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败：${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _clearBackground() {
    _log.info('清除背景图片');
    setState(() {
      _selectedBackground = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('背景设置'),
        elevation: 0,
        actions: [
          if (_selectedBackground != null)
            TextButton.icon(
              onPressed: _clearBackground,
              icon: const Icon(Icons.clear),
              label: const Text('清除'),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isSaving ? '保存中...' : '保存'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreviewSection(context),
            const SizedBox(height: 24),
            _buildPresetsSection(context),
            const SizedBox(height: 24),
            _buildCustomSection(context),
            const SizedBox(height: 24),
            _buildControlsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '预览',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 240,
            child: _selectedBackground != null
                ? _buildBackgroundPreview()
                : _buildEmptyPreview(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPreview() {
    Widget imageWidget;

    try {
      if (_selectedBackground!.startsWith('assets/')) {
        imageWidget = Image.asset(_selectedBackground!, fit: BoxFit.cover);
      } else {
        imageWidget = Image.file(File(_selectedBackground!), fit: BoxFit.cover);
      }
    } catch (e) {
      _log.error('加载背景图片失败', e);
      return _buildErrorPreview();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        Container(color: Colors.white.withValues(alpha: 1 - _opacity)),
        if (_enableBlur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.transparent),
          ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '预览效果',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPreview(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无背景',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择一个预设背景或上传自定义图片',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPreview() {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '图片加载失败',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.collections,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  '预设背景',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: defaultBackgrounds.length,
              itemBuilder: (context, index) {
                final bg = defaultBackgrounds[index];
                final isSelected = _selectedBackground == bg['path'];

                return _buildPresetCard(
                  context: context,
                  background: bg,
                  isSelected: isSelected,
                  onTap: () {
                    _log.debug('选择预设背景', {'name': bg['name']});
                    setState(() {
                      _selectedBackground = bg['path'];
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetCard({
    required BuildContext context,
    required Map<String, String> background,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image),
              ),
              if (isSelected)
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  child: Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    background['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.upload_file,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Text(
                  '自定义背景',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '上传你喜欢的图片作为聊天背景',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickCustomImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('选择图片'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: colorScheme.tertiary),
                const SizedBox(width: 12),
                Text(
                  '效果控制',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 透明度设置
            Row(
              children: [
                Icon(Icons.opacity, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text('透明度', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${(_opacity * 100).toInt()}%',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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

            // 模糊效果
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                secondary: CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.blur_on,
                    color: colorScheme.secondary,
                    size: 22,
                  ),
                ),
                title: const Text('启用模糊效果'),
                subtitle: const Text('为背景添加模糊效果,提高文字可读性'),
                value: _enableBlur,
                onChanged: (value) {
                  _log.debug('切换模糊效果', {'enabled': value});
                  setState(() {
                    _enableBlur = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
