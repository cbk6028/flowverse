import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/image.dart';
import 'package:flov/domain/models/tool/marker.dart';
import 'package:flov/domain/models/tool/pen.dart';
import 'package:flov/domain/models/tool/shape.dart';
import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/domain/models/tool/text.dart';
import 'package:flutter/material.dart';


enum ToolType {
  pen,
  marker, // 荧光笔
  shape,
  lasso, // 套索类型
  text, // 打字机类型
  image, // 图片类型
  eraser, // 橡皮擦类型
}


abstract class Tool {
  ToolType get type;
  Map<String, dynamic> toJson();
  void draw(Canvas canvas, Paint paint, Stroke stroke);
  static Tool fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'pen':
        return Pen.fromJson(json);
      case 'marker':
        return MTool.fromJson(json);
      case 'shape':
        return Shape.fromJson(json);
      // case 'lasso':
      //   return Lasso.fromJson(json);
      case 'text':
        return TextTool.fromJson(json);
      case 'image':
        return ImageTool.fromJson(json);
      // case 'eraser':
        // return Eraser.fromJson(json);
      default:
        throw Exception('Unknown tool type: $type');
    }
  }
}
