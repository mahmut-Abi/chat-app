import 'package:flutter/material.dart';
import 'dart:io';
import '../../../../core/utils/platform_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/utils/message_utils.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;

  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _saveImage(context),
            tooltip: '保存到相册',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imagePath),
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.white54),
                    SizedBox(height: 16),
                    Text('图片加载失败', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      final status = await Permission.photos.request();

      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('需要相册权限才能保存图片')));
        }
        return;
      }

      Directory? directory;
      if (PlatformUtils.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else if (PlatformUtils.isAndroid) {
        directory = await getExternalStorageDirectory();
      }

      if (directory == null) {
        throw Exception('无法获取存储目录');
      }

      final fileName = path.basename(imagePath);
      final newPath = path.join(directory.path, 'Pictures', fileName);

      final imageFile = File(imagePath);
      await Directory(path.dirname(newPath)).create(recursive: true);
      await imageFile.copy(newPath);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('图片已保存到: $newPath')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    }
  }
}
