import 'dart:math';
import 'dart:ui';
// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/annotation/underline.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flov/config/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class Stroke {
  final Paint paint;
  final PageNumber pageNumber;
  final List<Point> points;
  final Tool tool;
  final int timestamp = DateTime.now().millisecondsSinceEpoch;

  Stroke({
    required this.paint,
    required this.pageNumber,
    required this.tool,
    required List<Point> initialPoints,
  }) : points = List<Point>.from(initialPoints);

  Map<String, dynamic> toJson() => {
        'paint': paint.toJson(),
        'points': points.map((p) => [p.x, p.y]).toList(),
        'pageNumber': pageNumber,
        'tool': tool.toJson(),
        'timestamp': timestamp,
      };

  factory Stroke.fromJson(Map<String, dynamic> json) => Stroke(
        paint: PaintJson.fromJson(json['paint']),
        pageNumber: json['pageNumber'],
        tool: Tool.fromJson(json['tool']),
        initialPoints: (json['points'] as List)
            .map((p) => Point<num>(p[0], p[1]))
            .toList(),
      );
}

// 定义操作类型
enum MarkerOperation { add, remove }

// 定义操作记录类
class MarkerAction {
  final Marker marker;
  final MarkerOperation operation;
  final int pageNumber;

  MarkerAction(this.marker, this.operation, this.pageNumber);
}

enum MarkerType {
  highlight,
  underline,
  strikethrough,
}

abstract class MarkerTool {
  MarkerType get type;
  Map<String, dynamic> toJson();

  static MarkerTool fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'highlight':
        return HighlightMarkerTool.fromJson(json);
      case 'underline':
        return UnderlineMarkerTool.fromJson(json);
      case 'strikethrough':
        return StrikethroughMarkerTool.fromJson(json);
      default:
        throw UnsupportedError('Unknown tool type');
    }
  }
}

class HighlightMarkerTool extends MarkerTool {
  HighlightMarkerTool();

  @override
  final MarkerType type = MarkerType.highlight;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'highlight',
      };

  static HighlightMarkerTool fromJson(Map<String, dynamic> json) =>
      HighlightMarkerTool();
}

class StrikethroughMarkerTool extends MarkerTool {
  StrikethroughMarkerTool();

  @override
  final MarkerType type = MarkerType.strikethrough;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'highlight',
      };

  static StrikethroughMarkerTool fromJson(Map<String, dynamic> json) =>
      StrikethroughMarkerTool();
}

// 修改现有的 UnderlineMarkerTool
class UnderlineMarkerTool extends MarkerTool {
  final UnderlineStyle style;

  UnderlineMarkerTool({
    this.style = UnderlineStyle.solid,
  });

  @override
  final MarkerType type = MarkerType.underline; // 修改为 marker 类型

  // 根据样式获取下划线路径的方法
  Path getUnderlinePath(Offset start, Offset end) {
    final path = Path();

    switch (style) {
      case UnderlineStyle.solid:
        path.moveTo(start.dx, start.dy);
        path.lineTo(end.dx, end.dy);
        break;

      case UnderlineStyle.dashed:
        const dashWidth = 5.0;
        const dashSpace = 5.0;
        double distance = (end.dx - start.dx);
        double drawn = 0;

        while (drawn < distance) {
          double toDraw = min(dashWidth, distance - drawn);
          path.moveTo(start.dx + drawn, start.dy);
          path.lineTo(start.dx + drawn + toDraw, start.dy);
          drawn += toDraw + dashSpace;
        }
        break;

      case UnderlineStyle.dotted:
        const dotSpace = 4.0;
        double distance = (end.dx - start.dx);
        double drawn = 0;

        while (drawn < distance) {
          path.addOval(Rect.fromCircle(
            center: Offset(start.dx + drawn, start.dy),
            radius: 1.0,
          ));
          drawn += dotSpace;
        }
        break;

      case UnderlineStyle.wavy:
        const waveWidth = 3.0;
        const waveHeight = 2.0;
        double distance = end.dx - start.dx;
        int numWaves = (distance / (2 * waveWidth)).floor(); // 计算完整的波浪数
        double remaining = distance - numWaves * (2 * waveWidth); // 剩余部分

        path.moveTo(start.dx, start.dy);

        for (int i = 0; i < numWaves; i++) {
          path.relativeQuadraticBezierTo(
              waveWidth / 2, -waveHeight, waveWidth, 0);
          path.relativeQuadraticBezierTo(
              waveWidth / 2, waveHeight, waveWidth, 0);
        }

        // 处理剩余的部分，平滑收尾
        if (remaining > 0) {
          path.relativeQuadraticBezierTo(
              remaining / 2, -waveHeight, remaining, 0);
        }
        break;
    }

    return path;
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'underline',
        'style': style.name,
      };

  static UnderlineMarkerTool fromJson(Map<String, dynamic> json) =>
      UnderlineMarkerTool(
        style: UnderlineStyle.values.firstWhere((e) => e.name == json['style']),
      );
}

class Marker {
  final DateTime timestamp;
  final Paint paint;
  final PageNumber pageNumber;
  List<Point> points = [];
  final MarkerTool tool;
  final PdfTextRanges? ranges;

  Marker(
    this.timestamp,
    this.paint,
    this.points,
    this.pageNumber,
    this.tool, {
    this.ranges,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toString(),
      'paint': paint.toJson(),
      'points': points.map((p) => [p.x, p.y]).toList(),
      'pageNumber': pageNumber,
      'tool': tool.toJson(),
    };
  }

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
      DateTime.parse(json['timestamp']),
      PaintJson.fromJson(json['paint']),
      (json['points'] as List).map((p) => Point<num>(p[0], p[1])).toList(),
      json['pageNumber'],
      MarkerTool.fromJson(json['tool']),
      ranges: null,
    );
  }
}

extension PaintJson on Paint {
  Map<String, dynamic> toJson() => {
        'color': color.value,
        'style': style.toString(),
        'strokeWidth': strokeWidth,
        'alpha': color.alpha,
      };

  static Paint fromJson(Map<String, dynamic> json) => Paint()
    ..color = Color(json['color']).withAlpha(json['alpha'])
    ..style =
        PaintingStyle.values.firstWhere((e) => e.toString() == json['style'])
    ..strokeWidth = json['strokeWidth'];
}
