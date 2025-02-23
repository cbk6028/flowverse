import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flutter/material.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';

enum ShapeType {
  line, // 直线
  rectangle, // 矩形
  circle, // 圆形
  arrow, // 箭头
  triangle, // 三角形
  star, // 五角星
}

class Shape extends Tool {
  @override
  final ToolType type = ToolType.shape;

  final ShapeType shapeType;
  final Paint? fillPaint; // 添加填充画笔

  Shape(this.shapeType, {this.fillPaint});

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'shapeType': shapeType.name,
        'fillPaint': fillPaint?.toJson(),
      };

  static Shape fromJson(Map<String, dynamic> json) => Shape(
        ShapeType.values.firstWhere((e) => e.name == json['shapeType']),
        fillPaint: json['fillPaint'] != null
            ? PaintJson.fromJson(json['fillPaint'])
            : null,
      );

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    final shapeTool = stroke.tool as Shape;
    switch (shapeTool.shapeType) {
      case ShapeType.rectangle:
        final rect = Rect.fromPoints(
          Offset(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
          Offset(
              stroke.points.last.x.toDouble(), stroke.points.last.y.toDouble()),
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
          Offset(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
          Offset(
              stroke.points.last.x.toDouble(), stroke.points.last.y.toDouble()),
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
          Offset(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble()),
          Offset(
              stroke.points.last.x.toDouble(), stroke.points.last.y.toDouble()),
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
  }

  void _drawArrow(Path path, Offset start, Offset end) {
    final vector = end - start;
    final length = vector.distance;
    final unitVector = vector / length;
    final normal = Offset(-unitVector.dy, unitVector.dx);

    final arrowLength = length * 0.2;
    final arrowWidth = length * 0.1;

    final arrowBase = end - unitVector * arrowLength;
    final arrowLeft = arrowBase + normal * arrowWidth;
    final arrowRight = arrowBase - normal * arrowWidth;

    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);
    path.moveTo(end.dx, end.dy);
    path.lineTo(arrowLeft.dx, arrowLeft.dy);
    path.moveTo(end.dx, end.dy);
    path.lineTo(arrowRight.dx, arrowRight.dy);
  }

  void _drawTriangle(Path path, Offset start, Offset end) {
    final width = end.dx - start.dx;
    final height = end.dy - start.dy;

    path.moveTo(start.dx + width / 2, start.dy); // 顶点
    path.lineTo(start.dx, end.dy); // 左下角
    path.lineTo(end.dx, end.dy); // 右下角
    path.close();
  }

  void _drawStar(Path path, Offset start, Offset end) {
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final radius = (end - start).distance / 2;
    final innerRadius = radius * 0.4;

    for (var i = 0; i < 5; i++) {
      final outerAngle = -pi / 2 + 2 * pi * i / 5;
      final innerAngle = outerAngle + pi / 5;

      final outerPoint = Offset(
        center.dx + radius * cos(outerAngle),
        center.dy + radius * sin(outerAngle),
      );
      final innerPoint = Offset(
        center.dx + innerRadius * cos(innerAngle),
        center.dy + innerRadius * sin(innerAngle),
      );

      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
  }
}
