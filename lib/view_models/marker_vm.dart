import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:convert';
import 'dart:io';

typedef PageNumber = int;

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

class Archive {
  final int version = 0;

  Map<PageNumber, List<Marker>> markers = {};
  final DateTime dateCreated;
  final DateTime? dateModified;

  Archive({required this.dateCreated, this.dateModified});

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'dateCreated': dateCreated.toIso8601String(),
      'dateModified': dateModified?.toIso8601String(),
      'markers': markers.map((pageNumber, markers) => MapEntry(
          pageNumber.toString(), markers.map((m) => m.toJson()).toList())),
    };
  }

  factory Archive.fromJson(Map<String, dynamic> json) {
    var archive = Archive(
      dateCreated: DateTime.parse(json['dateCreated']),
      dateModified: json['dateModified'] != null
          ? DateTime.parse(json['dateModified'])
          : null,
    );

    var markersJson = json['markers'] as Map<String, dynamic>;
    markersJson.forEach((pageStr, markersJson) {
      var pageNumber = int.parse(pageStr);
      var markers = (markersJson as List)
          .map((m) => Marker.fromJson(m as Map<String, dynamic>))
          .toList();
      archive.markers[pageNumber] = markers;
    });

    return archive;
  }
}

class Marker {
  final DateTime timestamp;
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
    this.timestamp,
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

class MarkerVewModel extends ChangeNotifier {
  final readerVm;

  MarkerVewModel(this.readerVm);

  // final Map<PageNumber, List<Marker>> _highlightMarkers = {};
  // final Map<PageNumber, List<Marker>> _underlineMarkers = {};

  final Map<PageNumber, List<Marker>> _strokes = {};
  Map<PageNumber, List<Marker>> applyStrokes = {};
  List<PdfTextRanges> selectedRanges = [];

  var selectionColor = Colors.yellow;

  var underlineColor = Colors.blue;
  var highlightColor = Colors.yellow;

  // 添加新的状态标志
  bool isHighlightMode = false;
  bool isUnderlineMode = false;
  var currentMarkerType = MarkerType.highlight;

  // 撤销和重做栈
  final List<MarkerAction> _undoStack = [];
  final List<MarkerAction> _redoStack = [];

  var strikethroughColor = Colors.red;

  // 修改 selectedRanges 的 setter
  // set selectedRanges(List<PdfTextRanges> ranges) {

  // }

  void applyMarkS() {
    var ranges = selectedRanges;

    if (ranges.isEmpty) {
      return;
    }

    for (var range in ranges) {
      Paint paint = Paint()
        ..color = strikethroughColor
        ..strokeWidth = 0.8
        ..style = PaintingStyle.fill;

      Marker marker = Marker(
        DateTime.now(),
        paint,
        [],
        range.pageText.pageNumber,
        type: MarkerType.strikethrough,
        ranges: range,
      );
      addMarker(marker);
    }

    readerVm.notifyListeners();
  }

  void applyMark() {
    // applyStrokes = Map.from(_strokes);
    // _selectedRanges = ranges;
    var ranges = selectedRanges;

    if (ranges.isEmpty) {
      return;
    }
    currentMarkerType = MarkerType.highlight;
    //
    // 实时应用效果
    switch (currentMarkerType) {
      case MarkerType.highlight:
        for (var range in ranges) {
          //  print('range.pageText.pageNumber: ${range.pageText.pageNumber}');
          Paint paint = Paint()
            ..color = highlightColor.withAlpha(100)
            ..style = PaintingStyle.fill;

          Marker marker = Marker(
            DateTime.now(),
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
            DateTime.now(),
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
          // addMarker(marker);
        }
        break;
      default:
        break;
    }

    // applyStrokes = Map.from(_strokes);

    // notifysListeners();
    readerVm.notifyListeners();
  }

  void applyMarkU() {
    // applyStrokes = Map.from(_strokes);
    // _selectedRanges = ranges;
    var ranges = selectedRanges;

    if (ranges.isEmpty) {
      return;
    }
    currentMarkerType = MarkerType.underline;
    // 实时应用效果
    switch (currentMarkerType) {
      case MarkerType.highlight:
        for (var range in ranges) {
          Paint paint = Paint()
            ..color = highlightColor.withAlpha(100)
            ..style = PaintingStyle.fill;

          Marker marker = Marker(
            DateTime.now(),
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
            DateTime.now(),
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
      default:
        break;
    }

    // applyStrokes = Map.from(_strokes);

    // notifysListeners();
    readerVm.notifyListeners();
  }

  // List<PdfTextRanges> get selectedRanges => _selectedRanges;
  // List<PdfTextRanges> _selectedRanges = [];

  // 新增：添加标记
  void addMarker(Marker marker) {
    if (!applyStrokes.containsKey(marker.pageNumber)) {
      applyStrokes[marker.pageNumber] = [];
    }
    applyStrokes[marker.pageNumber]!.add(marker);
    
    // 记录添加操作
    _undoStack.add(MarkerAction(marker, MarkerOperation.add, marker.pageNumber));
    _redoStack.clear(); // 清空重做栈
    
  
    readerVm.notifyListeners();
  }

  void removeMarker(int pageNumber, Marker marker) {
    applyStrokes[pageNumber]?.remove(marker);
    
    // 记录删除操作
    _undoStack.add(MarkerAction(marker, MarkerOperation.remove, pageNumber));
    _redoStack.clear();

    // 如果页面的标注列表为空，删除该页面的记录
    if (applyStrokes[pageNumber]?.isEmpty ?? false) {
      applyStrokes.remove(pageNumber);
    }

    readerVm.notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    switch (action.operation) {
      case MarkerOperation.add:
        // 撤销添加操作 -> 执行删除
        applyStrokes[action.pageNumber]?.remove(action.marker);
        if (applyStrokes[action.pageNumber]?.isEmpty ?? false) {
          applyStrokes.remove(action.pageNumber);
        }
        break;
      case MarkerOperation.remove:
        // 撤销删除操作 -> 执行添加
        if (!applyStrokes.containsKey(action.pageNumber)) {
          applyStrokes[action.pageNumber] = [];
        }
        applyStrokes[action.pageNumber]!.add(action.marker);
        break;
    }

    readerVm.notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    switch (action.operation) {
      case MarkerOperation.add:
        // 重做添加操作 -> 执行添加
        if (!applyStrokes.containsKey(action.pageNumber)) {
          applyStrokes[action.pageNumber] = [];
        }
        applyStrokes[action.pageNumber]!.add(action.marker);
        break;
      case MarkerOperation.remove:
        // 重做删除操作 -> 执行删除
        applyStrokes[action.pageNumber]?.remove(action.marker);
        if (applyStrokes[action.pageNumber]?.isEmpty ?? false) {
          applyStrokes.remove(action.pageNumber);
        }
        break;
    }

    readerVm.notifyListeners();
  }

  // 获取指定页面的所有标注
  List<Marker>? getMarkersForPage(int pageNumber) {
    return applyStrokes[pageNumber];
  }

  // 保存高亮到文件
  Future<void> saveHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    final archive = Archive(
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
    );
    archive.markers = Map.from(applyStrokes);

    final archiveJson = jsonEncode(archive.toJson());
    await File(savePath).writeAsString(archiveJson);
  }

  // 从文件加载高亮
  Future<void> loadHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final archive = Archive.fromJson(json);

      applyStrokes = Map.from(archive.markers);

      readerVm.notifyListeners();
    }
  }

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = applyStrokes[page.pageNumber];
    if (markers == null) return;

    for (final marker in markers) {
      // 过滤保存的
      if (marker.ranges == null) {
        final paint = marker.paint;
        switch (marker.type) {
          case MarkerType.highlight:
            canvas.drawRect(
                PdfRect(
                        marker.points[0].x as double,
                        marker.points[0].y as double,
                        marker.points[1].x as double,
                        marker.points[1].y as double)
                    .toRectInPageRect(page: page, pageRect: pageRect),
                paint);
            break;
          case MarkerType.underline:
            Rect rect = PdfRect(
                    marker.points[0].x as double,
                    marker.points[0].y as double,
                    marker.points[1].x as double,
                    marker.points[1].y as double)
                .toRectInPageRect(page: page, pageRect: pageRect);
            canvas.drawLine(Offset(rect.left, rect.bottom),
                Offset(rect.right, rect.bottom), paint);
            break;

          case MarkerType.strikethrough:
            Rect rect = PdfRect(
                    marker.points[0].x as double,
                    marker.points[0].y as double,
                    marker.points[1].x as double,
                    marker.points[1].y as double)
                .toRectInPageRect(page: page, pageRect: pageRect);

            canvas.drawLine(Offset(rect.left, (rect.bottom + rect.top) / 2),
                Offset(rect.right, (rect.bottom + rect.top) / 2), paint);
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
              // debugPrint('range ${range}');
              // debugPrint('bounds ${bounds}');
              // debugPrint('$pageRect');
              canvas.drawRect(bounds, marker.paint);
              // 保存矩形的四个点
              if (!marker.points.isEmpty) {
                break;
              }
              marker.points.addAll([
                // Point(bounds.left, bounds.top),
                // Point(bounds.right, bounds.bottom),
                Point(f.bounds.left, f.bounds.top),
                Point(f.bounds.right, f.bounds.bottom),
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
              // 防止大量重复添加
              if (!marker.points.isEmpty) {
                break;
              }
              // 保存下划线的起点和终点
              marker.points.addAll([
                // Point(rect.bottomLeft.dx, rect.bottomLeft.dy),
                // Point(rect.bottomRight.dx, rect.bottomRight.dy),
                Point(f.bounds.left, f.bounds.top),
                Point(f.bounds.right, f.bounds.bottom),
              ]);
            }
          }
          break;

        case MarkerType.strikethrough:
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
                rect.bottomLeft - Offset(0, rect.height / 2),
                rect.bottomRight - Offset(0, rect.height / 2),
                marker.paint,
              );
              // 防止大量重复添加
              if (!marker.points.isEmpty) {
                break;
              }

              marker.points.addAll([
                // Point(rect.left, rect.top),
                // Point(rect.right, rect.bottom),
                Point(f.bounds.left, f.bounds.top),
                Point(f.bounds.right, f.bounds.bottom),
              ]);
            }
          }
          break;
      }
    }
  }
}
