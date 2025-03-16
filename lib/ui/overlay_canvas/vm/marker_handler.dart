
// lib/ui/canvas_overlay/vm/marker_handler.dart
part of 'handler.dart';

class MarkerHandler extends ToolHandler {
  final ToolContext _context;
  
  MarkerHandler(this._context);

  @override
  ToolContext get context => _context;

  @override
  void onPanStart(DragStartDetails details, PageNumber pageNumber, double scale) {
    final point = context.toPageCoordinate(details.localPosition, scale);
    
    _currentStroke = Stroke(
      paint: Paint()
        ..color = context.drawingVm.markerColor
            .withOpacity(context.drawingVm.markerOpacity)
        ..strokeWidth = context.drawingVm.markerWidth / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver,
      pageNumber: pageNumber,
      tool: MTool(),
      initialPoints: [Point(point.dx, point.dy)],
    );
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke != null) {
      final point = context.toPageCoordinate(details.localPosition, scale);
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