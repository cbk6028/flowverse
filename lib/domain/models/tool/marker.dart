import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flutter/material.dart';
import 'package:flov/domain/models/tool/stroke.dart';

class MTool extends Tool {
  @override
  final ToolType type = ToolType.marker;

  @override
  Map<String, dynamic> toJson() => {'type': type.name};

  static MTool fromJson(Map<String, dynamic> _) => MTool();

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    final path = Path();
    path.moveTo(stroke.points[0].x.toDouble(), stroke.points[0].y.toDouble());

    for (var i = 1; i < stroke.points.length; i++) {
      path.lineTo(
        stroke.points[i].x.toDouble(),
        stroke.points[i].y.toDouble(),
      );
    }

    canvas.drawPath(path, stroke.paint);
  }
}
