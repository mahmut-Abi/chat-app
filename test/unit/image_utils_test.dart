import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/core/utils/image_utils.dart';

void main() {
  group('ImageUtils', () {
    test('应该正确识别图片文件类型', () {
      expect(ImageUtils.isImageFile('test.jpg'), true);
      expect(ImageUtils.isImageFile('test.jpeg'), true);
      expect(ImageUtils.isImageFile('test.png'), true);
      expect(ImageUtils.isImageFile('test.gif'), true);
      expect(ImageUtils.isImageFile('test.webp'), true);
      expect(ImageUtils.isImageFile('test.txt'), false);
      expect(ImageUtils.isImageFile('test.pdf'), false);
    });

    test('应该返回正确的 MIME 类型', () {
      expect(ImageUtils.getImageMimeType('test.jpg'), 'image/jpeg');
      expect(ImageUtils.getImageMimeType('test.jpeg'), 'image/jpeg');
      expect(ImageUtils.getImageMimeType('test.png'), 'image/png');
      expect(ImageUtils.getImageMimeType('test.gif'), 'image/gif');
      expect(ImageUtils.getImageMimeType('test.webp'), 'image/webp');
      expect(ImageUtils.getImageMimeType('test.unknown'), 'image/jpeg');
    });
  });
}
