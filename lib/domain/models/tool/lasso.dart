import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flutter/material.dart';
import 'package:flov/domain/models/tool/stroke.dart';


class Lasso extends Tool {
  @override
  final ToolType type = ToolType.lasso;

  @override
  Map<String, dynamic> toJson() => {'type': type.name};

  static Lasso fromJson(Map<String, dynamic> _) => Lasso();

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    // TODO: implement draw for LassoTool
  }
}