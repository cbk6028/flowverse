import 'dart:ui' as ui;

import 'package:flowverse/models/lasso.dart';
import 'package:flowverse/models/marker.dart';
import 'package:flowverse/models/pen.dart';
import 'package:flowverse/models/shape.dart';
import 'package:flowverse/models/text.dart';
import 'package:flowverse/models/tool.dart';
import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/widgets/canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/provider/drawing_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';

part 'lasso.dart';

class DrawingOverlay extends StatefulWidget {
  final Rect pageRect;
  final PdfPage page;

  DrawingOverlay({
    Key? key,
    required this.pageRect,
    required this.page,
  }) : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  Stroke? _currentStroke;
  bool _isPointerInside = false;
  Offset? _currentEraserPosition;
  List<Stroke> selectedStrokes = [];
  // Path? _lassoPath;
  Rect? selectionRect; // 选择框矩形
  bool _isDraggingSelection = false; // 是否正在拖动选择框

  // Offset? _dragStartOffset; // 拖动起始点
  // List<Offset> _originalPositions = []; // 存储选中笔画的原始位置
  TextEditingController? _textController;
  FocusNode? _focusNode;
  Offset? _textPosition;
  bool _isEditing = false;

  ui.Image? _currentImage;
  Offset? _imagePosition;
  Size? _imageSize;
  bool _isImageSelected = false;

  // Rect? get selectionRect => selectionRect;
  final double _rotationAngle = 0.0;
  // double _scale = 1.0;
  // Offset? _lastFocalPoint;
  bool _isTransforming = false;
  ControlPoint? _activeControlPoint;
  // Offset? _rotationCenter;

  // 套索选择管理器
  final LassoSelection _lassoSelection = LassoSelection();

  // 处理变换操作
  // void _handleTransform(Offset currentPoint) {
  //   _lassoSelection.handleTransform(currentPoint);
  //   setState(() {});
  // }

  // 处理旋转
  // void _handleRotation(Offset currentPoint) {
  //   _lassoSelection.handleRotation(currentPoint);
  //   setState(() {});
  // }

  // 旋转笔画
  // void _rotateStrokes(double angle) {
  //   if (selectionRect == null ||
  //       selectedStrokes.isEmpty ||
  //       _rotationCenter == null) return;

  //   print('${DateTime.now()} : rotating strokes by $angle radians');

  //   final cosAngle = cos(angle);
  //   final sinAngle = sin(angle);

  //   for (var stroke in selectedStrokes) {
  //     for (var i = 0; i < stroke.points.length; i++) {
  //       final point = stroke.points[i];
  //       final dx = point.x - _rotationCenter!.dx;
  //       final dy = point.y - _rotationCenter!.dy;

  //       // 应用旋转变换
  //       final newX = dx * cosAngle - dy * sinAngle + _rotationCenter!.dx;
  //       final newY = dx * sinAngle + dy * cosAngle + _rotationCenter!.dy;

  //       stroke.points[i] = Point(newX, newY);
  //     }
  //   }

  //   // 更新选择框
  //   _calculateSelectionRect();
  // }

  // 使用PDF原始尺寸的比例计算缩放
  double get scale => widget.pageRect.width / widget.page.width;

  // 转换屏幕坐标到PDF坐标
  Offset _toPageCoordinate(Offset screenPoint) {
    return Offset(screenPoint.dx / scale, screenPoint.dy / scale);
  }

  @override
  void dispose() {
    _textController?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Consumer<MarkerViewModel>(builder: (context, markerVm, child) {
      final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];

      return Consumer<DrawingProvider>(
          builder: (context, drawingProvider, child) {
        // Clear eraser position when not in eraser mode
        bool isEraserMode = drawingProvider.strokeType == ToolType.eraser;
        if (!isEraserMode && _currentEraserPosition != null) {
          _currentEraserPosition = null;
        }

        return Stack(
          children: [
            Listener(
              onPointerMove: (event) {
                if (drawingProvider.strokeType == ToolType.eraser) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  setState(() {
                    _currentEraserPosition = localPosition;
                    _isPointerInside = true;
                  });
                }
              },
              onPointerHover: (event) {
                if (drawingProvider.strokeType == ToolType.eraser) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  setState(() {
                    _currentEraserPosition = localPosition;
                    _isPointerInside = true;
                  });
                }
              },
              onPointerDown: (event) {
                if (drawingProvider.strokeType == ToolType.text) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final point =
                      _toPageCoordinate(box.globalToLocal(event.position));
                  _createNewTextInput(point, context, markerVm);
                }
              },
              child: IgnorePointer(
                ignoring: !drawingProvider.isDrawingMode && !isEraserMode,
                child: GestureDetector(
                  onPanStart: (details) {
                    _handlePanStart(
                        drawingProvider, context, details, markerVm);
                  },
                  onPanUpdate: (details) {
                    _handlePanUpdate(
                        drawingProvider, context, details, markerVm);
                    if (_isTransforming && _activeControlPoint != null) {
                      // _handleTransform(details.localPosition);
                      _lassoSelection.handleTransform(details.localPosition);
                      setState(() {});
                    }
                  },
                  onPanEnd: (details) {
                    _handlePanEnd(drawingProvider, markerVm);
                    _isTransforming = false;
                    _activeControlPoint = null;
                  },
                  child: CustomPaint(
                    painter: Painter(
                      strokes: [
                        ...strokes,
                        if (_currentStroke != null) _currentStroke!
                      ],
                      scale: scale,
                      pageSize: widget.page.size,
                      screenSize: widget.pageRect.size,
                      eraserPosition:
                          _isPointerInside ? _currentEraserPosition : null,
                      eraserSize: drawingProvider.eraserSize,
                      lassoPath: _lassoSelection.lassoPath,
                      selectedStrokes: _lassoSelection.selectedStrokes,
                      selectionRect: _lassoSelection.selectionRect,
                      currentImage: _currentImage,
                      imagePosition: _imagePosition,
                      imageSize: _imageSize,
                      rotationAngle: _rotationAngle,
                    ),
                    size: widget.pageRect.size,
                  ),
                ),
              ),
            ),
            if (_isEditing && _textPosition != null)
              Positioned(
                left: _textPosition!.dx * scale,
                top: _textPosition!.dy * scale,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 200,
                    constraints: BoxConstraints(
                      minHeight: 40,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,
                        width: 1,
                      ),
                      color: Colors.white.withOpacity(0.9),
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          autofocus: true,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.fromLTRB(8, 8, 40, 8),
                            border: InputBorder.none,
                            hintText: '输入文字...',
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: null,
                          onSubmitted: (text) {
                            if (text.isNotEmpty) {
                              _saveText(markerVm);
                            }
                          },
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, size: 16),
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                                onPressed: () => _saveText(markerVm),
                              ),
                              IconButton(
                                icon: Icon(Icons.close, size: 16),
                                padding: EdgeInsets.all(4),
                                constraints: BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _textController?.clear();
                                    _textPosition = null;
                                    _isEditing = false;
                                    _focusNode?.unfocus();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isImageSelected && _imagePosition != null)
              Positioned(
                left: _imagePosition!.dx * scale,
                top: _imagePosition!.dy * scale,
                child: _buildImageControls(),
              ),
          ],
        );
      });
    });
  }

  void _handlePanEnd(
      DrawingProvider drawingProvider, MarkerViewModel markerVm) {
    if (_isDraggingSelection) {
      _isDraggingSelection = false;
      // _dragStartOffset = null;
      // _originalPositions = [];
    }

    if (drawingProvider.strokeType == ToolType.lasso &&
        _lassoSelection.lassoPath != null) {
      final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];
      _lassoSelection.handleLassoEnd(strokes);
      setState(() {
        _currentStroke = null;
      });
    } else if (drawingProvider.isDrawingMode && _currentStroke != null) {
      markerVm.addStroke(_currentStroke!, widget.page.pageNumber);
      _currentStroke = null;
      setState(() {});
    }
  }

  void _handlePanUpdate(DrawingProvider drawingProvider, BuildContext context,
      DragUpdateDetails details, MarkerViewModel markerVm) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final point = _toPageCoordinate(box.globalToLocal(details.globalPosition));

    // 处理控制点拖动
    if (_activeControlPoint != null && _lassoSelection.selectionRect != null) {
      if (_activeControlPoint == ControlPoint.rotate) {
        _lassoSelection.handleRotation(point);
      } else {
        _lassoSelection.handleControlPointDrag(_activeControlPoint!, point);
        // 根据选择框的变化调整笔画
        // _resizeStrokes();
        _lassoSelection.resizeStrokes();
      }
      setState(() {});
      return;
    }

    if (_lassoSelection.isDraggingSelection &&
        _lassoSelection.dragStartOffset != null) {
      // 计算移动距离
      final delta = point - _lassoSelection.dragStartOffset!;
      _lassoSelection.moveSelectedStrokes(delta);
      _lassoSelection.dragStartOffset = point;
      setState(() {});
      return;
    }

    if (drawingProvider.isDrawingMode && _currentStroke != null) {
      switch (drawingProvider.strokeType) {
        case ToolType.pen:
          _currentStroke!.points.add(Point(point.dx, point.dy));
          setState(() {});
          break;
        case ToolType.marker:
          setState(() {
            _currentStroke!.points.add(Point(point.dx, point.dy));
          });
          break;
        case ToolType.shape:
          // 对于形状，我们只需要更新最后一个点
          if (_currentStroke!.points.length > 1) {
            _currentStroke!.points.removeLast();
          }
          _currentStroke!.points.add(Point(point.dx, point.dy));
          setState(() {});
          break;

        case ToolType.lasso:
          _lassoSelection.updateLassoPath(point);
          _currentStroke!.points.add(Point(point.dx, point.dy));
          setState(() {});
          break;

        case ToolType.text:
          break;
        case ToolType.image:
          if (drawingProvider.imagePath != null) {
            _loadImage(drawingProvider.imagePath!).then((image) {
              setState(() {
                _currentImage = image;
                _imagePosition =
                    Offset(point.dx.toDouble(), point.dy.toDouble());
                _imageSize = _calculateFitSize(
                  Size(image.width.toDouble(), image.height.toDouble()),
                  Size(200, 200), // 默认最大尺寸
                );
              });
            });
          }
          break;
        case ToolType.eraser:
          _eraseAtPoint(point, markerVm);
          break;
      }
    }

    // if (drawingProvider.isEraserMode) {
    //   _eraseAtPoint(point, markerVm);
    // }
  }

  void _handlePanStart(DrawingProvider drawingProvider, BuildContext context,
      DragStartDetails details, MarkerViewModel markerVm) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final globalPoint = details.globalPosition;
    final localPoint = box.globalToLocal(globalPoint);
    final point = _toPageCoordinate(localPoint);

    print('${DateTime.now()} : _handlePanStart called');
    print('${DateTime.now()} : global point = $globalPoint');
    print('${DateTime.now()} : local point = $localPoint');
    print('${DateTime.now()} : page point = $point');
    print(
        '${DateTime.now()} : selectionRect = ${_lassoSelection.selectionRect}');

    // 检查是否点击了选择框
    if (_lassoSelection.selectionRect != null) {
      // 首先检查控制点
      final controlPoint = _lassoSelection.getControlPoint(
          _lassoSelection.selectionRect!, point);
      if (controlPoint != null) {
        print('${DateTime.now()} : clicked on control point $controlPoint');
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
        print('${DateTime.now()} : clicked inside selection rect');
        _lassoSelection.isDraggingSelection = true;
        _lassoSelection.dragStartOffset = point;
        _lassoSelection.originalPositions = _lassoSelection.selectedStrokes
            .expand((stroke) => stroke.points)
            .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
            .toList();
        return;
      }

      // 如果点击在选择框外部，清除选择
      print(
          '${DateTime.now()} : clicked outside selection rect, clearing selection');
      _lassoSelection.clearSelection();
      setState(() {});
    }

    if (drawingProvider.isDrawingMode) {
      switch (drawingProvider.strokeType) {
        case ToolType.pen:
          _currentStroke = Stroke(
            paint: Paint()
              ..color = drawingProvider.penColor
              ..strokeWidth = drawingProvider.penWidth / scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
            pageNumber: widget.page.pageNumber,
            tool: Pen(),
            initialPoints: [Point(point.dx, point.dy)],
          );
          break;
        case ToolType.marker:
          _currentStroke = Stroke(
            paint: Paint()
              ..color = drawingProvider.markerColor
                  .withOpacity(drawingProvider.markerOpacity)
              ..strokeWidth = drawingProvider.markerWidth / scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke
              ..blendMode = BlendMode.srcOver,
            pageNumber: widget.page.pageNumber,
            tool: MTool(),
            initialPoints: [Point(point.dx, point.dy)],
          );
        case ToolType.shape:
          // 创建填充画笔
          final fillPaint = Paint()
            ..color = drawingProvider.shapeFillColor
                .withOpacity(drawingProvider.shapeFillOpacity)
            ..style = PaintingStyle.fill;

          // 只对封闭图形设置填充画笔
          final bool isClosedShape = [
            ShapeType.rectangle,
            ShapeType.circle,
            ShapeType.triangle,
            ShapeType.star,
          ].contains(drawingProvider.currentShape);

          Tool tool = Shape(
            drawingProvider.currentShape,
            fillPaint: isClosedShape ? fillPaint : null, // 只有封闭图形才设置填充画笔
          );

          _currentStroke = Stroke(
            paint: Paint()
              ..color = drawingProvider.shapeColor
              ..strokeWidth = drawingProvider.shapeWidth / scale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..style = PaintingStyle.stroke,
            pageNumber: widget.page.pageNumber,
            tool: tool,
            initialPoints: [Point(point.dx, point.dy)],
          );
        case ToolType.lasso:
          // 开始新的套索选择时清除旧的选择
          _lassoSelection.clearSelection();
          _lassoSelection.lassoPath = Path();
          _lassoSelection.lassoPath!.moveTo(point.dx, point.dy);
          _currentStroke = Stroke(
            paint: Paint()
              ..color = Colors.blue.withOpacity(0.5)
              ..strokeWidth = 1 / scale
              ..style = PaintingStyle.stroke,
            pageNumber: widget.page.pageNumber,
            tool: Lasso(),
            initialPoints: [Point(point.dx, point.dy)],
          );
        case ToolType.text:
          _createNewTextInput(point, context, markerVm);
          break;
        case ToolType.image:
          if (drawingProvider.imagePath != null) {
            _loadImage(drawingProvider.imagePath!).then((image) {
              setState(() {
                _currentImage = image;
                _imagePosition =
                    Offset(point.dx.toDouble(), point.dy.toDouble());
                _imageSize = _calculateFitSize(
                  Size(image.width.toDouble(), image.height.toDouble()),
                  Size(200, 200), // 默认最大尺寸
                );
              });
            });
          }
          break;
        case ToolType.eraser:
          _eraseAtPoint(point, markerVm);
          break;
      }

      // if (drawingProvider.isEraserMode) {
      //   _eraseAtPoint(point, markerVm);
      // }
    }
  }

  void _eraseAtPoint(Offset point, MarkerViewModel markerVm) {
    final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];
    final eraserRadius =
        Provider.of<DrawingProvider>(context, listen: false).eraserSize;

    // 检查每个笔画
    for (var i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
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
        markerVm.removeStroke(widget.page.pageNumber, stroke);
      }
    }
  }

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

  // 计算选中笔画的边界矩形
  // void _calculateSelectionRect() {
  //   print('${DateTime.now()} : _calculateSelectionRect start');
  //   if (_lassoSelection.selectedStrokes.isEmpty) {
  //     print('${DateTime.now()} : no selected strokes');
  //     _lassoSelection.selectionRect = null;
  //     return;
  //   }

  //   double minX = double.infinity;
  //   double minY = double.infinity;
  //   double maxX = -double.infinity;
  //   double maxY = -double.infinity;

  //   for (var stroke in _lassoSelection.selectedStrokes) {
  //     for (var point in stroke.points) {
  //       minX = min(minX, point.x.toDouble());
  //       minY = min(minY, point.y.toDouble());
  //       maxX = max(maxX, point.x.toDouble());
  //       maxY = max(maxY, point.y.toDouble());
  //     }
  //   }

  //   _lassoSelection.selectionRect = Rect.fromLTRB(minX, minY, maxX, maxY);
  //   print(
  //       '${DateTime.now()} : set selectionRect = ${_lassoSelection.selectionRect}');
  // }

  // 检查点是否在选择框上
  // bool _isPointOnSelectionRect(Offset point) {
  //   print('${DateTime.now()} : _isPointOnSelectionRect called');
  //   print('${DateTime.now()} : point = $point');
  //   print(
  //       '${DateTime.now()} : selectionRect = ${_lassoSelection.selectionRect}');

  //   if (_lassoSelection.selectionRect == null) return false;

  //   // 扩大点击区域到20像素，与控制点检测保持一致
  //   final expandedRect = Rect.fromLTRB(
  //     _lassoSelection.selectionRect!.left - 20,
  //     _lassoSelection.selectionRect!.top - 20,
  //     _lassoSelection.selectionRect!.right + 20,
  //     _lassoSelection.selectionRect!.bottom + 20,
  //   );

  //   // 首先检查是否在控制点上
  //   if (_lassoSelection.getControlPoint(
  //           _lassoSelection.selectionRect!, point) !=
  //       null) {
  //     print('${DateTime.now()} : point is on control point');
  //     return false;
  //   }

  //   final result = expandedRect.contains(point);
  //   print(
  //       '${DateTime.now()} : point is ${result ? "on" : "not on"} selection rect');
  //   return result;
  // }

  // 移动选中的笔画
  // void _moveSelectedStrokes(Offset delta) {
  //   if (_lassoSelection.selectedStrokes.isEmpty) return;

  //   for (var i = 0; i < _lassoSelection.selectedStrokes.length; i++) {
  //     var stroke = _lassoSelection.selectedStrokes[i];
  //     for (var j = 0; j < stroke.points.length; j++) {
  //       var point = stroke.points[j];
  //       stroke.points[j] = Point(
  //         point.x + delta.dx,
  //         point.y + delta.dy,
  //       );
  //     }
  //   }

  //   // 更新选择框位置
  //   if (_lassoSelection.selectionRect != null) {
  //     _lassoSelection.selectionRect =
  //         _lassoSelection.selectionRect!.translate(delta.dx, delta.dy);
  //   }
  // }

  // void _showFloatingMenu(BuildContext context, MarkerViewModel markerVm) {
  //   if (_lassoSelection.selectionRect == null) return;

  //   final RenderBox overlay =
  //       Overlay.of(context).context.findRenderObject() as RenderBox;
  //   final RenderBox box = context.findRenderObject() as RenderBox;

  //   // 计算菜单位置（在选择框上方）
  //   final Offset localPosition = Offset(
  //     _lassoSelection.selectionRect!.left,
  //     _lassoSelection.selectionRect!.top - 50, // 在选择框上方50像素
  //   );
  //   final Offset globalPosition = box.localToGlobal(localPosition);

  //   showMenu(
  //     context: context,
  //     position: RelativeRect.fromRect(
  //       Rect.fromPoints(
  //         globalPosition,
  //         globalPosition + const Offset(200, 0), // 菜单宽度
  //       ),
  //       Offset.zero & overlay.size,
  //     ),
  //     items: [
  //       PopupMenuItem(
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             IconButton(
  //               icon: Icon(Icons.delete, size: 20),
  //               onPressed: () {
  //                 for (var stroke in _lassoSelection.selectedStrokes) {
  //                   markerVm.removeStroke(widget.page.pageNumber, stroke);
  //                 }
  //                 _lassoSelection.selectedStrokes.clear();
  //                 _lassoSelection.selectionRect = null;
  //                 setState(() {});
  //                 Navigator.pop(context);
  //               },
  //               tooltip: '删除',
  //             ),
  //             IconButton(
  //               icon: Icon(Icons.color_lens, size: 20),
  //               onPressed: () {
  //                 // TODO: 实现颜色修改逻辑
  //                 Navigator.pop(context);
  //               },
  //               tooltip: '修改颜色',
  //             ),
  //             // 可以添加更多按钮
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  void _createNewTextInput(
      Offset position, BuildContext context, MarkerViewModel markerVm) {
    // 如果已经存在输入框，先保存之前的文本
    if (_isEditing && _textController != null && _textPosition != null) {
      _saveText(markerVm);
    }

    // 先创建新的控制器和焦点节点
    final newController = TextEditingController();
    final newFocusNode = FocusNode();

    setState(() {
      // 释放旧的资源
      _textController?.dispose();
      _focusNode?.dispose();

      _textPosition = position;
      _textController = newController;
      _focusNode = newFocusNode;
      _isEditing = true;
    });

    // 确保在下一帧请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode?.hasListeners ?? false) {
        _focusNode?.requestFocus();
      }
    });
  }

  void _saveText(MarkerViewModel markerVm) {
    final text = _textController?.text ?? '';
    if (text.isNotEmpty && _textPosition != null) {
      final stroke = Stroke(
        paint: Paint()
          ..color = Colors.black
          ..strokeWidth = 1,
        pageNumber: widget.page.pageNumber,
        tool: TextTool(
          text: text,
          fontSize: 14.0,
          color: Colors.black,
        ),
        initialPoints: [Point(_textPosition!.dx, _textPosition!.dy)],
      );
      markerVm.addStroke(stroke, widget.page.pageNumber);
    }

    setState(() {
      _textController?.clear();
      _textPosition = null;
      _isEditing = false;
      _focusNode?.unfocus(); // 确保取消焦点
    });
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Size _calculateFitSize(Size imageSize, Size maxSize) {
    final double aspectRatio = imageSize.width / imageSize.height;
    if (imageSize.width > maxSize.width) {
      return Size(maxSize.width, maxSize.width / aspectRatio);
    }
    if (imageSize.height > maxSize.height) {
      return Size(maxSize.height * aspectRatio, maxSize.height);
    }
    return imageSize;
  }

  Widget _buildImageControls() {
    return Container(
      width: _imageSize!.width * scale,
      height: _imageSize!.height * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Stack(
        children: [
          // 调整大小的手柄
          Positioned(
            right: -10,
            bottom: -10,
            child: GestureDetector(
              onPanUpdate: _handleResizeUpdate,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.open_with, size: 12, color: Colors.white),
              ),
            ),
          ),
          // 删除按钮
          Positioned(
            right: -10,
            top: -10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentImage = null;
                  _imagePosition = null;
                  _imageSize = null;
                  _isImageSelected = false;
                });
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

// image
  void _handleResizeUpdate(DragUpdateDetails details) {
    // Implementation of _handleResizeUpdate method
  }

}
