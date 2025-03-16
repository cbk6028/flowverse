import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flutter/material.dart';
import 'package:flov/domain/models/tool/stroke.dart';


class ImageTool extends Tool {
  @override
  final ToolType type = ToolType.image;
  final String imagePath;
  final Size imageSize;

  ImageTool({
    required this.imagePath,
    required this.imageSize,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'imagePath': imagePath,
        'imageSize': {
          'width': imageSize.width,
          'height': imageSize.height,
        },
      };

  static ImageTool fromJson(Map<String, dynamic> json) => ImageTool(
        imagePath: json['imagePath'],
        imageSize: Size(
          json['imageSize']['width'],
          json['imageSize']['height'],
        ),
      );

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    // TODO: implement draw for ImageTool
  }
}
