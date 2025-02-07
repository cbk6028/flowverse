import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/models/eraser.dart';
import 'package:flowverse/models/image.dart';
import 'package:flowverse/models/lasso.dart';
import 'package:flowverse/models/marker.dart';
import 'package:flowverse/models/pen.dart';
import 'package:flowverse/models/shape.dart';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/models/text.dart';
import 'package:flowverse/models/tool.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';


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
