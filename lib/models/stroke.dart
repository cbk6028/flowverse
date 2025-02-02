import 'dart:math';
import 'dart:ui';
// import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/type.dart';
import 'package:pdfrx/pdfrx.dart';

enum StrokeType {
  pen,
  marker,
  shape,
  lasso, // 新增套索类型
}

enum ShapeType {
  line, // 直线
  rectangle, // 矩形
  circle, // 圆形
  arrow, // 箭头
    triangle, // 新增三角形
  star,     // 新增五角星
}

abstract class Tool {
  StrokeType get type;
  Map<String, dynamic> toJson();

  static Tool fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'pen':
        return PenTool.fromJson(json);
      case 'shape':
        return ShapeTool.fromJson(json);
      case 'lasso':
        return LassoTool.fromJson(json);
      default:
        throw UnsupportedError('Unknown tool type');
    }
  }
}

class PenTool extends Tool {
  @override
  final StrokeType type = StrokeType.pen;

  @override
  Map<String, dynamic> toJson() => {'type': type.name};

  static PenTool fromJson(Map<String, dynamic> _) => PenTool();
}

class ShapeTool extends Tool {
  final ShapeType shapeType;

  ShapeTool(this.shapeType);

  @override
  final StrokeType type = StrokeType.shape;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'shapeType': shapeType.name,
      };

  static ShapeTool fromJson(Map<String, dynamic> json) => ShapeTool(
      ShapeType.values.firstWhere((e) => e.name == json['shapeType']));
}

class LassoTool extends Tool {
  @override
  final StrokeType type = StrokeType.lasso;

  @override
  Map<String, dynamic> toJson() => {'type': type.name};

  static LassoTool fromJson(Map<String, dynamic> _) => LassoTool();
}

class Stroke {
  final Paint paint;
  final PageNumber pageNumber;
  final List<Point> points = [];
  final Tool tool;
  final int timestamp = DateTime.now().millisecondsSinceEpoch;

  Stroke(
      {required this.paint,
      required this.pageNumber,
      required this.tool,
      List<Point> initialPoints = const []}) {
    points.addAll(initialPoints);
  }

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

enum MarkerType { highlight, underline, strikethrough }

class Marker {
  final DateTime timestamp;
  final Paint paint;
  final PageNumber pageNumber;
  List<Point> points = []; // 改为可变列表
  final MarkerType type;
  final PdfTextRanges? ranges;

  Marker(
    this.timestamp,
    this.paint,
    this.points, // 改为初始点列表
    this.pageNumber, {
    this.type = MarkerType.highlight,
    this.ranges,
  });

  Map<String, dynamic> toJson() {
    return {
      // 'color': qcolor.value,
      'timestamp': timestamp.toString(),
      'paint': paint.toJson(),
      'points': points.map((p) => [p.x, p.y]).toList(),
      // 'strokeWidth': paint.strokeWidth,
      'pageNumber': pageNumber,
      'type': type.name, // 只保存枚举名称
    };
  }

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
        DateTime.parse(json['timestamp']),
        PaintJson.fromJson(json['paint']),
        (json['points'] as List).map((p) => Point<num>(p[0], p[1])).toList(),
        // strokeWidth: json['strokeWidth'],
        json['pageNumber'],
        type: MarkerType.values.byName(json['type'].split('.').last), // 提取枚举名称
        ranges: null);
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
