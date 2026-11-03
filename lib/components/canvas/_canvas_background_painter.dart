import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saber/data/extensions/color_extensions.dart';
import 'package:sbn/canvas_background_pattern.dart';

class CanvasBackgroundPainter extends CustomPainter {
  const new({
    required this.invert,
    required this.backgroundColor,
    this.backgroundPattern = .none,
    required this.lineHeight,
    required this.lineThickness,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.red,
    this.preview = false,
  });

  final bool invert;
  final Color backgroundColor;

  /// The pattern to use for the background. See [CanvasBackgroundPatterns].
  final CanvasBackgroundPattern backgroundPattern;

  /// The height between each line in the background pattern
  final int lineHeight;
  final int lineThickness;
  final Color primaryColor, secondaryColor;

  /// Whether to draw the background pattern in a preview mode (more opaque).
  final bool preview;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    final paint = Paint();

    paint.color = backgroundColor.withInversion(invert);
    canvas.drawRect(canvasRect, paint);

    paint.strokeWidth = lineThickness.toDouble();

    if (backgroundPattern.requiresClipping) {
      canvas.save();
      canvas.clipRect(canvasRect);
    }

    for (final element in getPatternElements(
      pattern: backgroundPattern,
      size: size,
      lineHeight: lineHeight,
    )) {
      if (element.secondaryColor) {
        paint.color = secondaryColor.withValues(alpha: preview ? 0.5 : 0.2);
      } else {
        paint.color = primaryColor.withValues(alpha: preview ? 0.5 : 0.2);
      }

      if (element.isLine) {
        canvas.drawLine(element.start, element.end, paint);
      } else {
        canvas.drawCircle(element.start, paint.strokeWidth * 4 / 3, paint);
      }
    }

    if (backgroundPattern.requiresClipping) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CanvasBackgroundPainter oldDelegate) =>
      kDebugMode ||
      oldDelegate.invert != invert ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.backgroundPattern != backgroundPattern ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;

  static Iterable<PatternElement> getPatternElements({
    required CanvasBackgroundPattern pattern,
    required Size size,
    required int lineHeight,
  }) sync* {
    switch (pattern) {
      case .none:
        return;
      case .collegeLtr:
      case .collegeRtl:
      case .lined:
        // horizontal lines
        for (double y = lineHeight * 2; y < size.height; y += lineHeight) {
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            isLine: true,
          );
        }

        // vertical line
        if (pattern == .collegeLtr) {
          yield PatternElement(
            Offset(lineHeight * 2, 0),
            Offset(lineHeight * 2, size.height),
            isLine: true,
            secondaryColor: true,
          );
        } else if (pattern == .collegeRtl) {
          yield PatternElement(
            Offset(size.width - lineHeight * 2, 0),
            Offset(size.width - lineHeight * 2, size.height),
            isLine: true,
            secondaryColor: true,
          );
        }
      case .grid:
        for (double y = lineHeight * 2; y < size.height; y += lineHeight) {
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            isLine: true,
          );
        }
        for (double x = 0; x < size.width; x += lineHeight) {
          yield PatternElement(
            Offset(x, lineHeight * 2),
            Offset(x, size.height),
            isLine: true,
          );
        }
      case .dots:
        for (double y = lineHeight * 2; y <= size.height; y += lineHeight) {
          for (double x = 0; x <= size.width; x += lineHeight) {
            yield PatternElement(Offset(x, y), Offset(x, y), isLine: false);
          }
        }
      case .staffs:
      case .tablature:
        final staffSpaces = pattern == .staffs ? 4 : 5;
        final staffHeight = lineHeight * staffSpaces;
        final staffSpacing = lineHeight * 3;

        for (
          double topOfStaff = staffSpacing.toDouble() - lineHeight;
          topOfStaff + staffHeight < size.height;
          topOfStaff += staffHeight + staffSpacing
        ) {
          // horizontal lines
          for (int line = 0; line < staffSpaces + 1; line++) {
            yield PatternElement(
              Offset(lineHeight.toDouble(), topOfStaff + lineHeight * line),
              Offset(size.width - lineHeight, topOfStaff + lineHeight * line),
              isLine: true,
            );
          }

          // vertical lines on either side
          yield PatternElement(
            Offset(lineHeight.toDouble(), topOfStaff),
            Offset(lineHeight.toDouble(), topOfStaff + staffHeight),
            isLine: true,
          );
          yield PatternElement(
            Offset(size.width - lineHeight, topOfStaff),
            Offset(size.width - lineHeight, topOfStaff + staffHeight),
            isLine: true,
          );
        }
      case .cornell:
        // half-width line for name field
        yield PatternElement(
          Offset(lineHeight.toDouble(), lineHeight * 2),
          Offset(size.width / 2 - lineHeight / 2, lineHeight * 2),
          isLine: true,
        );
        // half-width line for date field
        yield PatternElement(
          Offset(size.width / 2 + lineHeight / 2, lineHeight * 2),
          Offset(size.width - lineHeight, lineHeight * 2),
          isLine: true,
        );
        // full-width line for title field
        yield PatternElement(
          Offset(lineHeight.toDouble(), lineHeight * 3),
          Offset(size.width - lineHeight, lineHeight * 3),
          isLine: true,
        );

        // lines for main notes
        final left = size.width * 0.35; // 35% width reserved for cues column
        final bottom = size.height * 0.7; // 30% height reserved for summary
        for (double y = lineHeight * 5; y < bottom; y += lineHeight) {
          yield PatternElement(
            Offset(left, y),
            Offset(size.width - lineHeight, y),
            isLine: true,
          );
        }
      case .graph:
        // minor grid lines
        for (double y = lineHeight * 2; y < size.height; y += lineHeight) {
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            isLine: true,
            secondaryColor: true,
          );
        }
        for (double x = 0; x < size.width; x += lineHeight) {
          yield PatternElement(
            Offset(x, lineHeight * 2),
            Offset(x, size.height),
            isLine: true,
            secondaryColor: true,
          );
        }
        // bold line every fifth square
        for (double y = lineHeight * 2; y < size.height; y += lineHeight * 5) {
          yield PatternElement(Offset(0, y), Offset(size.width, y));
        }
        for (double x = 0; x < size.width; x += lineHeight * 5) {
          yield PatternElement(Offset(x, lineHeight * 2), Offset(x, size.height));
        }
      case .isometric:
        const slope = 1.7320508075688772; // tan(60°)
        final spacing = lineHeight.toDouble() * 2;
        final verticalStep = spacing * slope;
        // vertical lines
        for (double x = 0; x < size.width + size.height; x += spacing) {
          yield PatternElement(Offset(x, 0), Offset(x, size.height));
        }
        // lines at +60° and -60° from the horizontal
        for (double b = -size.width * slope; b < size.height; b += verticalStep) {
          yield PatternElement(
            Offset(0, b),
            Offset(size.width, b + slope * size.width),
          );
        }
        for (double b = 0; b < size.height + size.width * slope; b += verticalStep) {
          yield PatternElement(
            Offset(0, b),
            Offset(size.width, b - slope * size.width),
          );
        }
      case .hex:
        final side = lineHeight.toDouble();
        final halfHeight = side * 0.8660254037844386; // sqrt(3)/2
        final columnStep = side * 1.5;
        final rowStep = halfHeight * 2;
        for (int col = 0;; col++) {
          final centreX = col * columnStep;
          if (centreX - side > size.width) break;
          final rowOffset = col.isOdd ? halfHeight : 0;
          for (int row = 0;; row++) {
            final centreY = row * rowStep + rowOffset;
            if (centreY - halfHeight > size.height) break;
            final corners = [
              Offset(centreX + side, centreY),
              Offset(centreX + side / 2, centreY + halfHeight),
              Offset(centreX - side / 2, centreY + halfHeight),
              Offset(centreX - side, centreY),
              Offset(centreX - side / 2, centreY - halfHeight),
              Offset(centreX + side / 2, centreY - halfHeight),
            ];
            for (int i = 0; i < 6; i++) {
              yield PatternElement(corners[i], corners[(i + 1) % 6]);
            }
          }
        }
      case .weeklyPlanner:
        final headerHeight = lineHeight * 2.5;
        final columnWidth = size.width / 7;
        yield PatternElement(
          Offset(0, headerHeight),
          Offset(size.width, headerHeight),
        );
        for (int i = 1; i < 7; i++) {
          final x = columnWidth * i;
          yield PatternElement(
            Offset(x, 0),
            Offset(x, size.height),
            secondaryColor: true,
          );
        }
        for (double y = headerHeight + lineHeight * 4; y < size.height; y += lineHeight * 4) {
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            secondaryColor: true,
          );
        }
      case .dailyPlanner:
        final timeColumnWidth = size.width * 0.18;
        final hourHeight = lineHeight * 2.5;
        yield PatternElement(
          Offset(timeColumnWidth, 0),
          Offset(timeColumnWidth, size.height),
        );
        int hourIndex = 0;
        for (double y = hourHeight; y < size.height; y += hourHeight) {
          hourIndex++;
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            secondaryColor: hourIndex % 4 != 0,
          );
        }
      case .checklist:
        final rowHeight = lineHeight * 2;
        final boxSize = lineHeight * 1.2;
        final margin = lineHeight.toDouble();
        for (double y = margin; y + rowHeight < size.height; y += rowHeight) {
          final boxTop = y + (rowHeight - boxSize) / 2;
          final boxLeft = margin + boxSize / 2;
          final boxRight = boxLeft + boxSize;
          final boxBottom = boxTop + boxSize;
          yield PatternElement(Offset(boxLeft, boxTop), Offset(boxRight, boxTop));
          yield PatternElement(Offset(boxRight, boxTop), Offset(boxRight, boxBottom));
          yield PatternElement(Offset(boxRight, boxBottom), Offset(boxLeft, boxBottom));
          yield PatternElement(Offset(boxLeft, boxBottom), Offset(boxLeft, boxTop));
          yield PatternElement(
            Offset(boxRight + margin, y + rowHeight / 2),
            Offset(size.width - margin, y + rowHeight / 2),
            secondaryColor: true,
          );
        }
      case .storyboard:
        final margin = lineHeight.toDouble();
        const columns = 2;
        const rows = 3;
        final frameWidth = (size.width - margin * (columns + 1)) / columns;
        final frameHeight = (size.height - margin * (rows + 1)) / rows;
        for (int column = 0; column < columns; column++) {
          for (int row = 0; row < rows; row++) {
            final left = margin + column * (frameWidth + margin);
            final top = margin + row * (frameHeight + margin);
            final right = left + frameWidth;
            final bottom = top + frameHeight;
            yield PatternElement(Offset(left, top), Offset(right, top));
            yield PatternElement(Offset(right, top), Offset(right, bottom));
            yield PatternElement(Offset(right, bottom), Offset(left, bottom));
            yield PatternElement(Offset(left, bottom), Offset(left, top));
          }
        }
      case .calligraphy:
        final ascenderToXHeight = lineHeight.toDouble();
        final xHeightToBaseline = lineHeight * 1.5;
        final baselineToDescender = lineHeight.toDouble();
        final groupHeight =
            ascenderToXHeight + xHeightToBaseline + baselineToDescender;
        for (
          double top = lineHeight.toDouble();
          top + groupHeight < size.height;
          top += groupHeight + lineHeight * 2
        ) {
          final xHeight = top + ascenderToXHeight;
          final baseline = xHeight + xHeightToBaseline;
          final descender = baseline + baselineToDescender;
          yield PatternElement(Offset(0, top), Offset(size.width, top));
          yield PatternElement(
            Offset(0, xHeight),
            Offset(size.width, xHeight),
            secondaryColor: true,
          );
          yield PatternElement(Offset(0, baseline), Offset(size.width, baseline));
          yield PatternElement(
            Offset(0, descender),
            Offset(size.width, descender),
            secondaryColor: true,
          );
        }
      case .halfLined:
        for (double y = size.height / 2 + lineHeight; y < size.height; y += lineHeight) {
          yield PatternElement(Offset(0, y), Offset(size.width, y));
        }
    }
  }
}

class PatternElement {
  final Offset start, end;

  /// Whether this is a line or a dot
  final bool isLine;

  /// Whether this should use a secondary color
  final bool secondaryColor;

  const new(
    this.start,
    this.end, {
    this.isLine = true,
    this.secondaryColor = false,
  });
}
