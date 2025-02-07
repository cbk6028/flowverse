import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/models/tool.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flowverse/models/stroke.dart';

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
