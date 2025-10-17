import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter/services.dart';
import '../../core/providers/providers.dart';
import '../../features/settings/domain/api_config.dart';

// Markdown 渲染缓存
class _MarkdownCache {
  static final Map<String, Widget> _cache = {};
  static const int _maxCacheSize = 100;

  static Widget? get(String key) => _cache[key];

  static void set(String key, Widget widget) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = widget;
  }
}

// 增强的 Markdown 消息渲染组件，支持 LaTeX
class EnhancedMarkdownMessage extends ConsumerWidget {
  final String content;
  final bool selectable;

  const EnhancedMarkdownMessage({
    super.key,
    required this.content,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return settingsAsync.when(
      data: (settings) => _buildMarkdown(context, settings),
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => _buildMarkdown(context, const AppSettings()),
    );
  }

  Widget _buildMarkdown(BuildContext context, AppSettings settings) {
    final enableMarkdown = settings.enableMarkdown;
    final enableLatex = settings.enableLatex;
    final enableCodeHighlight = settings.enableCodeHighlight;

    // 如果禁用 Markdown，直接显示纯文本
    if (!enableMarkdown) {
      return selectable ? SelectableText(content) : Text(content);
    }

    // 使用内容和配置创建缓存键
    final cacheKey = '$content-$enableLatex-$enableCodeHighlight-$selectable';

    // 尝试从缓存获取
    final cached = _MarkdownCache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    // 渲染并缓存
    final widget = MarkdownBody(
      data: content,
      selectable: selectable,
      builders: {
        'code': CodeBlockBuilder(enableHighlight: enableCodeHighlight),
        if (enableLatex) 'latex': LaTeXBuilder(),
      },
      extensionSet:
          md.ExtensionSet(md.ExtensionSet.gitHubFlavored.blockSyntaxes, [
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            if (enableLatex) LaTeXInlineSyntax(),
          ]),
      styleSheet: MarkdownStyleSheet(
        blockSpacing: 8,
        listIndent: 24,
        codeblockDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        code: TextStyle(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );

    // 存入缓存
    _MarkdownCache.set(cacheKey, widget);
    return widget;
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
  final bool enableHighlight;

  CodeBlockBuilder({this.enableHighlight = true});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.split('-').last ?? 'text';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // 深色背景
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 代码块头部 - 美化设计
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // 语言标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007ACC),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                // 复制按钮 - 改进样式
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.content_copy,
                            size: 16,
                            color: Color(0xFFCCCCCC),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '复制',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 代码内容 - 改进样式
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: enableHighlight
                ? HighlightView(
                    code,
                    language: language,
                    theme: githubTheme,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFFD4D4D4),
                    ),
                  )
                : SelectableText(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFFD4D4D4),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
