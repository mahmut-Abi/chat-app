import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:markdown/markdown.dart' as md;

// 自定义代码块构建器
class CodeElementBuilder extends MarkdownElementBuilder {
  final bool isDarkMode;

  CodeElementBuilder({required this.isDarkMode});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9);
    }

    return CodeBlock(
      code: element.textContent,
      language: language,
      isDarkMode: isDarkMode,
    );
  }
}

// 代码块组件
class CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final bool isDarkMode;

  const CodeBlock({
    super.key,
    required this.code,
    required this.language,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF272822) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3E3D32) : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF3E3D32)
                  : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isEmpty ? 'code' : language,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('代码已复制'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: '复制代码',
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language.isEmpty ? 'plaintext' : language,
              theme: isDarkMode ? monokaiSublimeTheme : githubTheme,
              padding: EdgeInsets.zero,
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                height: 1.5,
                color: isDarkMode ? const Color(0xFFF8F8F2) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Markdown 消息组件
class MarkdownMessage extends StatelessWidget {
  final String content;
  final bool isDarkMode;

  const MarkdownMessage({
    super.key,
    required this.content,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: true,
      builders: {'code': CodeElementBuilder(isDarkMode: isDarkMode)},
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        code: TextStyle(
          backgroundColor: isDarkMode
              ? const Color(0xFF272822)
              : const Color(0xFFF1F5F9),
          fontFamily: 'monospace',
          fontSize: 13,
          color: isDarkMode ? const Color(0xFFF8F8F2) : const Color(0xFF1E293B),
        ),
        codeblockDecoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF272822) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: TextStyle(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
              width: 4,
            ),
          ),
        ),
        h1: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        h2: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        listBullet: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
        a: TextStyle(
          color: isDarkMode ? const Color(0xFF66D9EF) : Colors.blue.shade700,
          decoration: TextDecoration.underline,
        ),
        tableBorder: TableBorder.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        tableHead: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
