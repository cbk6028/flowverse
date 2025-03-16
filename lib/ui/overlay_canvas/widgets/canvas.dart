import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/ui/overlay_canvas/vm/handler.dart';
import 'package:flutter/material.dart';

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

    // 绘制已保存的笔画
    // logger.i('CanvasPainter: Drawing saved strokes - Count: ${strokes.length}');
    for (final stroke in strokes) {
      stroke.tool.draw(canvas, stroke.paint, stroke);
    }

    // 绘制当前正在绘制的笔画
    // logger.d('CanvasPainter: Drawing current stroke - ${handler?.currentStroke}');
    if (handler?.currentStroke != null) {
      // logger.i('CanvasPainter: Drawing current stroke');
      handler!.currentStroke!.tool
          .draw(canvas, handler!.currentStroke!.paint, handler!.currentStroke!);
    }

    if (handler is EraserHandler) {
      handler!.draw(canvas, size);
    }

    if (handler is LassoHandler) {
      handler!.draw(canvas, size);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return true;
  }
}
