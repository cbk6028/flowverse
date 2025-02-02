import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowverse/view_models/reader_vm.dart';
import 'dart:math';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/provider/drawing_provider.dart';
// import 'package:simple_painter/simple_painter.dart';
import 'package:pdfrx/pdfrx.dart';
// import 'dart:ui' as ui';

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

  // 使用PDF原始尺寸的比例计算缩放
  double get scale => widget.pageRect.width / widget.page.width;

  // 转换屏幕坐标到PDF坐标
  Offset _toPageCoordinate(Offset screenPoint) {
    return Offset(screenPoint.dx / scale, screenPoint.dy / scale);
  }

  @override
  Widget build(BuildContext context) {
    // final drawingProvider = context.read<DrawingProvider>();
    // final markerVm = context.read<MarkerVewModel>();
    return Consumer<MarkerVewModel>(builder: (context, markerVm, child) {
      final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];

      return Consumer<DrawingProvider>(
          builder: (context, drawingProvider, child) {
        return Listener(
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
              setState(() => _isPointerInside = false);
            },
            child: IgnorePointer(
              ignoring: !drawingProvider.isDrawingMode &&
                  !drawingProvider.isEraserMode,
              child: GestureDetector(
                onPanStart: (details) {
                  _handlePanStart(drawingProvider, context, details, markerVm);
                },
                onPanUpdate: (details) {
                  _handlePanUpdate(drawingProvider, context, details, markerVm);
                },
                onPanEnd: (details) {
                  _handlePanEnd(drawingProvider, markerVm);
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
                    // shapeType: drawingProvider.currentShape,
                  ),
                  size: widget.pageRect.size,
                ),
              ),
            )

            // CustomPaint(
            //   painter: _DrawingPainter(
            //     strokes: [...strokes, if (_currentStroke != null) _currentStroke!],
            //     scale: scale,
            //     pageSize: widget.page.size,
            //     screenSize: widget.pageRect.size,
            //     eraserPosition: _isPointerInside ? _currentEraserPosition : null,
            //     eraserSize: drawingProvider.strokeWidth,
            //     // shapeType: drawingProvider.currentShape,
            //   ),
            //   size: widget.pageRect.size,
            // ),
            // child: CustomPaint(
            //   painter: _DrawingPainter(
            //     strokes: widget.strokes,
            //     scale: _currentScale,
            //     pageSize: widget.page.size,
            //     screenSize: widget.pageRect.size,
            //     eraserPosition: _isPointerInside ? _currentEraserPosition : null,
            //     eraserSize: drawingProvider.strokeWidth,
            //   ),
            //   size: widget.pageRect.size,
            // ),
            );
      });
    });
  }

  void _handlePanEnd(DrawingProvider drawingProvider, MarkerVewModel markerVm) {
    if (drawingProvider.isDrawingMode && _currentStroke != null) {
      markerVm.addStroke(_currentStroke!, widget.page.pageNumber);
      _currentStroke = null;
    }
  }

  void _handlePanUpdate(DrawingProvider drawingProvider, BuildContext context,
      DragUpdateDetails details, MarkerVewModel markerVm) {
    if (drawingProvider.isDrawingMode && _currentStroke != null) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final point =
          _toPageCoordinate(box.globalToLocal(details.globalPosition));

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
      final RenderBox box = context.findRenderObject() as RenderBox;
      final point =
          _toPageCoordinate(box.globalToLocal(details.globalPosition));
      _eraseAtPoint(point, markerVm);
    }
  }

  void _handlePanStart(DrawingProvider drawingProvider, BuildContext context,
      DragStartDetails details, MarkerVewModel markerVm) {
    if (drawingProvider.isDrawingMode || drawingProvider.isEraserMode) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final point =
          _toPageCoordinate(box.globalToLocal(details.globalPosition));
      if (drawingProvider.isEraserMode) {
        _eraseAtPoint(point, markerVm);
      } else {
        Tool tool = PenTool();
        ;
        if (drawingProvider.strokeType == StrokeType.pen) {
          tool = PenTool();
        } else if (drawingProvider.strokeType == StrokeType.shape) {
          tool = ShapeTool(drawingProvider.currentShape);
        }
        _currentStroke = Stroke(
          paint: Paint()
            ..color = Colors.red
            ..strokeWidth = drawingProvider.strokeWidth / scale
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
          pageNumber: widget.page.pageNumber,
          tool: tool,
          initialPoints: [Point(point.dx, point.dy)],
        );
      }
    }
  }
  // @override
  // Widget build(BuildContext context) {
  //   print('pageSize: ${widget.page.size}');
  //   print('pageRectSize: ${widget.pageRect.size}');
  //   print('scale: $scale');
  //   final markerVm = context.watch<MarkerVewModel>();
  //   final strokes = markerVm.strokes[widget.page.pageNumber] ?? [];

  //   return Consumer<DrawingProvider>(
  //     builder: (context, drawingProvider, child) {
  //       // 确保 controller 已经初始化并且大小正确
  //       // if (markerVm.painterController == null) {
  //       //   markerVm.painterController = PainterController(
  //       //       settings: PainterSettings(size: widget.pageRect.size));
  //       // } else {
  //       //   markerVm.painterController!.value = markerVm
  //       //       .painterController!.value
  //       //       .copyWith(settings: PainterSettings(size: widget.pageRect.size));
  //       // }

  //       return Positioned.fromRect(
  //         rect: Rect.fromLTRB(
  //             0, 0, widget.pageRect.width, widget.pageRect.height),
  //         child: IgnorePointer(
  //           ignoring:
  //               !drawingProvider.isDrawingMode && !drawingProvider.isEraserMode,
  //           child: GestureDetector(
  //             onPanStart: (details) {
  //               if (drawingProvider.isDrawingMode ||
  //                   drawingProvider.isEraserMode) {
  //                 final RenderBox box = context.findRenderObject() as RenderBox;
  //                 final point = _toPageCoordinate(
  //                     box.globalToLocal(details.globalPosition));
  //                 if (drawingProvider.isEraserMode) {
  //                   _eraseAtPoint(point, markerVm);
  //                 } else {
  //                   Tool tool = PenTool();;
  //                   if (drawingProvider.strokeType == StrokeType.pen) {
  //                     tool = PenTool();
  //                   } else if (drawingProvider.strokeType == StrokeType.shape) {
  //                     tool = ShapeTool(drawingProvider.currentShape);
  //                   }
  //                   _currentStroke = Stroke(
  //                     paint: Paint()
  //                       ..color = Colors.red
  //                       ..strokeWidth = drawingProvider.strokeWidth / scale
  //                       ..strokeCap = StrokeCap.round
  //                       ..strokeJoin = StrokeJoin.round
  //                       ..style = PaintingStyle.stroke,
  //                     pageNumber: widget.page.pageNumber,
  //                     tool: tool,
  //                     initialPoints: [Point(point.dx, point.dy)],
  //                   );
  //                 }
  //               }
  //             },
  //             onPanUpdate: (details) {
  //               if (drawingProvider.isDrawingMode && _currentStroke != null) {
  //                 final RenderBox box = context.findRenderObject() as RenderBox;
  //                 final point = _toPageCoordinate(
  //                     box.globalToLocal(details.globalPosition));

  //                 if (_currentStroke!.tool.type == StrokeType.pen) {
  //                   _currentStroke!.points.add(Point(point.dx, point.dy));
  //                 } else {
  //                   // 对于形状，我们只需要更新最后一个点
  //                   if (_currentStroke!.points.length > 1) {
  //                     _currentStroke!.points.removeLast();
  //                   }
  //                   _currentStroke!.points.add(Point(point.dx, point.dy));
  //                 }
  //                 setState(() {});
  //               } else if (drawingProvider.isEraserMode) {
  //                 final RenderBox box = context.findRenderObject() as RenderBox;
  //                 final point = _toPageCoordinate(
  //                     box.globalToLocal(details.globalPosition));
  //                 _eraseAtPoint(point, markerVm);
  //               }
  //             },
  //             onPanEnd: (details) {
  //               if (drawingProvider.isDrawingMode && _currentStroke != null) {
  //                 markerVm.addStroke(_currentStroke!, widget.page.pageNumber);
  //                 _currentStroke = null;
  //               }
  //             },
  //             child: CustomPaint(
  //               painter: _DrawingPainter(
  //                 strokes: [
  //                   ...strokes,
  //                   if (_currentStroke != null) _currentStroke!
  //                 ],
  //                 scale: scale,
  //                 pageSize: widget.page.size,
  //                 screenSize: widget.pageRect.size,
  //                 // shapeType: drawingProvider.currentShape,
  //               ),
  //               size: widget.pageRect.size,
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _eraseAtPoint(Offset point, MarkerVewModel markerVm) {
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
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final double scale;
  final Size pageSize;
  final Size screenSize;
  final Offset? eraserPosition;
  final double eraserSize;
  // final ShapeType shapeType;

  _DrawingPainter({
    required this.strokes,
    required this.scale,
    required this.pageSize,
    required this.screenSize,
    required this.eraserPosition,
    required this.eraserSize,
    // required this.shapeType,
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
      _paintStroke(canvas, stroke);
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
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    // switch (stroke.strokeType) {
    //   case StrokeType.highlight:
    //     break;
    //   case StrokeType.pen:
    //     break;
    //   case StrokeType.shape:
    //     break;
    // }

    if (stroke.tool.type == StrokeType.pen) {
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
          canvas.drawRect(rect, stroke.paint);
          break;
        case ShapeType.circle:
          final rect = Rect.fromPoints(
            Offset(
                stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
            Offset(stroke.points.last.x.toDouble(),
                stroke.points.last.y.toDouble()),
          );
          canvas.drawOval(rect, stroke.paint);
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
        // 在 drawing_overlay.dart 中添加绘制逻辑
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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
