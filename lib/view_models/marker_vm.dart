import 'dart:math';
import 'package:flowverse/models/archive.dart';
import 'package:flowverse/models/draw_action.dart';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:convert';
import 'dart:io';

import 'package:simple_painter/simple_painter.dart';

class MarkerVewModel extends ChangeNotifier {
  // final readerVm;

  MarkerVewModel();

  PainterController? painterController = PainterController();

  Map<PageNumber, List<Stroke>> strokes = {};
  Map<PageNumber, List<Marker>> markers = {};
  List<PdfTextRanges> selectedRanges = [];

  // var selectionColor = Colors.yellow;
  var underlineColor = Colors.blue;
  var highlightColor = Colors.yellow;
  // var strikethroughColor = Colors.red;

  MaterialColor _strikethroughColor = Colors.red;

  MaterialColor get strikethroughColor => _strikethroughColor;

  set strikethroughColor(MaterialColor color) {
    _strikethroughColor = color;
    notifyListeners();
  }

  // 添加新的状态标志
  bool isHighlightMode = false;
  bool isUnderlineMode = false;
  var currentMarkerType = MarkerType.highlight;

  // 撤销和重做栈
  final List<DrawAction> _undoStack = [];
  final List<DrawAction> _redoStack = [];

  // 检查是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  // 检查是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  void addStroke(Stroke stroke, int pageNumber) {
    if (!strokes.containsKey(pageNumber)) {
      strokes[pageNumber] = [];
    }
    strokes[pageNumber]!.add(stroke);

    // 记录添加操作
    _undoStack.add(DrawAction(
      actionType: DrawActionType.addStroke,
      pageNumber: pageNumber,
      stroke: stroke,
    ));
    _redoStack.clear();

    notifyListeners();
  }

  void removeStroke(int pageNumber, Stroke stroke) {
    if (strokes[pageNumber]?.contains(stroke) ?? false) {
      strokes[pageNumber]?.remove(stroke);

      // 记录删除操作
      _undoStack.add(DrawAction(
        actionType: DrawActionType.removeStroke,
        pageNumber: pageNumber,
        stroke: stroke,
      ));
      _redoStack.clear();

      // 如果页面的笔画列表为空，删除该页面的记录
      if (strokes[pageNumber]?.isEmpty ?? false) {
        strokes.remove(pageNumber);
      }

      notifyListeners();
    }
  }

  void addMarker(Marker marker) {
    if (!markers.containsKey(marker.pageNumber)) {
      markers[marker.pageNumber] = [];
    }
    markers[marker.pageNumber]!.add(marker);
    _undoStack.add(DrawAction(
      actionType: DrawActionType.addMarker,
      pageNumber: marker.pageNumber,
      marker: marker,
    ));
    _redoStack.clear();
    notifyListeners();
  }

  void removeMarker(int pageNumber, Marker marker) {
    if (markers[pageNumber]?.contains(marker) ?? false) {
      markers[pageNumber]?.remove(marker);

      // 记录删除操作
      _undoStack.add(DrawAction(
        actionType: DrawActionType.removeMarker,
        pageNumber: pageNumber,
        marker: marker,
      ));
      _redoStack.clear();

      // 如果页面的标注列表为空，删除该页面的记录
      if (markers[pageNumber]?.isEmpty ?? false) {
        markers.remove(pageNumber);
      }

      notifyListeners();
    }
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    switch (action.actionType) {
      case DrawActionType.addStroke:
        // 撤销添加操作，需要删除笔画
        if (action.stroke != null) {
          strokes[action.pageNumber]?.remove(action.stroke);
          if (strokes[action.pageNumber]?.isEmpty ?? false) {
            strokes.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.removeStroke:
        // 撤销删除操作，需要添加笔画
        if (action.stroke != null) {
          if (!strokes.containsKey(action.pageNumber)) {
            strokes[action.pageNumber] = [];
          }
          strokes[action.pageNumber]!.add(action.stroke!);
        }
        break;
      case DrawActionType.addMarker:
        // 撤销添加标记操作，需要删除标记
        if (action.marker != null) {
          markers[action.pageNumber]?.remove(action.marker);
          if (markers[action.pageNumber]?.isEmpty ?? false) {
            markers.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.removeMarker:
        // 撤销删除标记操作，需要添加标记
        if (action.marker != null) {
          if (!markers.containsKey(action.pageNumber)) {
            markers[action.pageNumber] = [];
          }
          markers[action.pageNumber]!.add(action.marker!);
        }
        break;
    }

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    switch (action.actionType) {
      case DrawActionType.addStroke:
        // 重做添加操作，需要添加笔画
        if (action.stroke != null) {
          if (!strokes.containsKey(action.pageNumber)) {
            strokes[action.pageNumber] = [];
          }
          strokes[action.pageNumber]!.add(action.stroke!);
        }
        break;
      case DrawActionType.removeStroke:
        // 重做删除操作，需要删除笔画
        if (action.stroke != null) {
          strokes[action.pageNumber]?.remove(action.stroke);
          if (strokes[action.pageNumber]?.isEmpty ?? false) {
            strokes.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.addMarker:
        // 重做添加标记操作，需要添加标记
        if (action.marker != null) {
          if (!markers.containsKey(action.pageNumber)) {
            markers[action.pageNumber] = [];
          }
          markers[action.pageNumber]!.add(action.marker!);
        }
        break;
      case DrawActionType.removeMarker:
        // 重做删除标记操作，需要删除标记
        if (action.marker != null) {
          markers[action.pageNumber]?.remove(action.marker);
          if (markers[action.pageNumber]?.isEmpty ?? false) {
            markers.remove(action.pageNumber);
          }
        }
        break;
    }

    notifyListeners();
  }

  void applyMark(currentMarkerType) {
    var ranges = selectedRanges;

    if (ranges.isEmpty) {
      return;
    }
    // currentMarkerType = MarkerType.highlight;
    //
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
      case MarkerType.strikethrough:
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
        break;
    }

    notifyListeners();
    // readerVm.notifyListeners();
  }

  // 获取指定页面的所有标注
  List<Marker>? getMarkersForPage(int pageNumber) {
    return markers[pageNumber];
  }

  // 保存归档到文件
  Future<void> saveArchive(String pdfPath) async {
    final savePath = '${pdfPath}_archive.json';
    final archive = Archive(
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
    );
    archive.markers = Map.from(markers);
    archive.strokes = Map.from(strokes);

    final archiveJson = jsonEncode(archive.toJson());
    await File(savePath).writeAsString(archiveJson);
  }

  Future<void> loadArchive(String pdfPath) async {
    final savePath = '${pdfPath}_archive.json';
    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final archive = Archive.fromJson(json);

      markers = Map.from(archive.markers);
      strokes = Map.from(archive.strokes);

      notifyListeners();
      // readerVm.notifyListeners();
    }
  }

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final lmarkers = markers[page.pageNumber];
    if (lmarkers == null) return;

    for (final marker in lmarkers) {
      // 过滤保存的
      if (marker.ranges == null) {
        print('DEBUG: Processing marker with ${marker.points.length} points');
        final paint = marker.paint;
        final rect = PdfRect(
                marker.points[0].x as double,
                marker.points[0].y as double,
                marker.points[1].x as double,
                marker.points[1].y as double)
            .toRectInPageRect(page: page, pageRect: pageRect);
        switch (marker.type) {
          case MarkerType.highlight:
            canvas.drawRect(rect, paint);
            break;
          case MarkerType.underline:
            canvas.drawLine(Offset(rect.left, rect.bottom),
                Offset(rect.right, rect.bottom), paint);
            break;
          case MarkerType.strikethrough:
            canvas.drawLine(Offset(rect.left, (rect.bottom + rect.top) / 2),
                Offset(rect.right, (rect.bottom + rect.top) / 2), paint);
            break;
        }
      } else {
        print(
            'DEBUG: Processing marker with ${marker.ranges!.ranges.length} ranges');
        for (final range in marker.ranges!.ranges) {
          print('DEBUG: Range start=${range.start}, end=${range.end}');
          // 添加范围验证
          // if (range.start >= range.end || range.start < 0) {
          //   print('DEBUG: Invalid range detected: start=${range.start}, end=${range.end}');
          //   continue;
          // }

          final f = PdfTextRangeWithFragments.fromTextRange(
            marker.ranges!.pageText,
            range.start,
            range.end,
          );
          if (f != null) {
            final rect =
                f.bounds.toRectInPageRect(page: page, pageRect: pageRect);

            switch (marker.type) {
              case MarkerType.highlight:
                canvas.drawRect(rect, marker.paint);
                break;

              case MarkerType.underline:
                canvas.drawLine(
                  rect.bottomLeft,
                  rect.bottomRight,
                  marker.paint,
                );
                break;

              case MarkerType.strikethrough:
                canvas.drawLine(
                  rect.bottomLeft - Offset(0, rect.height / 2),
                  rect.bottomRight - Offset(0, rect.height / 2),
                  marker.paint,
                );
                break;
            }
            // 保存矩形的四个点
            if (!marker.points.isEmpty) {
              break;
            }

            marker.points.addAll([
              Point(f.bounds.left, f.bounds.top),
              Point(f.bounds.right, f.bounds.bottom),
            ]);
          }
        }
      }
    }
  }
}
