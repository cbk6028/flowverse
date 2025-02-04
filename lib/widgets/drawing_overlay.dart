import 'dart:ui' as ui;

import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/provider/drawing_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/rendering.dart' as ui;
import 'dart:io';

// 控制点类型
enum ControlPoint { topLeft, topRight, bottomLeft, bottomRight, rotate }

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
  Path? _lassoPath;
  Rect? _selectionRect; // 选择框矩形
  bool _isDraggingSelection = false; // 是否正在拖动选择框
  Offset? _dragStartOffset; // 拖动起始点
  List<Offset> _originalPositions = []; // 存储选中笔画的原始位置
  TextEditingController? _textController;
  FocusNode? _focusNode;
  Offset? _textPosition;
  bool _isEditing = false;
  ui.Image? _currentImage;
  Offset? _imagePosition;
  Size? _imageSize;
  bool _isImageSelected = false;

  Rect? selectionRect;
  double _rotationAngle = 0.0;
  double _scale = 1.0;
  Offset? _lastFocalPoint;
  bool _isTransforming = false;
  ControlPoint? _activeControlPoint;

  // 判断点击位置是否在控制点上
  ControlPoint? _getControlPoint(Offset position) {
    if (selectionRect == null) return null;

    final points = {
      ControlPoint.topLeft: selectionRect!.topLeft,
      ControlPoint.topRight: selectionRect!.topRight,
      ControlPoint.bottomLeft: selectionRect!.bottomLeft,
      ControlPoint.bottomRight: selectionRect!.bottomRight,
      ControlPoint.rotate: Offset(
        selectionRect!.center.dx,
        selectionRect!.top - 30,
      ),
    };

    for (var entry in points.entries) {
      if ((position - entry.value).distance < 20) {
        return entry.key;
      }
    }
    return null;
  }

  // 处理变换操作
  void _handleTransform(Offset currentPoint) {
    if (selectionRect == null || _activeControlPoint == null) return;

    final center = selectionRect!.center;
    final originalRect = selectionRect!;

    switch (_activeControlPoint) {
      case ControlPoint.rotate:
        final previousAngle = _rotationAngle;
        final originalAngle = (center - _lastFocalPoint!).direction;
        final newAngle = (center - currentPoint).direction;
        _rotationAngle += (newAngle - originalAngle);
        _lastFocalPoint = currentPoint;
        break;

      case ControlPoint.topLeft:
      case ControlPoint.topRight:
      case ControlPoint.bottomLeft:
      case ControlPoint.bottomRight:
        final dx = currentPoint.dx - _lastFocalPoint!.dx;
        final dy = currentPoint.dy - _lastFocalPoint!.dy;

        double newLeft = originalRect.left;
        double newTop = originalRect.top;
        double newWidth = originalRect.width;
        double newHeight = originalRect.height;

        switch (_activeControlPoint) {
          case ControlPoint.topLeft:
            newLeft += dx;
            newTop += dy;
            newWidth -= dx;
            newHeight -= dy;
            break;
          case ControlPoint.topRight:
            newTop += dy;
            newWidth += dx;
            newHeight -= dy;
            break;
          case ControlPoint.bottomLeft:
            newLeft += dx;
            newWidth -= dx;
            newHeight += dy;
            break;
          case ControlPoint.bottomRight:
            newWidth += dx;
            newHeight += dy;
            break;
          default:
            break;
        }

        // 确保矩形不会太小
        if (newWidth > 20 && newHeight > 20) {
          selectionRect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
        }
        _lastFocalPoint = currentPoint;
        break;
      default:
        break;
    }
    setState(() {});
  }

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
        return Stack(
          children: [
            Listener(
              onPointerMove: (event) {
                if (drawingProvider.isEraserMode) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  setState(() {
                    _currentEraserPosition = localPosition;
                    _isPointerInside = true;
                  });
                }
              },
              onPointerHover: (event) {
                if (drawingProvider.isEraserMode) {
                  final box = context.findRenderObject() as RenderBox;
                  final localPosition = box.globalToLocal(event.position);
                  setState(() {
                    _currentEraserPosition = localPosition;
                    _isPointerInside = true;
                  });
                }
              },
              onPointerDown: (event) {
                if (drawingProvider.strokeType == StrokeType.text) {
                  final RenderBox box = context.findRenderObject() as RenderBox;
                  final point =
                      _toPageCoordinate(box.globalToLocal(event.position));
                  _createNewTextInput(point, context, markerVm);
                }
              },
              child: IgnorePointer(
                ignoring: !drawingProvider.isDrawingMode &&
                    !drawingProvider.isEraserMode,
                child: GestureDetector(
                  onPanStart: (details) {
                    _handlePanStart(
                        drawingProvider, context, details, markerVm);
                    _activeControlPoint =
                        _getControlPoint(details.localPosition);
                    if (_activeControlPoint != null) {
                      _isTransforming = true;
                      _lastFocalPoint = details.localPosition;
                    }
                  },
                  onPanUpdate: (details) {
                    _handlePanUpdate(
                        drawingProvider, context, details, markerVm);
                    if (_isTransforming && _activeControlPoint != null) {
                      _handleTransform(details.localPosition);
                    }
                  },
                  onPanEnd: (details) {
                    _handlePanEnd(drawingProvider, markerVm);
                    _isTransforming = false;
                    _activeControlPoint = null;
                  },
                  child: CustomPaint(
                    painter: _DrawingPainter(
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
                      lassoPath: _lassoPath,
                      selectedStrokes: selectedStrokes,
                      selectionRect: _selectionRect,
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

  void _showLassoMenu(BuildContext context, MarkerViewModel markerVm) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(0, 0, 0, 0),
      items: [
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('删除选中'),
            onTap: () {
              for (var stroke in selectedStrokes) {
                markerVm.removeStroke(widget.page.pageNumber, stroke);
              }
              selectedStrokes.clear();
              Navigator.pop(context);
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('修改颜色'),
            onTap: () {
              Navigator.pop(context);
              // _showColorPicker(context, markerVm);
            },
          ),
        ),
      ],
    );
  }

  void _handlePanEnd(
      DrawingProvider drawingProvider, MarkerViewModel markerVm) {
    if (_isDraggingSelection) {
      _isDraggingSelection = false;
      _dragStartOffset = null;
      setState(() {});
      return;
    }

    if (drawingProvider.strokeType == StrokeType.lasso && _lassoPath != null) {
      _lassoPath!.close();

      // 检查哪些笔画在套索区域内
      final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];
      selectedStrokes = strokes.where((stroke) {
        return stroke.points.any((point) {
          final offset = Offset(point.x.toDouble(), point.y.toDouble());
          return _lassoPath!.contains(offset);
        });
      }).toList();

      // 计算选择框
      _calculateSelectionRect();

      // 如果有选中的笔画，显示浮动菜单
      if (selectedStrokes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showFloatingMenu(context, markerVm);
        });
      }

      _lassoPath = null;
      _currentStroke = null;
      setState(() {});
    } else if (drawingProvider.isDrawingMode && _currentStroke != null) {
      markerVm.addStroke(_currentStroke!, widget.page.pageNumber);
      _currentStroke = null;
    }
  }

  void _handlePanUpdate(DrawingProvider drawingProvider, BuildContext context,
      DragUpdateDetails details, MarkerViewModel markerVm) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final point = _toPageCoordinate(box.globalToLocal(details.globalPosition));

    if (_isDraggingSelection && _dragStartOffset != null) {
      // 计算移动距离
      final delta = point - _dragStartOffset!;
      _moveSelectedStrokes(delta);
      _dragStartOffset = point;
      setState(() {});
      return;
    }

    if (drawingProvider.isDrawingMode && _currentStroke != null) {
      if (drawingProvider.strokeType == StrokeType.lasso &&
          _lassoPath != null) {
        // print('lasso update');

        _lassoPath!.lineTo(point.dx, point.dy);
        _currentStroke!.points.add(Point(point.dx, point.dy));
        setState(() {});
      }
      if (drawingProvider.strokeType == StrokeType.marker) {
        setState(() {
          _currentStroke!.points.add(Point(point.dx, point.dy));
        });
      }
      if (_currentStroke!.tool.type == StrokeType.pen) {
        _currentStroke!.points.add(Point(point.dx, point.dy));
      } else {
        // 对于形状，我们只需要更新最后一个点
        if (_currentStroke!.points.length > 1) {
          _currentStroke!.points.removeLast();
        }
        _currentStroke!.points.add(Point(point.dx, point.dy));
      }
      setState(() {});
    } else if (drawingProvider.isEraserMode) {
      _eraseAtPoint(point, markerVm);
    }
  }

  void _handlePanStart(DrawingProvider drawingProvider, BuildContext context,
      DragStartDetails details, MarkerViewModel markerVm) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final point = _toPageCoordinate(box.globalToLocal(details.globalPosition));

    if (drawingProvider.strokeType == StrokeType.text) {
      _createNewTextInput(point, context, markerVm);
      return;
    }

    // 检查是否点击了选择框
    if (_selectionRect != null && _isPointOnSelectionRect(point)) {
      _isDraggingSelection = true;
      _dragStartOffset = point;
      // 保存原始位置
      _originalPositions = selectedStrokes
          .expand((stroke) => stroke.points)
          .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
          .toList();
      return;
    }

    if (drawingProvider.isDrawingMode) {
      if (drawingProvider.strokeType == StrokeType.pen) {
        _currentStroke = Stroke(
          paint: Paint()
            ..color = drawingProvider.penColor
            ..strokeWidth = drawingProvider.penWidth / scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
          pageNumber: widget.page.pageNumber,
          tool: PenTool(),
          initialPoints: [Point(point.dx, point.dy)],
        );
      } else if (drawingProvider.strokeType == StrokeType.marker) {
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
      } else if (drawingProvider.strokeType == StrokeType.lasso) {
        // 开始新的套索选择时清除旧的选择
        selectedStrokes.clear();
        _selectionRect = null;
        _lassoPath = Path();
        _lassoPath!.moveTo(point.dx, point.dy);
        _currentStroke = Stroke(
          paint: Paint()
            ..color = Colors.blue.withOpacity(0.5)
            ..strokeWidth = 1 / scale
            ..style = PaintingStyle.stroke,
          pageNumber: widget.page.pageNumber,
          tool: LassoTool(),
          initialPoints: [Point(point.dx, point.dy)],
        );
      } else if (drawingProvider.strokeType == StrokeType.shape) {
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

        Tool tool = ShapeTool(
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
      }
    } else if (drawingProvider.isEraserMode) {
      _eraseAtPoint(point, markerVm);
    }

    if (drawingProvider.strokeType == StrokeType.image &&
        drawingProvider.imagePath != null) {
      _loadImage(drawingProvider.imagePath!).then((image) {
        setState(() {
          _currentImage = image;
          _imagePosition = Offset(point.dx.toDouble(), point.dy.toDouble());
          _imageSize = _calculateFitSize(
            Size(image.width.toDouble(), image.height.toDouble()),
            Size(200, 200), // 默认最大尺寸
          );
        });
      });
    }
  }

  void _eraseAtPoint(Offset point, MarkerViewModel markerVm) {
    final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];
    final eraserRadius = 10.0; // 橡皮擦的半径

    // 检查每个笔画
    for (var i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
      bool shouldErase = false;

      // 检查笔画的每个点
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

      if (shouldErase) {
        // 从 MarkerVm 中移除笔画
        markerVm.removeStroke(widget.page.pageNumber, stroke);
      }
    }
  }

  double _calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  // 计算选中笔画的边界矩形
  void _calculateSelectionRect() {
    if (selectedStrokes.isEmpty) {
      _selectionRect = null;
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var stroke in selectedStrokes) {
      for (var point in stroke.points) {
        minX = min(minX, point.x.toDouble());
        minY = min(minY, point.y.toDouble());
        maxX = max(maxX, point.x.toDouble());
        maxY = max(maxY, point.y.toDouble());
      }
    }

    _selectionRect = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // 检查点是否在选择框上
  bool _isPointOnSelectionRect(Offset point) {
    if (_selectionRect == null) return false;
    final expandedRect = _selectionRect!.inflate(10); // 扩大点击区域
    return expandedRect.contains(point);
  }

  // 移动选中的笔画
  void _moveSelectedStrokes(Offset delta) {
    if (selectedStrokes.isEmpty) return;

    for (var i = 0; i < selectedStrokes.length; i++) {
      var stroke = selectedStrokes[i];
      for (var j = 0; j < stroke.points.length; j++) {
        var point = stroke.points[j];
        stroke.points[j] = Point(
          point.x + delta.dx,
          point.y + delta.dy,
        );
      }
    }

    // 更新选择框位置
    if (_selectionRect != null) {
      _selectionRect = _selectionRect!.translate(delta.dx, delta.dy);
    }
  }

  void _showFloatingMenu(BuildContext context, MarkerViewModel markerVm) {
    if (_selectionRect == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox box = context.findRenderObject() as RenderBox;

    // 计算菜单位置（在选择框上方）
    final Offset localPosition = Offset(
      _selectionRect!.left,
      _selectionRect!.top - 50, // 在选择框上方50像素
    );
    final Offset globalPosition = box.localToGlobal(localPosition);

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          globalPosition,
          globalPosition + const Offset(200, 0), // 菜单宽度
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.delete, size: 20),
                onPressed: () {
                  for (var stroke in selectedStrokes) {
                    markerVm.removeStroke(widget.page.pageNumber, stroke);
                  }
                  selectedStrokes.clear();
                  _selectionRect = null;
                  setState(() {});
                  Navigator.pop(context);
                },
                tooltip: '删除',
              ),
              IconButton(
                icon: Icon(Icons.color_lens, size: 20),
                onPressed: () {
                  // TODO: 实现颜色修改逻辑
                  Navigator.pop(context);
                },
                tooltip: '修改颜色',
              ),
              // 可以添加更多按钮
            ],
          ),
        ),
      ],
    );
  }

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

  void _handleResizeUpdate(DragUpdateDetails details) {
    // Implementation of _handleResizeUpdate method
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final double scale;
  final Size pageSize;
  final Size screenSize;
  final Offset? eraserPosition;
  final double eraserSize;
  final Path? lassoPath;
  final List<Stroke> selectedStrokes;
  final Rect? selectionRect;
  final ui.Image? currentImage;
  final Offset? imagePosition;
  final Size? imageSize;
  final double rotationAngle;

  _DrawingPainter({
    required this.strokes,
    required this.scale,
    required this.pageSize,
    required this.screenSize,
    required this.eraserPosition,
    required this.eraserSize,
    required this.lassoPath,
    required this.selectedStrokes,
    this.selectionRect,
    this.currentImage,
    this.imagePosition,
    this.imageSize,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (eraserPosition != null) {
      final paint = Paint()
        ..color = Colors.red.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        eraserPosition!,
        eraserSize * 2,
        paint..style = PaintingStyle.stroke,
      );

      canvas.drawCircle(
        eraserPosition!,
        eraserSize / 2,
        paint
          ..style = PaintingStyle.fill
          ..color = Colors.red.withOpacity(0.1),
      );
    }
    // 计算实际缩放比例，确保完全贴合
    final scaleX = screenSize.width / pageSize.width;
    final scaleY = screenSize.height / pageSize.height;

    // 绘制调试边框
    final debugPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制缩放前的边框（屏幕坐标系）
    canvas.drawRect(Offset.zero & size, debugPaint);

    // 添加一个网格来显示缩放
    final gridPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 绘制网格（每100像素一条线）
    for (double i = 0; i < size.width; i += 100) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 100) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 应用缩放，使用实际的缩放比例
    canvas.scale(scaleX, scaleY);

    // 绘制缩放后的边框（PDF坐标系）
    final pdfDebugPaint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / scaleX;

    canvas.drawRect(Offset.zero & pageSize, pdfDebugPaint);

    // 绘制所有笔画
    for (final stroke in strokes) {
      if (stroke.tool.type != StrokeType.lasso) {
        // 不绘制套索工具的路径
        _paintStroke(canvas, stroke);
      }
    }

    // 添加坐标信息
    final textPainter = TextPainter(
      text: TextSpan(
        text:
            'Scale: ${scaleX.toStringAsFixed(2)} x ${scaleY.toStringAsFixed(2)}\n'
            'Size: ${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)}\n'
            'PDF Size: ${pageSize.width.toStringAsFixed(1)} x ${pageSize.height.toStringAsFixed(1)}',
        style: TextStyle(
          color: Colors.red,
          fontSize: 12 / scaleX,
          backgroundColor: Colors.white.withOpacity(0.8),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10 / scaleX, 10 / scaleY));

    // 绘制套索选择区域
    // print('lassopath $lassoPath');
    if (lassoPath != null) {
      final xlassoPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawPath(lassoPath!, xlassoPaint);

      final lassoStrokePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawPath(lassoPath!, lassoStrokePaint);
    }

    // 绘制选中效果
    for (final stroke in selectedStrokes) {
      final selectedPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.paint.strokeWidth + 4;
      _paintStroke(canvas, stroke);
    }

    // 绘制选择框
    if (selectionRect != null) {
      canvas.save();

      // 应用旋转变换
      canvas.translate(selectionRect!.center.dx, selectionRect!.center.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(-selectionRect!.center.dx, -selectionRect!.center.dy);

      final selectionPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // 绘制主矩形
      canvas.drawRect(selectionRect!, selectionPaint);

      // 绘制控制点
      final controlPoints = [
        selectionRect!.topLeft,
        selectionRect!.topRight,
        selectionRect!.bottomLeft,
        selectionRect!.bottomRight,
      ];

      // 绘制旋转控制点
      final rotatePoint = Offset(
        selectionRect!.center.dx,
        selectionRect!.top - 30,
      );

      // 绘制旋转控制点到矩形顶边的连接线
      canvas.drawLine(
        Offset(selectionRect!.center.dx, selectionRect!.top),
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
      if (selectedStrokes.isNotEmpty) {
        canvas.save();
        canvas.translate(selectionRect!.center.dx, selectionRect!.center.dy);
        canvas.rotate(rotationAngle);
        canvas.translate(-selectionRect!.center.dx, -selectionRect!.center.dy);

        for (final stroke in selectedStrokes) {
          final selectedPaint = Paint()
            ..color = Colors.blue.withOpacity(0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.paint.strokeWidth + 4;
          _paintStroke(canvas, stroke);
        }

        canvas.restore();
      }
    }

    // 绘制图片
    if (currentImage != null && imagePosition != null && imageSize != null) {
      final rect = Rect.fromLTWH(
        imagePosition!.dx * scale,
        imagePosition!.dy * scale,
        imageSize!.width * scale,
        imageSize!.height * scale,
      );
      canvas.drawImageRect(
        currentImage!,
        Rect.fromLTWH(0, 0, currentImage!.width.toDouble(),
            currentImage!.height.toDouble()),
        rect,
        Paint(),
      );
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.tool.type == StrokeType.marker) {
      final path = Path();
      path.moveTo(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble());

      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(
          stroke.points[i].x.toDouble(),
          stroke.points[i].y.toDouble(),
        );
      }

      canvas.drawPath(path, stroke.paint);
    } else if (stroke.tool.type == StrokeType.pen) {
      final path = Path();
      path.moveTo(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble());

      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(
          stroke.points[i].x.toDouble(),
          stroke.points[i].y.toDouble(),
        );
      }

      canvas.drawPath(path, stroke.paint);
    } else if (stroke.tool.type == StrokeType.shape) {
      final shapeTool = stroke.tool as ShapeTool;
      switch (shapeTool.shapeType) {
        case ShapeType.rectangle:
          final rect = Rect.fromPoints(
            Offset(
                stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
            Offset(stroke.points.last.x.toDouble(),
                stroke.points.last.y.toDouble()),
          );
          // 先绘制填充
          if (shapeTool.fillPaint != null) {
            canvas.drawRect(rect, shapeTool.fillPaint!);
          }
          // 再绘制边框
          canvas.drawRect(rect, stroke.paint);
          break;

        case ShapeType.circle:
          final rect = Rect.fromPoints(
            Offset(
                stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
            Offset(stroke.points.last.x.toDouble(),
                stroke.points.last.y.toDouble()),
          );
          if (shapeTool.fillPaint != null) {
            canvas.drawOval(rect, shapeTool.fillPaint!);
          }
          canvas.drawOval(rect, stroke.paint);
          break;

        case ShapeType.triangle:
          final path = Path();
          final start = Offset(
              stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble());
          final end = Offset(
              stroke.points.last.x.toDouble(), stroke.points.last.y.toDouble());
          final mid = Offset((start.dx + end.dx) / 2, start.dy);

          path.moveTo(mid.dx, start.dy);
          path.lineTo(end.dx, end.dy);
          path.lineTo(start.dx, end.dy);
          path.close();

          if (shapeTool.fillPaint != null) {
            canvas.drawPath(path, shapeTool.fillPaint!);
          }
          canvas.drawPath(path, stroke.paint);
          break;

        case ShapeType.line:
          canvas.drawLine(
            Offset(
                stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
            Offset(stroke.points.last.x.toDouble(),
                stroke.points.last.y.toDouble()),
            stroke.paint,
          );
          break;

        case ShapeType.arrow:
          final start = Offset(
              stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble());
          final end = Offset(
              stroke.points.last.x.toDouble(), stroke.points.last.y.toDouble());

          // 绘制主线
          canvas.drawLine(start, end, stroke.paint);

          // 计算箭头
          final angle = atan2(end.dy - start.dy, end.dx - start.dx);
          final arrowLength = 20.0; // 箭头长度
          final arrowAngle = pi / 6; // 箭头角度 (30度)

          final path = Path();
          path.moveTo(end.dx, end.dy);
          path.lineTo(
            end.dx - arrowLength * cos(angle - arrowAngle),
            end.dy - arrowLength * sin(angle - arrowAngle),
          );
          path.moveTo(end.dx, end.dy);
          path.lineTo(
            end.dx - arrowLength * cos(angle + arrowAngle),
            end.dy - arrowLength * sin(angle + arrowAngle),
          );

          canvas.drawPath(path, stroke.paint);
          break;

        case ShapeType.star:
          final center = Offset((stroke.points[0].x + stroke.points.last.x) / 2,
              (stroke.points[0].y + stroke.points.last.y) / 2);
          final radius = center.dx - stroke.points[0].x;

          final path = Path();
          for (int i = 0; i < 5; i++) {
            double angle = 2 * pi * i / 5 - pi / 2;
            double x = center.dx + radius * cos(angle);
            double y = center.dy + radius * sin(angle);
            if (i == 0)
              path.moveTo(x, y);
            else
              path.lineTo(x, y);

            angle += pi / 5;
            x = center.dx + (radius / 2) * cos(angle);
            y = center.dy + (radius / 2) * sin(angle);
            path.lineTo(x, y);
          }
          path.close();
          canvas.drawPath(path, stroke.paint);
          break;
        default:
          break;
      }
    } else if (stroke.tool.type == StrokeType.text) {
      final textTool = stroke.tool as TextTool;
      final textSpan = TextSpan(
        text: textTool.text,
        style: TextStyle(
          color: textTool.color,
          fontSize: textTool.fontSize,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      final position = Offset(
        stroke.points[0].x.toDouble(),
        stroke.points[0].y.toDouble(),
      );
      textPainter.paint(canvas, position);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
