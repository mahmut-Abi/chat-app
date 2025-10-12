import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter/services.dart';

// 增强的 Markdown 消息渲染组件，支持 LaTeX
class EnhancedMarkdownMessage extends StatelessWidget {
  final String content;
  final bool selectable;

  const EnhancedMarkdownMessage({
    super.key,
    required this.content,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: content,
      selectable: selectable,
      builders: {
        'code': CodeBlockBuilder(),
        'latex': LaTeXBuilder(),
      },
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
          LaTeXInlineSyntax(),
        ],
      ),
      styleSheet: MarkdownStyleSheet(
        blockSpacing: 8,
        listIndent: 24,
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        code: TextStyle(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }
}

// LaTeX 行内语法解析器
class LaTeXInlineSyntax extends md.InlineSyntax {
  LaTeXInlineSyntax() : super(r'\$\$(.+?)\$\$|\$(.+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final latex = match[1] ?? match[2];
    if (latex == null) return false;

    final element = md.Element.text('latex', latex);
    parser.addNode(element);
    return true;
  }
}

// LaTeX 构建器
class LaTeXBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final latex = element.textContent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Math.tex(
        latex,
        mathStyle: MathStyle.display,
        textStyle: preferredStyle,
        onErrorFallback: (error) {
          return Text(
            '数学公式解析错误: $latex',
            style: const TextStyle(color: Colors.red),
          );
        },
      ),
    );
  }
}

// 代码块构建器，支持语法高亮和复制
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.split('-').last ?? 'text';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 代码块头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Text(
                  language.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                  },
                  tooltip: '复制代码',
                ),
              ],
            ),
          ),
          // 代码内容
          Container(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language,
              theme: githubTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
