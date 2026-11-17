import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Morisnote: renders AI answers that mix plain text with LaTeX.
///
/// `$$...$$` becomes a centered display equation, `$...$` stays inline.
/// Broken LaTeX falls back to the raw text instead of throwing.
class MathText extends StatelessWidget {
  const MathText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static final _displayMath = RegExp(r'\$\$([\s\S]*?)\$\$');
  static final _inlineMath = RegExp(r'\$([^$\n]+?)\$');
  static final _bold = RegExp(r'\*\*(.+?)\*\*');

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);

    final blocks = <Widget>[];
    var index = 0;
    for (final match in _displayMath.allMatches(text)) {
      if (match.start > index) {
        blocks.add(_paragraph(text.substring(index, match.start), baseStyle));
      }
      blocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(child: _math(match.group(1) ?? '', baseStyle, true)),
        ),
      );
      index = match.end;
    }
    if (index < text.length) {
      blocks.add(_paragraph(text.substring(index), baseStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  Widget _paragraph(String raw, TextStyle baseStyle) {
    if (raw.trim().isEmpty) return const SizedBox.shrink();

    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in _inlineMath.allMatches(raw)) {
      if (match.start > index) {
        spans.addAll(_textSpans(raw.substring(index, match.start), baseStyle));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _math(match.group(1) ?? '', baseStyle, false),
        ),
      );
      index = match.end;
    }
    if (index < raw.length) {
      spans.addAll(_textSpans(raw.substring(index), baseStyle));
    }

    return SelectableText.rich(TextSpan(children: spans, style: baseStyle));
  }

  /// Handles `**bold**` and `` `code` `` inside a plain-text run.
  List<InlineSpan> _textSpans(String raw, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in _bold.allMatches(raw)) {
      if (match.start > index) {
        spans.add(TextSpan(text: raw.substring(index, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      index = match.end;
    }
    if (index < raw.length) spans.add(TextSpan(text: raw.substring(index)));

    // Inline code: split on backticks and style the odd runs.
    final result = <InlineSpan>[];
    for (final span in spans) {
      final value = span is TextSpan ? span.text : null;
      if (value == null || !value.contains('`')) {
        result.add(span);
        continue;
      }
      final pieces = value.split('`');
      for (var i = 0; i < pieces.length; i++) {
        result.add(
          TextSpan(
            text: pieces[i],
            style: i.isOdd
                ? const TextStyle(fontFamily: 'monospace', fontSize: 13)
                : null,
          ),
        );
      }
    }
    return result;
  }

  Widget _math(String tex, TextStyle baseStyle, bool display) {
    final source = tex.trim();
    if (source.isEmpty) return const SizedBox.shrink();
    return Math.tex(
      source,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: baseStyle,
      onErrorFallback: (_) => Text(
        display ? '\$\$$source\$\$' : '\$$source\$',
        style: baseStyle.copyWith(fontFamily: 'monospace', fontSize: 13),
      ),
    );
  }
}
