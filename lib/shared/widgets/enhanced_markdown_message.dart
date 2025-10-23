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
    final cacheKey =
        '$content-$enableLatex-$enableCodeHighlight-$selectable-$isDarkMode-$isMobile';

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

  MarkdownStyleSheet _buildStyleSheet(
    BuildContext context,
    bool isDarkMode,
    bool isMobile,
  ) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final codeBackgroundColor = isDarkMode
        ? const Color(0xFF2D2D2D)
        : const Color(0xFFF6F8FA);

    // 移动端使用更小的字号和间距
    final baseFontSize = isMobile ? 14.0 : 15.0;
    final h1Size = isMobile ? 24.0 : 28.0;
    final h2Size = isMobile ? 20.0 : 24.0;
    final h3Size = isMobile ? 18.0 : 20.0;
    final h4Size = isMobile ? 16.0 : 18.0;
    final h5Size = isMobile ? 15.0 : 16.0;
    final h6Size = isMobile ? 14.0 : 15.0;

    final pPaddingVertical = isMobile ? 6.0 : 8.0;
    final h1PaddingTop = isMobile ? 16.0 : 24.0;
    final h1PaddingBottom = isMobile ? 12.0 : 16.0;
    final h2PaddingTop = isMobile ? 14.0 : 20.0;
    final h2PaddingBottom = isMobile ? 10.0 : 12.0;
    final blockHorizontalPadding = isMobile ? 12.0 : 16.0;
    final listIndent = isMobile ? 20.0 : 28.0;

    return MarkdownStyleSheet(
      // 段落样式
      p: TextStyle(
        fontSize: baseFontSize,
        height: 1.6,
        color: textColor,
        letterSpacing: 0.2,
      ),
      pPadding: EdgeInsets.symmetric(vertical: pPaddingVertical),

      // 标题样式 - 移动端使用较小字号
      h1: TextStyle(
        fontSize: h1Size,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
        letterSpacing: -0.5,
      ),
      h1Padding: EdgeInsets.only(top: h1PaddingTop, bottom: h1PaddingBottom),

      h2: TextStyle(
        fontSize: h2Size,
        fontWeight: FontWeight.bold,
        color: textColor,
        height: 1.3,
        letterSpacing: -0.3,
      ),
      h2Padding: EdgeInsets.only(top: h2PaddingTop, bottom: h2PaddingBottom),

      h3: TextStyle(
        fontSize: h3Size,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h3Padding: EdgeInsets.only(
        top: isMobile ? 12.0 : 16.0,
        bottom: isMobile ? 8.0 : 10.0,
      ),

      h4: TextStyle(
        fontSize: h4Size,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.4,
      ),
      h4Padding: EdgeInsets.only(
        top: isMobile ? 10.0 : 12.0,
        bottom: isMobile ? 6.0 : 8.0,
      ),

      h5: TextStyle(
        fontSize: h5Size,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.5,
      ),
      h5Padding: EdgeInsets.only(
        top: isMobile ? 10.0 : 12.0,
        bottom: isMobile ? 6.0 : 8.0,
      ),

      h6: TextStyle(
        fontSize: h6Size,
        fontWeight: FontWeight.w600,
        color: textColor.withValues(alpha: 0.8),
        height: 1.5,
      ),
      h6Padding: EdgeInsets.only(
        top: isMobile ? 8.0 : 10.0,
        bottom: isMobile ? 4.0 : 6.0,
      ),

      // 列表样式 - 移动端使用较小缩进
      listBullet: TextStyle(
        fontSize: baseFontSize,
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      listIndent: listIndent,
      listBulletPadding: EdgeInsets.only(right: isMobile ? 8.0 : 12.0),

      // 引用块样式 - 移动端使用较小内边距
      blockquote: TextStyle(
        fontSize: baseFontSize,
        fontStyle: FontStyle.italic,
        color: textColor.withValues(alpha: 0.7),
        height: 1.6,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isMobile ? 6.0 : 8.0),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
            width: isMobile ? 3.0 : 4.0,
          ),
        ),
      ),
      blockquotePadding: EdgeInsets.symmetric(
        horizontal: blockHorizontalPadding,
        vertical: isMobile ? 10.0 : 12.0,
      ),

      // 代码样式 - 移动端使用较小字号
      code: TextStyle(
        backgroundColor: codeBackgroundColor,
        fontFamily: 'monospace',
        fontSize: isMobile ? 13.0 : 14.0,
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
            width: isMobile ? 1.5 : 2.0,
          ),
        ),
      ),

      // 链接样式
      a: TextStyle(
        color: theme.colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: theme.colorScheme.primary.withValues(alpha: 0.4),
        fontWeight: FontWeight.w500,
        fontSize: baseFontSize,
      ),

      // 强调和加粗样式
      em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
      strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),

      // 删除线样式
      del: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: textColor.withValues(alpha: 0.6),
      ),

      // 表格样式 - 移动端使用较小字号和内边距
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: isMobile ? 14.0 : 15.0,
        color: textColor,
      ),
      tableBody: TextStyle(fontSize: isMobile ? 13.0 : 14.0, color: textColor),
      tableBorder: TableBorder.all(
        color: textColor.withValues(alpha: 0.2),
        width: 1,
      ),
      tableHeadAlign: TextAlign.left,
      tableCellsPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 12.0,
        vertical: isMobile ? 6.0 : 8.0,
      ),

      // 其他间距 - 移动端使用较小间距
      blockSpacing: isMobile ? 10.0 : 12.0,
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
  final bool isMobile;

  CodeBlockBuilder({
    this.enableHighlight = true,
    required this.isDarkMode,
    required this.isMobile,
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

    // 移动端使用更小的边距和字号
    final borderRadius = isMobile ? 8.0 : 12.0;
    final verticalMargin = isMobile ? 8.0 : 10.0;
    final headerPadding = isMobile ? 10.0 : 12.0;
    final headerHorizontalPadding = isMobile ? 12.0 : 16.0;
    final contentPadding = isMobile ? 12.0 : 16.0;
    final dotSize = isMobile ? 10.0 : 12.0;
    final dotSpacing = isMobile ? 4.0 : 6.0;
    final fontSize = isMobile ? 13.0 : 14.0;
    final maxHeight = isMobile ? 400.0 : 500.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: isMobile ? 4.0 : 8.0,
            offset: Offset(0, isMobile ? 1.0 : 2.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 代码块头部 - 美化设计，移动端简化
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: headerHorizontalPadding,
              vertical: headerPadding,
            ),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(borderRadius),
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
                // 装饰性圆点 - 移动端隐藏或缩小
                if (!isMobile) ...[
                  Row(
                    children: [
                      _buildDot(Colors.red.withValues(alpha: 0.8), dotSize),
                      SizedBox(width: dotSpacing),
                      _buildDot(Colors.yellow.withValues(alpha: 0.8), dotSize),
                      SizedBox(width: dotSpacing),
                      _buildDot(Colors.green.withValues(alpha: 0.8), dotSize),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
                // 语言标签 - 移动端使用较小样式
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8.0 : 10.0,
                    vertical: isMobile ? 3.0 : 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: languageTagColor,
                    borderRadius: BorderRadius.circular(isMobile ? 4.0 : 6.0),
                  ),
                  child: Text(
                    language.toUpperCase(),
                    style: TextStyle(
                      fontSize: isMobile ? 10.0 : 11.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: isMobile ? 0.5 : 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                // 复制按钮 - 改进样式
                _CopyButton(
                  code: code,
                  color: copyButtonColor,
                  isDarkMode: isDarkMode,
                  isMobile: isMobile,
                ),
              ],
            ),
          ),
          // 代码内容 - 改进样式
          Container(
            constraints: BoxConstraints(
              maxHeight: maxHeight, // 限制最大高度，超过则滚动
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: EdgeInsets.all(contentPadding),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(borderRadius),
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
                          fontSize: fontSize,
                          height: 1.5,
                          color: textColor,
                        ),
                      )
                    : SelectableText(
                        code,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: fontSize,
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

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
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
  final bool isMobile;

  const _CopyButton({
    required this.code,
    required this.color,
    required this.isDarkMode,
    required this.isMobile,
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
    // 移动端使用更小的按钮
    final iconSize = widget.isMobile ? 14.0 : 16.0;
    final fontSize = widget.isMobile ? 11.0 : 12.0;
    final horizontalPadding = widget.isMobile ? 8.0 : 12.0;
    final verticalPadding = widget.isMobile ? 4.0 : 6.0;
    final spacing = widget.isMobile ? 4.0 : 6.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
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
                size: iconSize,
                color: _copied ? Colors.green : widget.color,
              ),
              SizedBox(width: spacing),
              Text(
                _copied ? '已复制' : '复制',
                style: TextStyle(
                  fontSize: fontSize,
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
