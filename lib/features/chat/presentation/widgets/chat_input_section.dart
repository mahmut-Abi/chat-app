import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../core/utils/image_utils.dart';
import 'image_picker_widget.dart';

/// 聊天输入区域组件
class ChatInputSection extends StatelessWidget {
  final TextEditingController messageController;
  final List<File> selectedImages;
  final bool isLoading;
  final VoidCallback onSend;
  final Function(List<File>) onImagesSelected;

  const ChatInputSection({
    super.key,
    required this.messageController,
    required this.selectedImages,
    required this.isLoading,
    required this.onSend,
    required this.onImagesSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 15.0,
      opacity: 0.15,
      padding: const EdgeInsets.all(16),
      border: Border(
        top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedImages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ImagePickerWidget(
                selectedImages: selectedImages,
                onImagesSelected: onImagesSelected,
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.image,
                  color: selectedImages.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: '添加图片',
                onPressed: () async {
                  final images = await ImageUtils.pickImages();
                  if (images != null && images.isNotEmpty) {
                    onImagesSelected([...selectedImages, ...images]);
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: isLoading ? null : onSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
