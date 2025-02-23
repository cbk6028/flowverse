import 'dart:ui' as ui;

import 'package:flowverse/domain/models/tool/eraser.dart';
import 'package:flowverse/domain/models/tool/lasso.dart';
import 'package:flowverse/domain/models/tool/marker.dart';
import 'package:flowverse/domain/models/tool/pen.dart';
import 'package:flowverse/domain/models/tool/shape.dart';
import 'package:flowverse/domain/models/tool/text.dart';
import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flowverse/ui/canvas_overlay/vm/handler.dart';
import 'package:flowverse/ui/maker_overlay/vm/marker_vm.dart';
import 'package:flowverse/ui/canvas_overlay/widgets/canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flowverse/ui/canvas_overlay/vm/drawing_vm.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';

part 'lasso.dart';

class DrawingOverlay extends StatefulWidget {
  final Rect pageRect;
  final PdfPage page;
  final List strokes;

  DrawingOverlay(
      {Key? key,
      required this.pageRect,
      required this.page,
      required this.strokes})
      : super(key: key);

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
  // ControlPoint? _activeControlPoint;
  // Offset? _rotationCenter;

  // 套索选择管理器
  // final LassoSelection _lassoSelection = LassoSelection();

  // 使用PDF原始尺寸的比例计算缩放
  double get scale => widget.pageRect.width / widget.page.width;

  // 转换屏幕坐标到PDF坐标
  Offset _toPageCoordinate(Offset screenPoint) {
    return Offset(screenPoint.dx / scale, screenPoint.dy / scale);
  }

  @override
  void initState() {
    // printText();
    print('DrawingOverlay: initState - 当前页码: ${widget.page.pageNumber}');
    super.initState();

    // 确保在initState中初始化工具管理器
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _initOrUpdateToolManager();
    //   // 强制重建以更新toolManager状态
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });
    initToolManager();
  }

  void _initOrUpdateToolManager() {
    final drawingVm = context.read<DrawingViewModel>();
    final toolContext = ToolContext(
      // context: context,
      markerVm: context.read<MarkerViewModel>(),
      drawingVm: drawingVm,
      // page: widget.page,
      // scale: scale,
      // pageSize: widget.page.size,
      // pageRect: widget.pageRect,
    );

    print('DrawingOverlay: 初始化或更新工具管理器 - 页码: ${widget.page.pageNumber}');
    drawingVm.initToolManager(toolContext);
  }

  Future<void> printText() async {
    final PdfPageText pageText = await widget.page.loadText();
    for (PdfPageTextFragment i in pageText.fragments) {
      print(i.text);
    }
  }

  Future<void> initToolManager() async {
    final drawingVm = context.read<DrawingViewModel>();
    final toolContext = ToolContext(
      // context: context,
      markerVm: context.read<MarkerViewModel>(),
      drawingVm: drawingVm,
      // page: widget.page,
      // scale: scale,
      // pageSize: widget.page.size,
      // pageRect: widget.pageRect,
    );

    print('DrawingOverlay: 初始化或更新工具管理器 - 页码: ${widget.page.pageNumber}');
    drawingVm.initToolManager(toolContext);
  }

  @override
  void dispose() {
    final drawingVm = context.read<DrawingViewModel>();
    drawingVm.toolManager?.dispose();

    _textController?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果页面发生变化，更新 ToolContext
    if (oldWidget.page.pageNumber != widget.page.pageNumber) {
      print(
          'DrawingOverlay: 页面变化 - 从 ${oldWidget.page.pageNumber} 到 ${widget.page.pageNumber}');
      _initOrUpdateToolManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarkerViewModel>(builder: (context, markerVm, child) {
      // 获取当前页面的笔画
      final pageStrokes =
          markerVm.archive.strokes[widget.page.pageNumber] ?? [];
      print('DrawingOverlay: build - 当前页码: ${widget.page.pageNumber}');
      print('DrawingOverlay: build - 当前页面笔画数量: ${pageStrokes.length}');

      return Consumer<DrawingViewModel>(
          builder: (context, drawingProvider, child) {
        print(
            'DrawingOverlay: build - drawingMode = ${drawingProvider.isDrawingMode}');
        // print(
        // 'DrawingOverlay: build - 工具管理器页码: ${drawingProvider.toolManager?.context.page.pageNumber}');
        print(
            'drawingProvider.isDrawingMode  ${drawingProvider.isDrawingMode}');

        // Clear eraser position when not in eraser mode
        // bool isEra.serMode = drawingProvider.strokeType == ToolType.eraser;
        if (!drawingProvider.isEraserMode && _currentEraserPosition != null) {
          _currentEraserPosition = null;
        }

        // 导致重建
        // _toolManager.switchTool(drawingProvider.strokeType);
        print(
            'drawingProvider.isDrawingMode  ${drawingProvider.isDrawingMode}');

        return Stack(
          children: [
            IgnorePointer(
              ignoring: !drawingProvider.isDrawingMode,
              child: Listener(
                onPointerMove: (event) {
                  print('onPointerMove');
                  setState(() {
                    drawingProvider.toolManager?.currentHandler.scale = scale;

                    drawingProvider.toolManager?.handlePointerMove(event);
                  });
                  // if (drawingProvider.strokeType == ToolType.eraser) {
                  //   // final box = context.findRenderObject() as RenderBox;
                  //   // final localPosition = box.globalToLocal(event.position);
                  //   setState(() {
                  //     _currentEraserPosition = event.localPosition;
                  //     _isPointerInside = true;
                  //   });
                  // }
                },
                onPointerHover: (event) {
                  drawingProvider.toolManager?.handlePointerHover(event);

                  // if (drawingProvider.strokeType == ToolType.eraser) {
                  //   setState(() {
                  //     _currentEraserPosition = event.localPosition;
                  //     _isPointerInside = true;
                  //   });
                  // }
                },
                onPointerDown: (event) {
                  drawingProvider.toolManager?.handlePointerDown(event);

                  // if (drawingProvider.strokeType == ToolType.text) {
                  //   final point = _toPageCoordinate(event.localPosition);
                  //   _createNewTextInput(point, context, markerVm);
                  // }
                },
                child: GestureDetector(
                  onPanStart: (details) {
                    print('DrawingOverlay: onPanStart');
                    drawingProvider.toolManager?.handlePanStart(
                        details, widget.page.pageNumber, scale);
                    setState(() {});
                    // _handlePanStart(
                    //     drawingProvider, context, details, markerVm);
                  },
                  onPanUpdate: (details) {
                    drawingProvider.toolManager
                        ?.handlePanUpdate(details, scale);
                    setState(() {});
                    // _handlePanUpdate(
                    //     drawingProvider, context, details, markerVm);
                    // if (_isTransforming && _activeControlPoint != null) {
                    //   // _handleTransform(details.localPosition);
                    //   _lassoSelection.handleTransform(details.localPosition);
                    //   setState(() {});
                    // }
                  },
                  onPanEnd: (details) {
                    print('DrawingOverlay: onPanEnd');
                    drawingProvider.toolManager?.handlePanEnd(details);
                    setState(() {});
                    // _handlePanEnd(drawingProvider, markerVm);
                    // _isTransforming = false;
                    // _activeControlPoint = null;
                  },
                  child: CustomPaint(
                    painter: CanvasPainter(
                      handler: drawingProvider.toolManager?.currentHandler,
                      strokes: pageStrokes,
                      pageSize: widget.page.size,
                      screenSize: widget.pageRect.size,
                      scale: scale,
                    ),
                    size: widget.pageRect.size,
                  ),
                  // CustomPaint(
                  //   painter: Painter(
                  //     strokes: [
                  //       ...strokes,
                  //       if (_currentStroke != null) _currentStroke!
                  //     ],
                  //     scale: scale,
                  //     pageSize: widget.page.size,
                  //     screenSize: widget.pageRect.size,
                  //     eraserPosition:
                  //         _isPointerInside ? _currentEraserPosition : null,
                  //     eraserSize: drawingProvider.eraserSize,
                  //     lassoPath: _lassoSelection.lassoPath,
                  //     selectedStrokes: _lassoSelection.selectedStrokes,
                  //     selectionRect: _lassoSelection.selectionRect,
                  //     currentImage: _currentImage,
                  //     imagePosition: _imagePosition,
                  //     imageSize: _imageSize,
                  //     rotationAngle: _rotationAngle,
                  //   ),
                  //   size: widget.pageRect.size,
                  // ),
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
                    constraints: const BoxConstraints(
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
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.fromLTRB(8, 8, 40, 8),
                            border: InputBorder.none,
                            hintText: '输入文字...',
                          ),
                          style: const TextStyle(
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
                                icon: const Icon(Icons.check, size: 16),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                onPressed: () => _saveText(markerVm),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
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

  // void _handlePanEnd(
  //     DrawingViewModel drawingProvider, MarkerViewModel markerVm) {
  //   if (_isDraggingSelection) {
  //     _isDraggingSelection = false;
  //     // _dragStartOffset = null;
  //     // _originalPositions = [];
  //   }

  //   if (drawingProvider.strokeType == ToolType.lasso &&
  //       _lassoSelection.lassoPath != null) {
  //     final strokes = markerVm.archive.strokes[widget.page.pageNumber] ?? [];
  //     _lassoSelection.handleLassoEnd(strokes);
  //     setState(() {
  //       _currentStroke = null;
  //     });
  //   } else if (_currentStroke != null) {
  //     markerVm.addStroke(_currentStroke!, widget.page.pageNumber);
  //     _currentStroke = null;
  //     setState(() {});
  //   }
  // }

  // void _handlePanUpdate(DrawingViewModel drawingProvider, BuildContext context,
  //     DragUpdateDetails details, MarkerViewModel markerVm) {
  //   final point = _toPageCoordinate(details.localPosition);

  //   // 处理控制点拖动
  //   if (_activeControlPoint != null && _lassoSelection.selectionRect != null) {
  //     if (_activeControlPoint == ControlPoint.rotate) {
  //       _lassoSelection.handleRotation(point);
  //     } else {
  //       _lassoSelection.handleControlPointDrag(_activeControlPoint!, point);
  //       // 根据选择框的变化调整笔画
  //       // _resizeStrokes();
  //       _lassoSelection.resizeStrokes();
  //     }
  //     setState(() {});
  //     return;
  //   }

  //   if (_lassoSelection.isDraggingSelection &&
  //       _lassoSelection.dragStartOffset != null) {
  //     // 计算移动距离
  //     final delta = point - _lassoSelection.dragStartOffset!;
  //     _lassoSelection.moveSelectedStrokes(delta);
  //     _lassoSelection.dragStartOffset = point;
  //     setState(() {});
  //     return;
  //   }

  //   if (_currentStroke != null) {
  //     switch (drawingProvider.strokeType) {
  //       case ToolType.pen:
  //         _currentStroke!.points.add(Point(point.dx, point.dy));
  //         setState(() {});
  //         break;
  //       case ToolType.marker:
  //         setState(() {
  //           _currentStroke!.points.add(Point(point.dx, point.dy));
  //         });
  //         break;
  //       case ToolType.shape:
  //         // 对于形状，我们只需要更新最后一个点
  //         if (_currentStroke!.points.length > 1) {
  //           _currentStroke!.points.removeLast();
  //         }
  //         _currentStroke!.points.add(Point(point.dx, point.dy));
  //         setState(() {});
  //         break;

  //       case ToolType.lasso:
  //         _lassoSelection.updateLassoPath(point);
  //         _currentStroke!.points.add(Point(point.dx, point.dy));
  //         setState(() {});
  //         break;

  //       case ToolType.text:
  //         break;
  //       case ToolType.image:
  //         if (drawingProvider.imagePath != null) {
  //           _loadImage(drawingProvider.imagePath!).then((image) {
  //             setState(() {
  //               _currentImage = image;
  //               _imagePosition =
  //                   Offset(point.dx.toDouble(), point.dy.toDouble());
  //               _imageSize = _calculateFitSize(
  //                 Size(image.width.toDouble(), image.height.toDouble()),
  //                 const Size(200, 200), // 默认最大尺寸
  //               );
  //             });
  //           });
  //         }
  //         break;
  //       case ToolType.eraser:
  //         // _eraseAtPoint(point, markerVm);
  //         eraseAtPoint(point, markerVm, widget.strokes,
  //             drawingProvider.eraserSize, widget.page.pageNumber);

  //         break;
  //     }
  //   }

  //   // if (drawingProvider.isEraserMode) {
  //   //   _eraseAtPoint(point, markerVm);
  //   // }
  // }

  // void _handlePanStart(DrawingViewModel drawingProvider, BuildContext context,
  //     DragStartDetails details, MarkerViewModel markerVm) {
  //   final point = _toPageCoordinate(details.localPosition);

  //   // print('${DateTime.now()} : _handlePanStart called');
  //   // print('${DateTime.now()} : global point = $globalPoint');
  //   print('${DateTime.now()} : local point = $point');
  //   print('${DateTime.now()} : localPosition = ${details.localPosition}');

  //   // print('${DateTime.now()} : page point = $point');
  //   // print(
  //   //     '${DateTime.now()} : selectionRect = ${_lassoSelection.selectionRect}');

  //   // 检查是否点击了选择框
  //   if (_lassoSelection.selectionRect != null) {
  //     // 首先检查控制点
  //     final controlPoint = _lassoSelection.getControlPoint(
  //         _lassoSelection.selectionRect!, point);
  //     if (controlPoint != null) {
  //       print('${DateTime.now()} : clicked on control point $controlPoint');
  //       _activeControlPoint = controlPoint;
  //       _lassoSelection.dragStartOffset = point;
  //       _lassoSelection.originalPositions = _lassoSelection.selectedStrokes
  //           .expand((stroke) => stroke.points)
  //           .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
  //           .toList();
  //       return;
  //     }

  //     // 然后检查选择框内部
  //     if (_lassoSelection.isPointOnSelectionRect(point)) {
  //       print('${DateTime.now()} : clicked inside selection rect');
  //       _lassoSelection.isDraggingSelection = true;
  //       _lassoSelection.dragStartOffset = point;
  //       _lassoSelection.originalPositions = _lassoSelection.selectedStrokes
  //           .expand((stroke) => stroke.points)
  //           .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
  //           .toList();
  //       return;
  //     }

  //     // 如果点击在选择框外部，清除选择
  //     // print(
  //     //     '${DateTime.now()} : clicked outside selection rect, clearing selection');
  //     _lassoSelection.clearSelection();
  //     setState(() {});
  //   }

  //   // if (drawingProvider.isDrawingMode) {
  //   switch (drawingProvider.strokeType) {
  //     case ToolType.pen:
  //       _currentStroke = Stroke(
  //         paint: Paint()
  //           ..color = drawingProvider.penColor
  //           ..strokeWidth = drawingProvider.penWidth / scale
  //           ..strokeCap = StrokeCap.round
  //           ..strokeJoin = StrokeJoin.round
  //           ..style = PaintingStyle.stroke,
  //         pageNumber: widget.page.pageNumber,
  //         tool: Pen(),
  //         initialPoints: [Point(point.dx, point.dy)],
  //       );
  //       break;
  //     case ToolType.marker:
  //       _currentStroke = Stroke(
  //         paint: Paint()
  //           ..color = drawingProvider.markerColor
  //               .withOpacity(drawingProvider.markerOpacity)
  //           ..strokeWidth = drawingProvider.markerWidth / scale
  //           ..strokeCap = StrokeCap.round
  //           ..strokeJoin = StrokeJoin.round
  //           ..style = PaintingStyle.stroke
  //           ..blendMode = BlendMode.srcOver,
  //         pageNumber: widget.page.pageNumber,
  //         tool: MTool(),
  //         initialPoints: [Point(point.dx, point.dy)],
  //       );
  //     case ToolType.shape:
  //       // 创建填充画笔
  //       final fillPaint = Paint()
  //         ..color = drawingProvider.shapeFillColor
  //             .withOpacity(drawingProvider.shapeFillOpacity)
  //         ..style = PaintingStyle.fill;

  //       // 只对封闭图形设置填充画笔
  //       final bool isClosedShape = [
  //         ShapeType.rectangle,
  //         ShapeType.circle,
  //         ShapeType.triangle,
  //         ShapeType.star,
  //       ].contains(drawingProvider.currentShape);

  //       Tool tool = Shape(
  //         drawingProvider.currentShape,
  //         fillPaint: isClosedShape ? fillPaint : null, // 只有封闭图形才设置填充画笔
  //       );

  //       _currentStroke = Stroke(
  //         paint: Paint()
  //           ..color = drawingProvider.shapeColor
  //           ..strokeWidth = drawingProvider.shapeWidth / scale
  //           ..strokeCap = StrokeCap.round
  //           ..strokeJoin = StrokeJoin.round
  //           ..style = PaintingStyle.stroke,
  //         pageNumber: widget.page.pageNumber,
  //         tool: tool,
  //         initialPoints: [Point(point.dx, point.dy)],
  //       );
  //     case ToolType.lasso:
  //       // 开始新的套索选择时清除旧的选择
  //       _lassoSelection.clearSelection();
  //       _lassoSelection.lassoPath = Path();
  //       _lassoSelection.lassoPath!.moveTo(point.dx, point.dy);
  //       _currentStroke = Stroke(
  //         paint: Paint()
  //           ..color = Colors.blue.withOpacity(0.5)
  //           ..strokeWidth = 1 / scale
  //           ..style = PaintingStyle.stroke,
  //         pageNumber: widget.page.pageNumber,
  //         tool: Lasso(),
  //         initialPoints: [Point(point.dx, point.dy)],
  //       );
  //     case ToolType.text:
  //       _createNewTextInput(point, context, markerVm);
  //       break;
  //     case ToolType.image:
  //       if (drawingProvider.imagePath != null) {
  //         _loadImage(drawingProvider.imagePath!).then((image) {
  //           setState(() {
  //             _currentImage = image;
  //             _imagePosition = Offset(point.dx.toDouble(), point.dy.toDouble());
  //             _imageSize = _calculateFitSize(
  //               Size(image.width.toDouble(), image.height.toDouble()),
  //               const Size(200, 200), // 默认最大尺寸
  //             );
  //           });
  //         });
  //       }
  //       break;
  //     case ToolType.eraser:
  //       // _eraseAtPoint(point, markerVm);
  //       eraseAtPoint(point, markerVm, widget.strokes,
  //           drawingProvider.eraserSize, widget.page.pageNumber);
  //       break;
  //   }

  //   // if (drawingProvider.isEraserMode) {
  //   //   _eraseAtPoint(point, markerVm);
  //   // }
  //   // }
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
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.open_with, size: 12, color: Colors.white),
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
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
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
