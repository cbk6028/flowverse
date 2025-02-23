// lib/domain/tools/context/tool_context.dart
import 'dart:math';

import 'package:flowverse/config/type.dart';
import 'package:flowverse/domain/models/tool/lasso.dart';
import 'package:flowverse/domain/models/tool/marker.dart';
import 'package:flowverse/domain/models/tool/pen.dart';
import 'package:flowverse/domain/models/tool/shape.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flowverse/ui/canvas_overlay/vm/drawing_vm.dart';
import 'package:flowverse/ui/canvas_overlay/widgets/drawing_overlay.dart';
import 'package:flowverse/ui/maker_overlay/vm/marker_vm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

part 'pen_handler.dart';
part 'shape_handler.dart';
part 'marker_handler.dart';
part 'lasso_handler.dart';
part 'text_handler.dart';
part 'image_handler.dart';
part 'eraser_handler.dart';

// lib/domain/tools/config/tool_config.dart
abstract class ToolConfig {
  final Color color;
  final double width;
  final double opacity;

  const ToolConfig({
    required this.color,
    required this.width,
    required this.opacity,
  });
}

class PenConfig extends ToolConfig {
  final StrokeCap strokeCap;
  final StrokeJoin strokeJoin;

  const PenConfig({
    required super.color,
    required super.width,
    required super.opacity,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
  });
}

class ShapeConfig extends ToolConfig {
  final ShapeType shapeType;
  final Color fillColor;
  final double fillOpacity;

  const ShapeConfig({
    required super.color,
    required super.width,
    required super.opacity,
    required this.shapeType,
    required this.fillColor,
    required this.fillOpacity,
  });
}

// lib/domain/tools/context/tool_context.dart
class ToolContext {
  // final BuildContext context;
  final MarkerViewModel markerVm;
  final DrawingViewModel drawingVm;
  // final PdfPage page;
  // late double scale;
  // final Size pageSize;
  // final Rect pageRect;

  ToolContext({
    // required this.context,
    required this.markerVm,
    required this.drawingVm,
    // required this.page,
    // required this.scale,
    // required this.pageSize,
    // required this.pageRect,
  }) {
    // scale = pageRect.width / page.width;
    // print('ToolContext: 初始化 - 当前页码: ${page.pageNumber}');
  }

  // 坐标转换方法
  Offset toPageCoordinate(Offset screenPoint, double scale) {
    // print('ToolContext: 坐标转换 - 当前页码: ${page.pageNumber}');
    return Offset(screenPoint.dx / scale, screenPoint.dy / scale);
  }

  // 获取当前工具配置
  ToolConfig get currentToolConfig => drawingVm.currentToolConfig;
}

// lib/domain/tools/handlers/base/tool_handler.dart
abstract class ToolHandler {
  ToolContext get context;
  late PageNumber pageNumber;
  late double scale;
  Stroke? _currentStroke;

  Stroke? get currentStroke => _currentStroke;

  // 添加保存笔画的方法
  void saveStroke(PageNumber pageNumber) {
    if (_currentStroke != null) {
      context.markerVm.addStroke(_currentStroke!, pageNumber);
      _currentStroke = null;
    }
  }

  // 清除当前笔画
  void clearCurrentStroke() {
    _currentStroke = null;
  }

  void onPanStart(
      DragStartDetails details, PageNumber pageNumber, double scale);
  void onPanUpdate(DragUpdateDetails details, double scale);
  // 移除默认实现，让子类必须实现
  void onPanEnd(DragEndDetails details);

  void onPointerMove(PointerMoveEvent event) {
    // print("");
  }

  void onPointerHover(PointerHoverEvent event) {}
  void onPointerDown(PointerDownEvent event) {}

  void onActivate();
  void onDeactivate() {
    // 停用时清除当前笔画
    clearCurrentStroke();
  }

  // 绘制方法
  void draw(Canvas canvas, Size size);

  // 清理资源
  void dispose();
}

// lib/domain/tools/factory/tool_factory.dart
class ToolFactory {
  static final Map<ToolType, ToolHandler> _toolCache = {};

  static ToolHandler createHandler(ToolType type, ToolContext context) {
    print('ToolFactory: 创建工具处理器 - 类型: $type');

    // 如果缓存中存在，先清理旧的handler
    if (_toolCache.containsKey(type)) {
      print('ToolFactory: 发现缓存的处理器，准备清理');
      _toolCache[type]!.dispose();
      _toolCache.remove(type);
      print('ToolFactory: 旧处理器已清理');
    }

    // 创建新的handler
    print('ToolFactory: 创建新的处理器');
    final handler = _createNewHandler(type, context);
    _toolCache[type] = handler;
    print('ToolFactory: 新处理器已创建并缓存');
    return handler;
  }

  static ToolHandler _createNewHandler(ToolType type, ToolContext context) {
    print('ToolFactory: _createNewHandler - 创建类型: $type');
    final handler = switch (type) {
      ToolType.pen => PenHandler(context),
      ToolType.marker => MarkerHandler(context),
      ToolType.shape => ShapeHandler(context),
      ToolType.eraser => EraserHandler(context),
      ToolType.lasso => LassoHandler(context),
      _ => throw Exception('未知工具类型: $type'),
    };
    print('ToolFactory: _createNewHandler - 创建完成: ${handler.runtimeType}');
    return handler;
  }

  // 获取当前活动的工具
  static ToolHandler? getCurrentHandler(ToolType strokeType) {
    print('ToolFactory: 获取当前处理器 - 类型: $strokeType');
    final handler = _toolCache[strokeType];
    print('ToolFactory: 当前处理器${handler != null ? "存在" : "不存在"}');
    return handler;
  }

  // 清理所有工具
  static void dispose() {
    print('ToolFactory: 开始清理所有工具');
    for (var handler in _toolCache.values) {
      handler.dispose();
    }
    _toolCache.clear();
    print('ToolFactory: 所有工具已清理完成');
  }
}

// lib/domain/tools/manager/tool_manager.dart
class ToolManager {
  late ToolHandler _currentHandler;
  ToolContext _context;

  ToolContext get context => _context;
  ToolHandler get currentHandler => _currentHandler;

  ToolManager(this._context) {
    // print('ToolManager: 初始化中... 页码: ${_context.page.pageNumber}');
    _currentHandler = ToolFactory.createHandler(ToolType.pen, _context);
    _currentHandler.onActivate();
    print('ToolManager: 初始化完成，当前工具: ${_currentHandler.runtimeType}');
  }

  void switchTool(ToolType type) {
    print('ToolManager: 切换工具 - 从 ${_currentHandler.runtimeType} 到 $type');
    // print('ToolManager: 当前页码: ${_context.page.pageNumber}');
    _currentHandler.onDeactivate();
    _currentHandler = ToolFactory.createHandler(type, _context);
    _currentHandler.onActivate();
    print('ToolManager: 工具切换完成 - 当前工具: ${_currentHandler.runtimeType}');
  }

  void handlePanStart(
      DragStartDetails details, PageNumber pageNumber, double scale) {
    print('ToolManager: 处理 PanStart - 当前工具: ${_currentHandler.runtimeType}');
    // print('ToolManager: 当前页码: ${_context.page.pageNumber}');
    _currentHandler.onPanStart(details, pageNumber, scale);
  }

  void handlePanUpdate(DragUpdateDetails details, double scale) {
    print('ToolManager: 处理 PanUpdate - 当前工具: ${_currentHandler.runtimeType}');
    // print('ToolManager: 当前页码: ${_context.page.pageNumber}');
    _currentHandler.onPanUpdate(details, scale);
  }

  void handlePanEnd(DragEndDetails details) {
    print('ToolManager: 处理 PanEnd - 当前工具: ${_currentHandler.runtimeType}');
    // print('ToolManager: 当前页码: ${_context.page.pageNumber}');
    _currentHandler.onPanEnd(details);
  }

  void handlePointerMove(PointerMoveEvent event) {
    _currentHandler.onPointerMove(event);
  }
  void handlePointerHover(PointerHoverEvent event) {
    _currentHandler.onPointerHover(event);
  }
  void handlePointerDown(PointerDownEvent event) {
    _currentHandler.onPointerDown(event);
  }


  void dispose() {
    print('ToolManager: 销毁所有工具');
    ToolFactory.dispose();
  }
}
