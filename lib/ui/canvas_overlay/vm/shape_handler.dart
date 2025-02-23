// lib/ui/canvas_overlay/vm/shape_handler.dart
part of 'handler.dart';

class ShapeHandler extends ToolHandler {
  final ToolContext _context;
  
  ShapeHandler(this._context);

  @override
  ToolContext get context => _context;

  @override
  void onPanStart(DragStartDetails details, PageNumber pageNumber, double scale) {
    final point = context.toPageCoordinate(details.localPosition, scale);
    
    // 创建填充画笔
    final fillPaint = Paint()
      ..color = context.drawingVm.shapeFillColor
          .withOpacity(context.drawingVm.shapeFillOpacity)
      ..style = PaintingStyle.fill;

    // 只对封闭图形设置填充画笔
    final bool isClosedShape = [
      ShapeType.rectangle,
      ShapeType.circle,
      ShapeType.triangle,
      ShapeType.star,
    ].contains(context.drawingVm.currentShape);

    Tool tool = Shape(
      context.drawingVm.currentShape,
      fillPaint: isClosedShape ? fillPaint : null,
    );

    _currentStroke = Stroke(
      paint: Paint()
        ..color = context.drawingVm.shapeColor
        ..strokeWidth = context.drawingVm.shapeWidth / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
      pageNumber: pageNumber,
      tool: tool,
      initialPoints: [Point(point.dx, point.dy)],
    );
  }

  @override
  void onPanUpdate(DragUpdateDetails details, double scale) {
    if (_currentStroke != null) {
      final point = context.toPageCoordinate(details.localPosition, scale);
      
      // 对于形状，我们只需要更新最后一个点
      if (_currentStroke!.points.length > 1) {
        _currentStroke!.points.removeLast();
      }
      _currentStroke!.points.add(Point(point.dx, point.dy));
    }
  }

  @override
  void onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      context.markerVm.addStroke(_currentStroke!, _currentStroke!.pageNumber);
      _currentStroke = null;
    }
  }

  @override
  void draw(Canvas canvas, Size size) {
    if (_currentStroke != null) {
      _currentStroke!.tool.draw(canvas, _currentStroke!.paint, _currentStroke!);
    }
  }

  @override
  void onActivate() {
    // 工具激活时的处理
  }

  @override
  void onDeactivate() {
    // 工具停用时的处理
    _currentStroke = null;
  }

  @override
  void dispose() {
    _currentStroke = null;
  }
}
