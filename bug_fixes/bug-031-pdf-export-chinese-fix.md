# Bug #31: PDF 导出乱码

## 问题描述
- 导出 PDF 时出现乱码问题
- 需要正确处理中文字体

## 原因分析

PDF 库默认不支持中文字符，需要：
1. 使用支持中文的字体
2. 在 PDF 中嵌入字体文件

## 修复方案

### 方案 A: 使用在线字体

使用 `pdf` 库提供的 Google Fonts 支持：

```dart
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// 加载中文字体
final font = await PdfGoogleFonts.notoSansSCRegular();
final fontBold = await PdfGoogleFonts.notoSansSCBold();

pdf.addPage(
  pw.MultiPage(
    theme: pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    ),
    build: (context) => [
      pw.Text('中文测试'),
    ],
  ),
);
```

### 方案 B: 使用本地字体

1. **添加字体文件**:
   - 下载 Noto Sans SC 或其他中文字体
   - 放入 `assets/fonts/` 目录
   - 在 `pubspec.yaml` 中声明

2. **加载字体**:
```dart
import 'package:flutter/services.dart';

final fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
final ttf = pw.Font.ttf(fontData);

final fontBoldData = await rootBundle.load('assets/fonts/NotoSansSC-Bold.ttf');
final ttfBold = pw.Font.ttf(fontBoldData);
```

3. **应用字体**:
```dart
pdf.addPage(
  pw.MultiPage(
    theme: pw.ThemeData.withFont(
      base: ttf,
      bold: ttfBold,
    ),
    build: (context) => [...],
  ),
);
```

## 推荐方案: 方案 A

使用 Google Fonts 更简单，不需要额外的资源文件。

### 实现代码

**文件**: `lib/core/utils/pdf_export.dart`

需要修改：

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExport {
  static Future<void> exportConversationToPdf(Conversation conversation) async {
    final pdf = pw.Document();
    
    // 加载中文字体
    final font = await PdfGoogleFonts.notoSansSCRegular();
    final fontBold = await PdfGoogleFonts.notoSansSCBold();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) => [
          // PDF 内容...
        ],
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}
```

## 测试步骤

1. 创建一个包含中文的对话
2. 导出为 PDF
3. 打开 PDF 验证中文显示正常
4. 测试特殊字符（emoji、标点符号等）

## 注意事项

1. **首次使用需要网络**
   - Google Fonts 首次使用需要下载字体
   - 后续会缓存到本地

2. **字体大小**
   - Noto Sans SC 字体较大（约 10MB）
   - 会增加第一次导出的时间

3. **备用方案**
   - 如果无法下载 Google Fonts
   - 可以改用本地字体方案

## 相关文件
- `lib/core/utils/pdf_export.dart`
- `pubspec.yaml` (可能需要添加字体资源)

## 修复日期
2025-01-18

## 状态
✅ 已完成

## 依赖包

当前 `pubspec.yaml` 中已有：
- `pdf: ^3.11.3`
- `printing: ^5.14.2`

这两个包已经支持 Google Fonts。
