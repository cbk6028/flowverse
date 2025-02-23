// lib/ui/canvas_overlay/vm/lasso_handler.dart
part of 'handler.dart';

class LassoHandler extends ToolHandler {
  final ToolContext _context;
  final LassoSelection _lassoSelection = LassoSelection();
  ControlPoint? _activeControlPoint;
  bool _isTransforming = false;
  LassoHandler(this._context);

  @override
  ToolContext get context => _context;

  @override
  void onPanStart(
      DragStartDetails details, PageNumber pageNumber, double scale) {
    final point = context.toPageCoordinate(details.localPosition, scale);

    // 检查是否点击了选择框
    if (_lassoSelection.selectionRect != null) {
      // 首先检查控制点
      final controlPoint = _lassoSelection.getControlPoint(
          _lassoSelection.selectionRect!, point);

      if (controlPoint != null) {
        _activeControlPoint = controlPoint;
        _lassoSelection.dragStartOffset = point;
        _lassoSelection.originalPositions = _lassoSelection.selectedStrokes
            .expand((stroke) => stroke.points)
            .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
            .toList();
        return;
      }

      // 然后检查选择框内部
      if (_lassoSelection.isPointOnSelectionRect(point)) {
        _lassoSelection.isDraggingSelection = true;
        _lassoSelection.dragStartOffset = point;
        _lassoSelection.originalPositions = _lassoSelection.selectedStrokes
            .expand((stroke) => stroke.points)
            .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
            .toList();
        return;
      }

      // 如果点击在选择框外部，清除选择
      _lassoSelection.clearSelection();
    }

    // 开始新的套索选择
    _lassoSelection.clearSelection();
    _lassoSelection.lassoPath = Path();
    _lassoSelection.lassoPath!.moveTo(point.dx, point.dy);

    _currentStroke = Stroke(
      paint: Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 1 / scale
        ..style = PaintingStyle.stroke,
      pageNumber: pageNumber,
      tool: Lasso(),
      initialPoints: [Point(point.dx, point.dy)],
    );

    this.pageNumber = pageNumber;
    this.scale = scale;
  }

  @override
  void onPanUpdate(DragUpdateDetails details, double scale) {
    final point = context.toPageCoordinate(details.localPosition, this.scale);

    // 处理控制点拖动
    if (_activeControlPoint != null && _lassoSelection.selectionRect != null) {
      if (_activeControlPoint == ControlPoint.rotate) {
        _lassoSelection.handleRotation(point);
      } else {
        _lassoSelection.handleControlPointDrag(_activeControlPoint!, point);
        _lassoSelection.resizeStrokes();
      }
      return;
    }

    // 处理选择框拖动
    if (_lassoSelection.isDraggingSelection &&
        _lassoSelection.dragStartOffset != null) {
      final delta = point - _lassoSelection.dragStartOffset!;
      _lassoSelection.moveSelectedStrokes(delta);
      _lassoSelection.dragStartOffset = point;
      return;
    }

    // 处理套索绘制
    if (_currentStroke != null) {
      _lassoSelection.updateLassoPath(point);
      _currentStroke!.points.add(Point(point.dx, point.dy));
    }

    if (_isTransforming && _activeControlPoint != null) {
      // _handleTransform(details.localPosition);
      _lassoSelection.handleTransform(details.localPosition);
    }
  }

  @override
  void onPanEnd(DragEndDetails details) {
    if (_lassoSelection.isDraggingSelection) {
      _lassoSelection.isDraggingSelection = false;
      _lassoSelection.dragStartOffset = null;
      _lassoSelection.originalPositions.clear();
    }

    if (_currentStroke != null && _lassoSelection.lassoPath != null) {
      final strokes = context.markerVm.archive.strokes[this.pageNumber] ?? [];
      _lassoSelection.handleLassoEnd(strokes);
      _currentStroke = null;
    }
    _isTransforming = false;
    _activeControlPoint = null;
  }

  @override
  void draw(Canvas canvas, Size size) {
    // 绘制套索选择区域
    print('lassopath ${_lassoSelection.lassoPath}');
    if (_lassoSelection.lassoPath != null) {
      final lassoPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawPath(_lassoSelection.lassoPath!, lassoPaint);

      final lassoStrokePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(_lassoSelection.lassoPath!, lassoStrokePaint);
    }
    void _paintStroke(Canvas canvas, Stroke stroke) {
      if (stroke.points.isEmpty) return;
      stroke.tool.draw(canvas, stroke.paint, stroke);
    }

    // 绘制选中效果
    for (final stroke in _lassoSelection.selectedStrokes) {
      // final selectedPaint = Paint()
      //   ..color = Colors.blue.withOpacity(0.2)
      //   ..style = PaintingStyle.stroke
      //   ..strokeWidth = stroke.paint.strokeWidth + 4;
      _paintStroke(canvas, stroke);
    }

    // 绘制选择框
    if (_lassoSelection.selectionRect != null) {
      canvas.save();

      // 应用旋转变换
      canvas.translate(_lassoSelection.selectionRect!.center.dx,
          _lassoSelection.selectionRect!.center.dy);
      // canvas.rotate(1);
      canvas.translate(-_lassoSelection.selectionRect!.center.dx,
          -_lassoSelection.selectionRect!.center.dy);

      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 绘制主矩形
      canvas.drawRect(_lassoSelection.selectionRect!, selectionPaint);

      // 绘制控制点
      final controlPoints = [
        _lassoSelection.selectionRect!.topLeft,
        _lassoSelection.selectionRect!.topRight,
        _lassoSelection.selectionRect!.bottomLeft,
        _lassoSelection.selectionRect!.bottomRight,
      ];

      // 绘制旋转控制点
      final rotatePoint = Offset(
        _lassoSelection.selectionRect!.center.dx,
        _lassoSelection.selectionRect!.top - 30,
      );

      // 绘制旋转控制点到矩形顶边的连接线
      canvas.drawLine(
        Offset(_lassoSelection.selectionRect!.center.dx,
            _lassoSelection.selectionRect!.top),
        rotatePoint,
        selectionPaint,
      );

      // 绘制所有控制点
      final allPoints = [...controlPoints, rotatePoint];
      for (var point in allPoints) {
        canvas.drawCircle(
          point,
          4.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          point,
          4.0,
          Paint()
            ..color = Colors.blue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }

      canvas.restore();

      // 如果有选中的笔画，也需要应用相同的变换
      if (_lassoSelection.selectedStrokes.isNotEmpty) {
        canvas.save();
        canvas.translate(_lassoSelection.selectionRect!.center.dx,
            _lassoSelection.selectionRect!.center.dy);
        // canvas.rotate(1);
        canvas.translate(-_lassoSelection.selectionRect!.center.dx,
            -_lassoSelection.selectionRect!.center.dy);

        for (final stroke in _lassoSelection.selectedStrokes) {
          // final selectedPaint = Paint()
          //   ..color = Colors.blue.withOpacity(0.2)
          //   ..style = PaintingStyle.stroke
          //   ..strokeWidth = stroke.paint.strokeWidth + 4;
          _paintStroke(canvas, stroke);
        }

        canvas.restore();
      }
    }
  }

  void _drawSelectionRect(Canvas canvas) {
    canvas.save();

    // 应用旋转变换
    final rect = _lassoSelection.selectionRect!;
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(_lassoSelection.rotationAngle);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    // 绘制选择框
    final selectionPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, selectionPaint);

    // 绘制控制点
    final controlPoints = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    // 绘制旋转控制点
    final rotatePoint = Offset(
      rect.center.dx,
      rect.top - 30,
    );

    // 绘制旋转控制点到矩形顶边的连接线
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      rotatePoint,
      selectionPaint,
    );

    // 绘制所有控制点
    final allPoints = [...controlPoints, rotatePoint];
    for (var point in allPoints) {
      canvas.drawCircle(
        point,
        4.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        point,
        4.0,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    canvas.restore();
  }

  @override
  void onActivate() {
    // 工具激活时的处理
  }

  @override
  void onDeactivate() {
    // 工具停用时的处理
    _currentStroke = null;
    _lassoSelection.clearSelection();
  }

  @override
  void dispose() {
    _currentStroke = null;
    _lassoSelection.clearSelection();
  }
}
