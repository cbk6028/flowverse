import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/models/tool.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flowverse/models/stroke.dart';


class TextTool extends Tool {
  @override
  final ToolType type = ToolType.text;
  String text;
  double fontSize;
  Color color;

  TextTool({
    this.text = '',
    this.fontSize = 14.0,
    this.color = Colors.black,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'fontSize': fontSize,
        'color': color.value,
      };

  static TextTool fromJson(Map<String, dynamic> json) => TextTool(
        text: json['text'],
        fontSize: json['fontSize'],
        color: Color(json['color']),
      );

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    final textTool = stroke.tool as TextTool;
    final textSpan = TextSpan(
      text: textTool.text,
      style: TextStyle(
        color: textTool.color,
        fontSize: textTool.fontSize,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final position = Offset(
      stroke.points[0].x.toDouble(),
      stroke.points[0].y.toDouble(),
    );
    textPainter.paint(canvas, position);
  }
}