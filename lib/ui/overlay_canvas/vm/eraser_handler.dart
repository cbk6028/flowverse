// lib/ui/canvas_overlay/vm/eraser_handler.dart
part of 'handler.dart';

class EraserHandler extends ToolHandler {
  final ToolContext _context;
  Offset? _currentPosition;
  bool _isPointerInside = false;
  final bool _isTransforming = false;
  EraserHandler(this._context);

  Offset? get currentPosition => _currentPosition;

  @override
  ToolContext get context => _context;

  // 橡皮擦没有笔画
  @override
  Stroke? get currentStroke => null;

  // 获取橡皮擦大小
  double get _eraserSize => context.drawingVm.eraserSize;

  // 检查是否可以擦除笔画
  bool _canEraseStroke(Stroke stroke, Offset point) {
    for (var p in stroke.points) {
      final distance =
          (Offset(p.x.toDouble(), p.y.toDouble()) - point).distance;
      if (distance < _eraserSize) {
        return true;
      }
    }
    return false;
  }

  // 擦除指定点的笔画
  // void _eraseAtPoint(Offset point, PageNumber pageNumber) {
  //   final pageStrokes = context.markerVm.archive.strokes[pageNumber] ?? [];
  //   final strokesToRemove = <Stroke>[];

  //   for (final stroke in pageStrokes) {
  //     if (_canEraseStroke(stroke, point)) {
  //       strokesToRemove.add(stroke);
  //     }
  //   }

  //   if (strokesToRemove.isNotEmpty) {
  //     for (final stroke in strokesToRemove) {
  //       context.markerVm.removeStroke(this.pageNumber, stroke);
  //     }
  //   }
  // }

  double _calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  Rect _calculateShapeBounds(List<Point> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points[0].x as double;
    double minY = points[0].y as double;
    double maxX = minX;
    double maxY = minY;

    for (var point in points) {
      final x = point.x as double;
      final y = point.y as double;
      minX = min(minX, x);
      minY = min(minY, y);
      maxX = max(maxX, x);
      maxY = max(maxY, y);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _eraseAtPoint(Offset point, PageNumber pageNumber) {
    logger.i('EraserHandler: Archive: ${context.markerVm.archive.strokes}');
    if (context.markerVm.archive.strokes[pageNumber] == null) {
      return;
    }
    final pageStrokes = context.markerVm.archive.strokes[pageNumber]!;
    var eraserRadius = context.drawingVm.eraserSize;
    // 检查每个笔画
    for (var i = pageStrokes.length - 1; i >= 0; i--) {
      final stroke = pageStrokes[i];
      bool shouldErase = false;

      if (stroke.tool is Shape) {
        // 对于形状，我们需要检查整个形状区域
        final bounds = _calculateShapeBounds(stroke.points);
        final expandedBounds = Rect.fromLTWH(
            bounds.left - eraserRadius,
            bounds.top - eraserRadius,
            bounds.width + eraserRadius * 2,
            bounds.height + eraserRadius * 2);

        if (expandedBounds.contains(point)) {
          shouldErase = true;
        }
      } else {
        // 对于笔和马克笔，检查每个点
        for (var j = 0; j < stroke.points.length; j++) {
          final strokePoint = stroke.points[j];
          final distance = _calculateDistance(
            point,
            Offset(strokePoint.x as double, strokePoint.y as double),
          );

          // 如果点在橡皮擦范围内
          if (distance <= eraserRadius) {
            shouldErase = true;
            break;
          }
        }
      }

      if (shouldErase) {
        context.markerVm.removeStroke(pageNumber, stroke);
      }
    }
  }

  // 处理指针移动事件
  @override
  void onPointerMove(PointerMoveEvent event) {
    final point = context.toPageCoordinate(event.localPosition, scale);
    _currentPosition = point;
    _isPointerInside = true;
    // _eraseAtPoint(point, this.pageNumber);
  }

  // 处理指针悬停事件
  @override
  void onPointerHover(PointerHoverEvent event) {
    final point = context.toPageCoordinate(event.localPosition, scale);
    _currentPosition = point;
    _isPointerInside = true;
  }

  // 处理指针离开事件
  @override
  void onPointerDown(PointerDownEvent event) {
    _currentPosition = null;
    _isPointerInside = false;
  }

  @override
  void onPanStart(
      DragStartDetails details, PageNumber pageNumber, double scale) {
    final point = context.toPageCoordinate(details.localPosition, scale);
    _currentPosition = point;
    // 不能改成 this.pageNumber ？
    _eraseAtPoint(point, pageNumber);

    this.pageNumber = pageNumber;
    this.scale = scale;
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    final point = context.toPageCoordinate(details.localPosition, scale);
    _currentPosition = point;
    _eraseAtPoint(point, pageNumber);
  }

  @override
  void onPanEnd(DragEndDetails details) {
    // 保持当前位置，但停止擦除
  }

  @override
  void draw(Canvas canvas, Size size) {
    if (_currentPosition == null) {
      logger.e('Current position is null');
    }
    
    if (_currentPosition != null) {
      print('橡皮擦绘制信息:');
      print('当前位置: $_currentPosition');
      print('橡皮擦大小: $_eraserSize');
      print('画布大小: $size');
      print('缩放比例: $scale');

      final paint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // 绘制外圈
      canvas.drawCircle(
        _currentPosition!,
        _eraserSize * 2,
        paint..style = PaintingStyle.stroke,
      );

      // 绘制内圈
      canvas.drawCircle(
        _currentPosition!,
        _eraserSize / 2,
        paint
          ..style = PaintingStyle.fill
          ..color = Colors.red.withOpacity(0.1),
      );
    }
  }

  @override
  void onActivate() {
    _currentPosition = null;
    _isPointerInside = false;
  }

  @override
  void onDeactivate() {
    _currentPosition = null;
    _isPointerInside = false;
  }

  @override
  void dispose() {
    _currentPosition = null;
    _isPointerInside = false;
  }
}
