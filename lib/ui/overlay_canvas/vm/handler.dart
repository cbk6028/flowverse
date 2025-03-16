// lib/domain/tools/context/tool_context.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flov/config/type.dart';
import 'package:flov/domain/models/tool/image.dart';
import 'package:flov/domain/models/tool/lasso.dart';
import 'package:flov/domain/models/tool/marker.dart';
import 'package:flov/domain/models/tool/pen.dart';
import 'package:flov/domain/models/tool/shape.dart';
import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/domain/models/tool/text.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flov/ui/overlay_canvas/vm/drawing_vm.dart';
import 'package:flov/ui/overlay_canvas/widgets/drawing_overlay.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flov/utils/logger.dart';

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
    // logger.d('ToolContext: Initialized - Current page: ${page.pageNumber}');
  }

  // 坐标转换方法
  Offset toPageCoordinate(Offset screenPoint, double scale) {
    // logger.d('ToolContext: Coordinate conversion - Current page: ${page.pageNumber}');
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
  void onPanUpdate(DragUpdateDetails details);
  // 移除默认实现，让子类必须实现
  void onPanEnd(DragEndDetails details);

  void onPointerMove(PointerMoveEvent event) {
    // logger.d("");
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
    logger.d('ToolFactory: Creating tool handler - Type: $type');

    // 如果缓存中存在，先清理旧的handler
    if (_toolCache.containsKey(type)) {
      logger.d('ToolFactory: Found cached handler, cleaning up');
      _toolCache[type]!.dispose();
      _toolCache.remove(type);
      logger.d('ToolFactory: Old handler cleaned up');
    }

    // 创建新的handler
    logger.d('ToolFactory: Creating new handler');
    final handler = _createNewHandler(type, context);
    _toolCache[type] = handler;
    logger.d('ToolFactory: New handler created and cached');
    return handler;
  }

  static ToolHandler _createNewHandler(ToolType type, ToolContext context) {
    logger.d('ToolFactory: _createNewHandler - Creating type: $type');
    final handler = switch (type) {
      ToolType.pen => PenHandler(context),
      ToolType.marker => MarkerHandler(context),
      ToolType.shape => ShapeHandler(context),
      ToolType.eraser => EraserHandler(context),
      ToolType.lasso => LassoHandler(context),
      ToolType.text => TextHandler(context),
      _ => throw Exception('未知工具类型: $type'),
    };
    logger.d('ToolFactory: _createNewHandler - Created: ${handler.runtimeType}');
    return handler;
  }

  // 获取当前活动的工具
  static ToolHandler? getCurrentHandler(ToolType strokeType) {
    logger.d('ToolFactory: Getting current handler - Type: $strokeType');
    final handler = _toolCache[strokeType];
    logger.d('ToolFactory: Current handler ${handler != null ? "exists" : "does not exist"}');
    return handler;
  }

  // 清理所有工具
  static void dispose() {
    logger.i('ToolFactory: Disposing all tools');
    for (var handler in _toolCache.values) {
      handler.dispose();
    }
    _toolCache.clear();
    logger.i('ToolFactory: All tools disposed');
  }
}

// lib/domain/tools/manager/tool_manager.dart
class ToolManager {
  late ToolHandler _currentHandler;
  final ToolContext _context;

  ToolContext get context => _context;
  ToolHandler get currentHandler => _currentHandler;

  ToolManager(this._context) {
    // logger.d('ToolManager: Initializing... Page: ${_context.page.pageNumber}');
    _currentHandler = ToolFactory.createHandler(ToolType.pen, _context);
    _currentHandler.onActivate();
    logger.d('ToolManager: Initialized, current tool: ${_currentHandler.runtimeType}');
  }

  void switchTool(ToolType type) {
    logger.d('ToolManager: Switching tool - From ${_currentHandler.runtimeType} to $type');
    // logger.d('ToolManager: Current page: ${_context.page.pageNumber}');
    _currentHandler.onDeactivate();
    _currentHandler = ToolFactory.createHandler(type, _context);
    _currentHandler.onActivate();
    logger.d('ToolManager: Tool switched, current tool: ${_currentHandler.runtimeType}');
  }

  void handlePanStart(
      DragStartDetails details, PageNumber pageNumber, double scale) {
    logger.d('ToolManager: Handling PanStart - Current tool: ${_currentHandler.runtimeType}');

    _currentHandler.onPanStart(details, pageNumber, scale);
  }

  void handlePanUpdate(DragUpdateDetails details) {
    logger.d('ToolManager: Handling PanUpdate - Current tool: ${_currentHandler.runtimeType}');
    // logger.d('ToolManager: Current page: ${_context.page.pageNumber}');
    _currentHandler.onPanUpdate(details);
  }

  void handlePanEnd(DragEndDetails details) {
    logger.d('ToolManager: Handling PanEnd - Current tool: ${_currentHandler.runtimeType}');
    // logger.d('ToolManager: Current page: ${_context.page.pageNumber}');
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
    logger.i('ToolManager: Disposing all tools');
    ToolFactory.dispose();
  }
}
