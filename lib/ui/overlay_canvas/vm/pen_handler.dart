part of 'handler.dart';

// lib/domain/tools/handlers/pen_handler.dart
class PenHandler extends ToolHandler {
  final ToolContext _context;

  PenHandler(this._context) {
    // logger.d(
    //     'PenHandler: Created new instance - Page: ${_currentStroke?.pageNumber}');
  }

  @override
  ToolContext get context => _context;

  @override
  void onPanStart(
      DragStartDetails details, PageNumber pageNumber, double scale) {
    logger.i(
        'PenHandler: onPanStart started - Page: ${_currentStroke?.pageNumber}');
    // print('PenHandler: onPanStart 开始 - 页码: ${_currentStroke?.pageNumber}');
    final point = context.toPageCoordinate(details.localPosition, scale);

    _currentStroke = Stroke(
      paint: Paint()
        ..color = context.drawingVm.penColor
        ..strokeWidth = context.drawingVm.penWidth / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
      pageNumber: pageNumber,
      tool: Pen(),
      initialPoints: [Point(point.dx, point.dy)],
    );
    logger.d(
        'PenHandler: Created new stroke - Page: ${_currentStroke?.pageNumber}, Initial point: ${_currentStroke?.points}');
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    logger.i(
        'PenHandler: onPanUpdate started - Page: ${_currentStroke?.pageNumber}');
    if (_currentStroke != null) {
      final point = context.toPageCoordinate(details.localPosition, scale);
      _currentStroke!.points.add(Point(point.dx, point.dy));
      //   try {
      //     _currentStroke!.points.add(Point(point.dx, point.dy));
      //     print('PenHandler: onPanUpdate 添加点 - 页码: ${_currentStroke?.pageNumber}, 当前点数: ${_currentStroke!.points.length}');
      //   } catch (e, stackTrace) {
      //     print('PenHandler: onPanUpdate 错误: $e');
      //     print('堆栈跟踪: $stackTrace');
      //   }
      // } else {
      //   print('PenHandler: onPanUpdate 警告 - _currentStroke 为空');
    }
  }

  @override
  void onPanEnd(DragEndDetails details) {
    logger.i(
        'PenHandler: onPanEnd started - Page: ${_currentStroke?.pageNumber}');
    if (_currentStroke != null) {
      try {
        logger.d(
            'PenHandler: Adding stroke - Page: ${_currentStroke?.pageNumber}, Points: ${_currentStroke!.points.length}');
        context.markerVm.addStroke(_currentStroke!, _currentStroke!.pageNumber);
        logger.d(
            'PenHandler: Stroke added successfully - Points: ${_currentStroke!.points.length}');
      } catch (e, stackTrace) {
        logger.e('PenHandler: Error adding stroke',
            error: e, stackTrace: stackTrace);
      }
      _currentStroke = null;
    } else {
      logger.w('PenHandler: _currentStroke is null');
    }
  }

  @override
  void draw(Canvas canvas, Size size) {
    if (_currentStroke != null) {
      logger.v(
          'PenHandler: Drawing current stroke - Page: ${_currentStroke?.pageNumber}, Points: ${_currentStroke!.points.length}');
      _currentStroke!.tool.draw(canvas, _currentStroke!.paint, _currentStroke!);
    }
  }

  @override
  void onActivate() {
    logger
        .d('PenHandler: Tool activated - Page: ${_currentStroke?.pageNumber}');
  }

  @override
  void onDeactivate() {
    logger.d(
        'PenHandler: Tool deactivated - Page: ${_currentStroke?.pageNumber}');
    clearCurrentStroke();
  }

  @override
  void dispose() {
    logger.d('PenHandler: Disposed - Page: ${_currentStroke?.pageNumber}');
    clearCurrentStroke();
  }
}
