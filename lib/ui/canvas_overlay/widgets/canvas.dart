import 'dart:ui' as ui;

import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flowverse/ui/canvas_overlay/vm/handler.dart';
import 'package:flutter/material.dart';

// // import 'package:flowverse/domain/models/stroke.dart';
// class Painter extends CustomPainter {
//   final List<Stroke> strokes;
//   final double scale;
//   final Size pageSize;
//   final Size screenSize;
//   final Offset? eraserPosition;
//   final double eraserSize;
//   final Path? lassoPath;
//   final List<Stroke> selectedStrokes;
//   final Rect? selectionRect;
//   final ui.Image? currentImage;
//   final Offset? imagePosition;
//   final Size? imageSize;
//   final double rotationAngle;

//   Painter({
//     required this.strokes,
//     required this.scale,
//     required this.pageSize,
//     required this.screenSize,
//     required this.eraserPosition,
//     required this.eraserSize,
//     required this.lassoPath,
//     required this.selectedStrokes,
//     this.selectionRect,
//     this.currentImage,
//     this.imagePosition,
//     this.imageSize,
//     required this.rotationAngle,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     drawEraser(canvas);

//     // 计算实际缩放比例，确保完全贴合
//     final scaleX = screenSize.width / pageSize.width;
//     final scaleY = screenSize.height / pageSize.height;

//     drawInfo(canvas, scaleX, scaleY, size);

//     drawStrokes(canvas, strokes);

//     // 绘制套索选择区域
//     drawLasso(canvas, scale);
//   }

//   void drawStrokes(Canvas canvas, List strokes) {
//     // 绘制所有笔画
//     // pen marker shape
//     for (final stroke in strokes) {
//       if (stroke.tool.type != ToolType.lasso) {
//         // 不绘制套索工具的路径
//         _paintStroke(canvas, stroke);
//       }
//     }
//   }

//   void _paintStroke(Canvas canvas, Stroke stroke) {
//     if (stroke.points.isEmpty) return;
//     stroke.tool.draw(canvas, stroke.paint, stroke);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

//   void drawEraser(Canvas canvas) {
//     if (eraserPosition != null) {
//       final paint = Paint()
//         ..color = Colors.red.withOpacity(0.3)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 2;

//       canvas.drawCircle(
//         eraserPosition!,
//         eraserSize * 2,
//         paint..style = PaintingStyle.stroke,
//       );

//       canvas.drawCircle(
//         eraserPosition!,
//         eraserSize / 2,
//         paint
//           ..style = PaintingStyle.fill
//           ..color = Colors.red.withOpacity(0.1),
//       );
//     }
//   }

//   void drawLasso(Canvas canvas, double scale) {
//     // 绘制套索选择区域
//     // print('lassopath $lassoPath');
//     if (lassoPath != null) {
//       final xlassoPaint = Paint()
//         ..color = Colors.blue.withOpacity(0.2)
//         ..style = PaintingStyle.fill;
//       canvas.drawPath(lassoPath!, xlassoPaint);

//       final lassoStrokePaint = Paint()
//         ..color = Colors.blue
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.0;
//       canvas.drawPath(lassoPath!, lassoStrokePaint);
//     }

//     // 绘制选中效果
//     for (final stroke in selectedStrokes) {
//       final selectedPaint = Paint()
//         ..color = Colors.blue.withOpacity(0.2)
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = stroke.paint.strokeWidth + 4;
//       _paintStroke(canvas, stroke);
//     }

//     // 绘制选择框
//     if (selectionRect != null) {
//       canvas.save();

//       // 应用旋转变换
//       canvas.translate(selectionRect!.center.dx, selectionRect!.center.dy);
//       canvas.rotate(rotationAngle);
//       canvas.translate(-selectionRect!.center.dx, -selectionRect!.center.dy);

//       final selectionPaint = Paint()
//         ..color = Colors.blue
//         ..style = PaintingStyle.stroke
//         ..strokeWidth = 1.0;

//       // 绘制主矩形
//       canvas.drawRect(selectionRect!, selectionPaint);

//       // 绘制控制点
//       final controlPoints = [
//         selectionRect!.topLeft,
//         selectionRect!.topRight,
//         selectionRect!.bottomLeft,
//         selectionRect!.bottomRight,
//       ];

//       // 绘制旋转控制点
//       final rotatePoint = Offset(
//         selectionRect!.center.dx,
//         selectionRect!.top - 30,
//       );

//       // 绘制旋转控制点到矩形顶边的连接线
//       canvas.drawLine(
//         Offset(selectionRect!.center.dx, selectionRect!.top),
//         rotatePoint,
//         selectionPaint,
//       );

//       // 绘制所有控制点
//       final allPoints = [...controlPoints, rotatePoint];
//       for (var point in allPoints) {
//         canvas.drawCircle(
//           point,
//           4.0,
//           Paint()
//             ..color = Colors.white
//             ..style = PaintingStyle.fill,
//         );
//         canvas.drawCircle(
//           point,
//           4.0,
//           Paint()
//             ..color = Colors.blue
//             ..style = PaintingStyle.stroke
//             ..strokeWidth = 1.0,
//         );
//       }

//       canvas.restore();

//       // 如果有选中的笔画，也需要应用相同的变换
//       if (selectedStrokes.isNotEmpty) {
//         canvas.save();
//         canvas.translate(selectionRect!.center.dx, selectionRect!.center.dy);
//         canvas.rotate(rotationAngle);
//         canvas.translate(-selectionRect!.center.dx, -selectionRect!.center.dy);

//         for (final stroke in selectedStrokes) {
//           final selectedPaint = Paint()
//             ..color = Colors.blue.withOpacity(0.2)
//             ..style = PaintingStyle.stroke
//             ..strokeWidth = stroke.paint.strokeWidth + 4;
//           _paintStroke(canvas, stroke);
//         }

//         canvas.restore();
//       }
//     }
//   }

//   void drawInfo(Canvas canvas, double scaleX, double scaleY, Size size) {
//     // 添加坐标信息
//     final textPainter = TextPainter(
//       text: TextSpan(
//         text:
//             'Scale: ${scaleX.toStringAsFixed(2)} x ${scaleY.toStringAsFixed(2)}\n'
//             'Size: ${screenSize.width.toStringAsFixed(1)} x ${screenSize.height.toStringAsFixed(1)}\n'
//             'PDF Size: ${pageSize.width.toStringAsFixed(1)} x ${pageSize.height.toStringAsFixed(1)}',
//         style: TextStyle(
//           color: Colors.red,
//           fontSize: 12 / scaleX,
//           backgroundColor: Colors.white.withOpacity(0.8),
//         ),
//       ),
//       textDirection: TextDirection.ltr,
//     );
//     textPainter.layout();
//     textPainter.paint(canvas, Offset(10 / scaleX, 10 / scaleY));

//     // 绘制调试边框
//     final debugPaint = Paint()
//       ..color = Colors.red
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;

//     // 绘制缩放前的边框（屏幕坐标系）
//     canvas.drawRect(Offset.zero & size, debugPaint);

//     // 添加一个网格来显示缩放
//     final gridPaint = Paint()
//       ..color = Colors.blue.withOpacity(0.2)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 0.5;

//     // 绘制网格（每100像素一条线）
//     for (double i = 0; i < size.width; i += 100) {
//       canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
//     }
//     for (double i = 0; i < size.height; i += 100) {
//       canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
//     }

//     // 应用缩放，使用实际的缩放比例
//     canvas.scale(scaleX, scaleY);

//     // 绘制缩放后的边框（PDF坐标系）
//     final pdfDebugPaint = Paint()
//       ..color = Colors.green.withOpacity(0.3)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0 / scaleX;

//     canvas.drawRect(Offset.zero & pageSize, pdfDebugPaint);
//   }

//   void drawImage(Canvas canvas, double scale) {
//     // 绘制图片
//     if (currentImage != null && imagePosition != null && imageSize != null) {
//       final rect = Rect.fromLTWH(
//         imagePosition!.dx * scale,
//         imagePosition!.dy * scale,
//         imageSize!.width * scale,
//         imageSize!.height * scale,
//       );
//       canvas.drawImageRect(
//         currentImage!,
//         Rect.fromLTWH(0, 0, currentImage!.width.toDouble(),
//             currentImage!.height.toDouble()),
//         rect,
//         Paint(),
//       );
//     }
//   }
// }

// lib/ui/canvas/painters/canvas_painter.dart
class CanvasPainter extends CustomPainter {
  final ToolHandler? handler;
  final List<Stroke> strokes;
  final Size pageSize;
  final Size screenSize;
  final double scale;

  CanvasPainter({
    required this.handler,
    required this.strokes,
    required this.pageSize,
    required this.screenSize,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算实际缩放比例，确保完全贴合
    final scaleX = screenSize.width / pageSize.width;
    final scaleY = screenSize.height / pageSize.height;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // 先绘制已保存的笔画
    print('CanvasPainter: 开始绘制已保存的笔画，数量: ${strokes.length}');
    for (final stroke in strokes) {
      stroke.tool.draw(canvas, stroke.paint, stroke);
    }

    // 再绘制当前正在绘制的笔画
    if (handler?.currentStroke != null) {
      print('CanvasPainter: 绘制当前笔画');
      handler!.currentStroke!.tool
          .draw(canvas, handler!.currentStroke!.paint, handler!.currentStroke!);
    }

    if (handler != null) {
      print("handler != null");
      handler!.draw(canvas, size);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.handler?.currentStroke != handler?.currentStroke;
  }
}
