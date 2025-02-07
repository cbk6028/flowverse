import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/models/tool.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flowverse/models/stroke.dart';

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
