import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/chat/domain/message.dart';
import '../../features/chat/domain/conversation.dart';
import 'package:intl/intl.dart';

// PDF 导出工具类
class PdfExport {
  // 导出单个对话为 PDF
  static Future<void> exportConversationToPdf(Conversation conversation) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // 标题
          pw.Header(
            level: 0,
            child: pw.Text(
              conversation.title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          // 元数据
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('创建时间: ${dateFormat.format(conversation.createdAt)}'),
                pw.Text('更新时间: ${dateFormat.format(conversation.updatedAt)}'),
                if (conversation.tags.isNotEmpty)
                  pw.Text('标签: ${conversation.tags.join(', ')}'),
                if (conversation.totalTokens != null)
                  pw.Text('总 Token 数: ${conversation.totalTokens}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          if (conversation.systemPrompt != null &&
              conversation.systemPrompt!.isNotEmpty) ...[
            pw.Header(level: 1, child: pw.Text('系统提示词')),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Text(conversation.systemPrompt!),
            ),
            pw.SizedBox(height: 20),
          ],
          // 对话内容
          pw.Header(level: 1, child: pw.Text('对话内容')),
          pw.SizedBox(height: 10),
          ...conversation.messages.map((message) {
            if (message.role == MessageRole.system) {
              return pw.SizedBox.shrink();
            }

            final isUser = message.role == MessageRole.user;
            final roleLabel = isUser ? '用户' : 'AI';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: pw.BoxDecoration(
                          color: isUser
                              ? PdfColors.blue100
                              : PdfColors.green100,
                          borderRadius: pw.BorderRadius.all(
                            const pw.Radius.circular(3),
                          ),
                        ),
                        child: pw.Text(
                          roleLabel,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        dateFormat.format(message.timestamp),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(5),
                      ),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Text(
                      message.content,
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ),
                  if (message.tokenCount != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 3),
                      child: pw.Text(
                        'Token 数: ${message.tokenCount}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    // 显示打印/保存对话框
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: '${conversation.title}.pdf',
    );
  }

  // 导出多个对话为单个 PDF
  static Future<void> exportConversationsToPdf(
    List<Conversation> conversations,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // 封面页
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                '对话导出',
                style: pw.TextStyle(
                  fontSize: 36,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '导出时间: ${dateFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                '总对话数: ${conversations.length}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    // 为每个对话添加页面
    for (final conversation in conversations) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                conversation.title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('创建时间: ${dateFormat.format(conversation.createdAt)}'),
            if (conversation.tags.isNotEmpty)
              pw.Text('标签: ${conversation.tags.join(', ')}'),
            pw.SizedBox(height: 15),
            ...conversation.messages.map((message) {
              if (message.role == MessageRole.system) {
                return pw.SizedBox.shrink();
              }

              final isUser = message.role == MessageRole.user;
              final roleLabel = isUser ? '用户' : 'AI';

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '$roleLabel:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      message.content,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    // 显示打印/保存对话框
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'conversations_export.pdf',
    );
  }
}
