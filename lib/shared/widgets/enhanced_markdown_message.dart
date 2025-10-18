import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobileDevice(context);

    // 如果禁用 Markdown，直接显示纯文本
    if (!enableMarkdown) {
      return selectable ? SelectableText(content) : Text(content);
    }

    // 使用内容和配置创建缓存键
    final cacheKey = '$content-$enableLatex-$enableCodeHighlight-$selectable-$isDarkMode-$isMobile';

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
        'code': CodeBlockBuilder(
          enableHighlight: enableCodeHighlight,
          isDarkMode: isDarkMode,
          isMobile: isMobile,
        ),
        if (enableLatex) 'latex': LaTeXBuilder(),
      },
      extensionSet:
          md.ExtensionSet(md.ExtensionSet.gitHubFlavored.blockSyntaxes, [
            ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
            if (enableLatex) LaTeXInlineSyntax(),
          ]),
      styleSheet: _buildStyleSheet(context, isDarkMode, isMobile),
    );

    // 存入缓存
    _MarkdownCache.set(cacheKey, widget);
    return widget;
  }

  // 判断是否为移动设备
  bool _isMobileDevice(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 600; // 小于 600px 视为移动设备
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context, bool isDarkMode) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final codeBackgroundColor = isDarkMode 
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF6F8FA);

    return MarkdownStyleSheet(
      // 段落样式
      p: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: textColor,
        letterSpacing: 0.2,
      ),
      pPadding: const EdgeInsets.symmetric(vertical: 8),

      // 标题样式
      h1: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
        letterSpacing: -0.5,
      ),
      h1Padding: const EdgeInsets.only(top: 24, bottom: 16),
      
      h2: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
        letterSpacing: -0.3,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 12),
      
      h3: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 10),
      
      h4: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h4Padding: const EdgeInsets.only(top: 12, bottom: 8),
      
      h5: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.5,
      ),
      h5Padding: const EdgeInsets.only(top: 12, bottom: 8),
      
      h6: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor.withValues(alpha: 0.8),
        height: 1.5,
      ),
      h6Padding: const EdgeInsets.only(top: 10, bottom: 6),

      // 列表样式
      listBullet: TextStyle(
        fontSize: 15,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      listIndent: 28,
      listBulletPadding: const EdgeInsets.only(right: 12),

      // 引用块样式
      blockquote: TextStyle(
        fontSize: 15,
        fontStyle: FontStyle.italic,
        color: textColor.withValues(alpha: 0.7),
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),

      // 代码样式
      code: TextStyle(
        backgroundColor: codeBackgroundColor,
        fontFamily: 'monospace',
        fontSize: 14,
        color: isDarkMode ? const Color(0xFFE06C75) : const Color(0xFFD73A49),
        fontWeight: FontWeight.w500,
      ),
      codeblockPadding: const EdgeInsets.all(0),
      codeblockDecoration: const BoxDecoration(),

      // 水平分割线样式
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: textColor.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
      ),

      // 链接样式
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
      ),

      // 强调和加粗样式
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: textColor,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.bold,
        color: textColor,
      ),

      // 删除线样式
      del: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: textColor.withValues(alpha: 0.6),
      ),

      // 表格样式
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: textColor,
      ),
      tableBody: TextStyle(
        fontSize: 14,
        color: textColor,
      ),
      tableBorder: TableBorder.all(
        color: textColor.withValues(alpha: 0.2),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),

      // 其他间距
      blockSpacing: 12,
      textScaleFactor: 1.0,
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
  final bool enableHighlight;
  final bool isDarkMode;

  CodeBlockBuilder({
    this.enableHighlight = true,
    required this.isDarkMode,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['class']?.split('-').last ?? 'text';

    // 根据主题选择颜色
    final backgroundColor = isDarkMode 
        ? const Color(0xFF1E1E1E) 
        : const Color(0xFFF6F8FA);
    final headerColor = isDarkMode 
        ? const Color(0xFF2D2D2D) 
        : const Color(0xFFE1E4E8);
    final textColor = isDarkMode 
        ? const Color(0xFFD4D4D4) 
        : const Color(0xFF24292E);
    final languageTagColor = isDarkMode 
        ? const Color(0xFF007ACC) 
        : const Color(0xFF0366D6);
    final copyButtonColor = isDarkMode 
        ? const Color(0xFFCCCCCC) 
        : const Color(0xFF586069);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
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
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode 
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // 装饰性圆点
                Row(
                  children: [
                    _buildDot(Colors.red.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    _buildDot(Colors.yellow.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    _buildDot(Colors.green.withValues(alpha: 0.8)),
                  ],
                ),
                const SizedBox(width: 16),
                // 语言标签
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: languageTagColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                // 复制按钮 - 改进样式
                _CopyButton(
                  code: code,
                  color: copyButtonColor,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
          // 代码内容 - 改进样式
          Container(
            constraints: const BoxConstraints(
              maxHeight: 500, // 限制最大高度，超过则滚动
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                child: enableHighlight
                    ? HighlightView(
                        code,
                        language: language,
                        theme: isDarkMode ? monokaiSublimeTheme : githubTheme,
                        padding: EdgeInsets.zero,
                        textStyle: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.5,
                          color: textColor,
                        ),
                      )
                    : SelectableText(
                        code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.5,
                          color: textColor,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
    );
  }
}

// 复制按钮组件
class _CopyButton extends StatefulWidget {
  final String code;
  final Color color;
  final bool isDarkMode;

  const _CopyButton({
    required this.code,
    required this.color,
    required this.isDarkMode,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _copied 
                ? (widget.isDarkMode 
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.1))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.content_copy,
                size: 16,
                color: _copied ? Colors.green : widget.color,
              ),
              const SizedBox(width: 6),
              Text(
                _copied ? '已复制' : '复制',
                style: TextStyle(
                  fontSize: 12,
                  color: _copied ? Colors.green : widget.color,
                  fontWeight: _copied ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
