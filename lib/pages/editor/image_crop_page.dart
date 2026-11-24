import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Morisnote: crop an inserted image.
///
/// Returns the cropped region in the image's natural pixel coordinates (the
/// same space as `EditorImage.srcRect`), or null when cancelled.
class ImageCropPage extends StatefulWidget {
  const ImageCropPage({
    super.key,
    required this.bytes,
    required this.naturalSize,
    required this.initialSrc,
  });

  final Uint8List bytes;
  final Size naturalSize;
  final Rect initialSrc;

  static Future<Rect?> show(
    BuildContext context, {
    required Uint8List bytes,
    required Size naturalSize,
    required Rect initialSrc,
  }) {
    return Navigator.of(context).push<Rect>(
      MaterialPageRoute(
        builder: (_) => ImageCropPage(
          bytes: bytes,
          naturalSize: naturalSize,
          initialSrc: initialSrc,
        ),
      ),
    );
  }

  @override
  State<ImageCropPage> createState() => _ImageCropPageState();
}

class _ImageCropPageState extends State<ImageCropPage> {
  late Rect _crop = widget.initialSrc.shortestSide == 0
      ? Offset.zero & widget.naturalSize
      : widget.initialSrc;

  /// Display scale: natural pixels -> screen pixels.
  double _scale = 1;
  Offset _origin = Offset.zero;

  static const _minCropSide = 24.0;

  void _onHandleDrag(int corner, DragUpdateDetails details) {
    var left = _crop.left;
    var top = _crop.top;
    var right = _crop.right;
    var bottom = _crop.bottom;

    final dx = details.delta.dx / _scale;
    final dy = details.delta.dy / _scale;

    // corner: 0 = topLeft, 1 = topRight, 2 = bottomLeft, 3 = bottomRight
    if (corner == 0 || corner == 2) left += dx;
    if (corner == 1 || corner == 3) right += dx;
    if (corner == 0 || corner == 1) top += dy;
    if (corner == 2 || corner == 3) bottom += dy;

    left = left.clamp(0.0, right - _minCropSide);
    top = top.clamp(0.0, bottom - _minCropSide);
    right = right.clamp(left + _minCropSide, widget.naturalSize.width);
    bottom = bottom.clamp(top + _minCropSide, widget.naturalSize.height);

    setState(() => _crop = Rect.fromLTRB(left, top, right, bottom));
  }

  void _onMoveDrag(DragUpdateDetails details) {
    final moved = _crop.shift(
      Offset(details.delta.dx / _scale, details.delta.dy / _scale),
    );
    final dx = moved.left.clamp(
      0.0,
      widget.naturalSize.width - _crop.width,
    ) - _crop.left;
    final dy = moved.top.clamp(
      0.0,
      widget.naturalSize.height - _crop.height,
    ) - _crop.top;
    setState(() => _crop = _crop.shift(Offset(dx, dy)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potong gambar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_crop),
            child: const Text('Simpan'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const padding = 24.0;
          final available = Size(
            constraints.maxWidth - padding * 2,
            constraints.maxHeight - padding * 2,
          );
          _scale = [
            available.width / widget.naturalSize.width,
            available.height / widget.naturalSize.height,
          ].reduce((a, b) => a < b ? a : b);
          final displaySize = Size(
            widget.naturalSize.width * _scale,
            widget.naturalSize.height * _scale,
          );
          _origin = Offset(
            (constraints.maxWidth - displaySize.width) / 2,
            (constraints.maxHeight - displaySize.height) / 2,
          );

          final cropRect = Rect.fromLTRB(
            _origin.dx + _crop.left * _scale,
            _origin.dy + _crop.top * _scale,
            _origin.dx + _crop.right * _scale,
            _origin.dy + _crop.bottom * _scale,
          );

          return Stack(
            children: [
              Positioned(
                left: _origin.dx,
                top: _origin.dy,
                width: displaySize.width,
                height: displaySize.height,
                child: Image.memory(widget.bytes, fit: BoxFit.fill),
              ),
              // dim everything outside the crop
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CropOverlayPainter(
                      cropRect: cropRect,
                      color: theme.colorScheme.scrim.withValues(alpha: 0.55),
                      borderColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: cropRect.left,
                top: cropRect.top,
                width: cropRect.width,
                height: cropRect.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: _onMoveDrag,
                ),
              ),
              for (var corner = 0; corner < 4; corner++)
                Positioned(
                  left: (corner == 0 || corner == 2
                          ? cropRect.left
                          : cropRect.right) -
                      14,
                  top: (corner == 0 || corner == 1
                          ? cropRect.top
                          : cropRect.bottom) -
                      14,
                  width: 28,
                  height: 28,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) => _onHandleDrag(corner, details),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({
    required this.cropRect,
    required this.color,
    required this.borderColor,
  });

  final Rect cropRect;
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dimPaint = Paint()..color = color;
    final full = Offset.zero & size;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(full),
        Path()..addRect(cropRect),
      ),
      dimPaint,
    );
    canvas.drawRect(
      cropRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor;
}
