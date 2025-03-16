import 'dart:math';
import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/shape.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flov/config/type.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:pdfrx/pdfrx.dart';
import 'package:flov/domain/models/tool/stroke.dart';

class Eraser extends Tool {
  @override
  final ToolType type = ToolType.eraser;

  @override
  Map<String, dynamic> toJson() => {'type': type.name};

  static Eraser fromJson(Map<String, dynamic> _) => Eraser();

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    // TODO: implement draw for EraserTool
  }
}

  double calculateDistance(Offset point1, Offset point2) {
    final dx = point1.dx - point2.dx;
    final dy = point1.dy - point2.dy;
    return sqrt(dx * dx + dy * dy);
  }



  Rect calculateShapeBounds(List<Point> points) {
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

  void eraseAtPoint(Offset point, MarkerViewModel markerVm, List strokes, double eraserRadius, PageNumber pageNumber) {

    // 检查每个笔画
    for (var i = strokes.length - 1; i >= 0; i--) {
      final stroke = strokes[i];
      bool shouldErase = false;

      if (stroke.tool is Shape) {
        // 对于形状，我们需要检查整个形状区域
        final bounds = calculateShapeBounds(stroke.points);
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
          final distance = calculateDistance(
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
        markerVm.removeStroke(pageNumber, stroke);
      }
    }
  }