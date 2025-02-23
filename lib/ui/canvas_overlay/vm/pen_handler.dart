part of 'handler.dart';

// lib/domain/tools/handlers/pen_handler.dart
class PenHandler extends ToolHandler {
  final ToolContext _context;

  PenHandler(this._context) {
    // print('PenHandler: 创建新实例 - 页码: ${_context.page.pageNumber}');
  }

  @override
  ToolContext get context => _context;

  @override
  void onPanStart(DragStartDetails details, PageNumber pageNumber, double scale) {
    // print('PenHandler: onPanStart 开始 - 页码: ${_context.page.pageNumber}');
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
    print('PenHandler: onPanStart 创建新笔画 - 页码: ${_currentStroke?.pageNumber}, 初始点: ${_currentStroke?.points}');
  }

  @override
  void onPanUpdate(DragUpdateDetails details, double scale) {
    if (_currentStroke != null) {
      final point = context.toPageCoordinate(details.localPosition , scale);
      try {
        _currentStroke!.points.add(Point(point.dx, point.dy));
        print('PenHandler: onPanUpdate 添加点 - 页码: ${_currentStroke!.pageNumber}, 当前点数: ${_currentStroke!.points.length}');
      } catch (e, stackTrace) {
        print('PenHandler: onPanUpdate 错误: $e');
        print('堆栈跟踪: $stackTrace');
      }
    } else {
      print('PenHandler: onPanUpdate 警告 - _currentStroke 为空');
    }
  }

  @override
  void onPanEnd(DragEndDetails details) {
    // print('PenHandler: onPanEnd 开始 - 页码: ${_context.page.pageNumber}');
    if (_currentStroke != null) {
      try {
        print('PenHandler: onPanEnd 准备添加笔画 - 页码: ${_currentStroke!.pageNumber}, 点数: ${_currentStroke!.points.length}');
        context.markerVm.addStroke(_currentStroke!, _currentStroke!.pageNumber);
        print('PenHandler: onPanEnd 笔画添加成功');
      } catch (e, stackTrace) {
        print('PenHandler: onPanEnd 错误: $e');
        print('堆栈跟踪: $stackTrace');
      }
      _currentStroke = null;
    } else {
      print('PenHandler: onPanEnd 警告 - _currentStroke 为空');
    }
  }

  @override
  void draw(Canvas canvas, Size size) {
    if (_currentStroke != null) {
      print('PenHandler: draw 绘制当前笔画 - 页码: ${_currentStroke!.pageNumber}, 点数: ${_currentStroke!.points.length}');
      _currentStroke!.tool.draw(canvas, _currentStroke!.paint, _currentStroke!);
    }
  }

  @override
  void onActivate() {
    // print('PenHandler: 工具激活 - 页码: ${_context.page.pageNumber}');
  }

  @override
  void onDeactivate() {
    // print('PenHandler: 工具停用 - 页码: ${_context.page.pageNumber}');
    clearCurrentStroke();
  }

  @override
  void dispose() {
    // print('PenHandler: 销毁 - 页码: ${_context.page.pageNumber}');
    clearCurrentStroke();
  }
}
