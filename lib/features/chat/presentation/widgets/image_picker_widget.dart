import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/utils/image_utils.dart';

/// 图片选择器组件
class ImagePickerWidget extends StatefulWidget {
  final ValueChanged<List<File>> onImagesSelected;
  final List<File> selectedImages;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.selectedImages = const [],
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  List<File> _images = [];

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.selectedImages);
  }

  Future<void> _pickImages() async {
    final images = await ImageUtils.pickImages();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _images.addAll(images);
      });
      widget.onImagesSelected(_images);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesSelected(_images);
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '添加图片',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._images.asMap().entries.map((entry) {
              return _buildImagePreview(entry.key, entry.value);
            }),
            _buildAddButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview(int index, File image) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            image: DecorationImage(image: FileImage(image), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
