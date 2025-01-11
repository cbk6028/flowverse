import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:convert';
import 'dart:io';

typedef PageNumber = int;



enum MarkerType { highlight, underline }


class Marker {
  final String key;
  final Paint paint;
  final PageNumber pageNumber;
  // final Color color;
  // final double strokeWidth;
  final List<Point> points = []; // 改为可变列表
  final MarkerType type;
  // final double opacity;
  final PdfTextRanges? ranges;
  // bool isDrawn;

  Marker(
    this.key,
    this.paint,
    List<Point> initialPoints, // 改为初始点列表
    this.pageNumber, {
    // this.strokeWidth = 0.8,
    this.type = MarkerType.highlight,
    // this.opacity = 1.0,
    this.ranges,
    // this.isDrawn = false,
  }) {
    points.addAll(initialPoints); // 添加初始点
  }

  Map<String, dynamic> toJson() {
    return {
      // 'color': qcolor.value,
      'key': key,
      'paint': paint.toJson(),
      'points': points.map((p) => {'x': p.x, 'y': p.y}).toList(),
      // 'strokeWidth': strokeWidth,
      'pageNumber': pageNumber,
      'type': type.name,  // 只保存枚举名称
    };
  }

  factory Marker.fromJson(Map<String, dynamic> json) {
    return Marker(
        json['key'],
        PaintJson.fromJson(json['paint']),
        (json['points'] as List)
            .map((p) => Point<num>(p['x'], p['y']))
            .toList(),
        json['pageNumber'],
        type: MarkerType.values.byName(json['type'].split('.').last),  // 提取枚举名称
        ranges: null);
  }
}

extension PaintJson on Paint {
  Map<String, dynamic> toJson() => {
        'color': color.value,
        'style': style.toString(),
        'strokeWidth': strokeWidth,
      };

  static Paint fromJson(Map<String, dynamic> json) => Paint()
    ..color = Color(json['color'])
    ..style = PaintingStyle.values
        .firstWhere((e) => e.toString() == json['style'])
    ..strokeWidth = json['strokeWidth'];
}


class MarkerVewModel extends ChangeNotifier {
  final readerVm;

  MarkerVewModel(this.readerVm);

  // final Map<PageNumber, List<Marker>> _highlightMarkers = {};
  // final Map<PageNumber, List<Marker>> _underlineMarkers = {};

  final Map<PageNumber, List<Marker>> _strokes = {};

  var selectionColor = Colors.yellow;

  var underlineColor = Colors.yellow;
  var highlightColor = Colors.yellow;

  // 添加新的状态标志
  bool isHighlightMode = false;
  bool isUnderlineMode = false;
  var currentMarkerType = MarkerType.highlight;

  // 撤销和重做栈
  final List<Map<PageNumber, List<Marker>>> _undoStack = [];
  final List<Map<PageNumber, List<Marker>>> _redoStack = [];


  // 修改 selectedRanges 的 setter
  set selectedRanges(List<PdfTextRanges> ranges) {
    // _selectedRanges = ranges;

    if (ranges.isEmpty) {
      return;
    }

    // 实时应用效果
    switch (currentMarkerType) {
      case MarkerType.highlight:
        for (var range in ranges) {
          Paint paint = Paint()
            ..color = highlightColor.withAlpha(100)
            ..style = PaintingStyle.fill;

          Marker marker = Marker(
            '',
            // highlightColor,
            paint,
            [],
            range.pageText.pageNumber,
            // strokeWidth: 0.8,
            type: MarkerType.highlight,
            // opacity: 1.0,
            ranges: range,
            // isDrawn: false,
          );
          addMarker(marker);
        }
        break;
      case MarkerType.underline:
        for (var range in ranges) {
          Paint paint = Paint()
            ..color = underlineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8;

          Marker marker = Marker(
            '',
            // underlineColor,
            paint,
            [],
            range.pageText.pageNumber,
            // strokeWidth: 0.8,
            type: MarkerType.underline,
            // opacity: 1.0,
            ranges: range,
            // isDrawn: false,
          );
          addMarker(marker);
        }
        break;
    }
  }

  // List<PdfTextRanges> get selectedRanges => _selectedRanges;
  // List<PdfTextRanges> _selectedRanges = [];

  // 新增：添加标记
  void addMarker(Marker marker) {
    _undoStack.add(Map.from(_strokes));

    _redoStack.clear();

    if (_strokes.containsKey(marker.pageNumber)) {
      _strokes[marker.pageNumber]!.add(marker);
    } else {
      _strokes[marker.pageNumber] = [marker];
    }
  }

  // 新增：移除标记
  // void removeMarker(PageNumber pageNumber, Marker marker) {
  //   _undoStack.add(Map.from(_highlightMarkers));
  //   _redoStack.clear();
  //   if (_highlightMarkers.containsKey(pageNumber)) {
  //     _highlightMarkers[pageNumber]!.remove(marker);
  //     if (_highlightMarkers[pageNumber]!.isEmpty) {
  //       _highlightMarkers.remove(pageNumber);
  //     }
  //   }
  // }

  // 添加撤销功能
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(Map.from(_strokes));
      _strokes.clear();
      _strokes.addAll(_undoStack.removeLast());
      // notifyListeners();
      readerVm.notifyListeners();
    }
  }

  // 添加重做功能
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(Map.from(_strokes));
      _strokes.clear();
      _strokes.addAll(_redoStack.removeLast());
      // notifyListeners();
      readerVm.notifyListeners();
    }
  }

  // 保存高亮到文件
  Future<void> saveHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    // 合并两个列表中的高亮，使用Set去重
    // final allHighlights = .toList();
    final highlightsJson =
        _strokes.values.expand((h) => h).map((h) => h.toJson()).toList();
    // debugPrint(savePath);
    await File(savePath).writeAsString(jsonEncode(highlightsJson));
  }

  // 从文件加载高亮
  Future<void> loadHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      final List<dynamic> highlightsJson = jsonDecode(content);



      // 加载新数据
      for (final json in highlightsJson) {
        final stroke = Marker.fromJson(json);
        final pageNumber = stroke.pageNumber;

        if (!_strokes.containsKey(pageNumber)) {
          _strokes[pageNumber] = [];
        }
        _strokes[pageNumber]!.add(stroke);
      }

      readerVm.notifyListeners();
    }
  }

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = _strokes[page.pageNumber];
    if (markers == null) return;

    for (final marker in markers) {
      // 过滤保存的
      if (marker.ranges == null) {
        final paint = marker.paint;
        switch (marker.type) {
          case MarkerType.highlight:
            canvas.drawRect(
                Rect.fromLTRB(
                    marker.points[0].x as double,
                    marker.points[0].y as double,
                    marker.points[1].x as double,
                    marker.points[1].y as double),
                paint);
            break;
          case MarkerType.underline:
            canvas.drawLine(
                Offset(
                    marker.points[0].x as double, marker.points[0].y as double),
                Offset(
                    marker.points[1].x as double, marker.points[1].y as double),
                paint);
            break;
        }
        continue;
      }

      switch (marker.type) {
        case MarkerType.highlight:
          for (final range in marker.ranges!.ranges) {
            final f = PdfTextRangeWithFragments.fromTextRange(
              marker.ranges!.pageText,
              range.start,
              range.end,
            );

            if (f != null) {
              final bounds =
                  f.bounds.toRectInPageRect(page: page, pageRect: pageRect);
              debugPrint('range ${range}');
              debugPrint('bounds ${bounds}');
              debugPrint('$pageRect');
              canvas.drawRect(bounds, marker.paint);
              // 保存矩形的四个点
              marker.points.addAll([
                Point(bounds.left, bounds.top),
                Point(bounds.right, bounds.bottom),
              ]);
            }
          }
          break;

        case MarkerType.underline:
          for (final range in marker.ranges!.ranges) {
            final f = PdfTextRangeWithFragments.fromTextRange(
              marker.ranges!.pageText,
              range.start,
              range.end,
            );
            if (f != null) {
              final rect =
                  f.bounds.toRectInPageRect(page: page, pageRect: pageRect);
              canvas.drawLine(
                rect.bottomLeft,
                rect.bottomRight,
                marker.paint,
              );
              // 保存下划线的起点和终点
              marker.points.addAll([
                Point(rect.bottomLeft.dx, rect.bottomLeft.dy),
                Point(rect.bottomRight.dx, rect.bottomRight.dy),
              ]);
            }
          }
          break;
      }
    }
  }
}
