import 'dart:math';
import 'package:flowverse/models/archive.dart';
import 'package:flowverse/models/draw_action.dart';
import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/type.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:convert';
import 'dart:io';

class MarkerViewModel extends ChangeNotifier {
  MarkerViewModel();

  // PainterController? painterController = PainterController();

  Map<PageNumber, List<Stroke>> strokes = {};
  Map<PageNumber, List<Marker>> markers = {};
  List<PdfTextRanges> selectedRanges = [];

  Color _underlineColor = Colors.blue;
  Color _highlightColor = Colors.yellow;
  Color _strikethroughColor = Colors.red;

  Color get strikethroughColor => _strikethroughColor;
  Color get underlineColor => _underlineColor;
  Color get highlightColor => _highlightColor;

  // 添加下划线样式属性
  UnderlineStyle _underlineStyle = UnderlineStyle.solid;
  UnderlineStyle get underlineStyle => _underlineStyle;

  // 添加粗细属性
  double _underlineWidth = 0.8;
  double _strikethroughWidth = 0.8;

  double get underlineWidth => _underlineWidth;
  double get strikethroughWidth => _strikethroughWidth;

  double getMarkupWidth(MarkerType type) {
    switch (type) {
      case MarkerType.underline:
        return underlineWidth;
      case MarkerType.strikethrough:
        return strikethroughWidth;
      default:
        return 0;
    }
  }

  // 设置下划线样式的方法
  void setUnderlineStyle(UnderlineStyle style) {
    _underlineStyle = style;
    notifyListeners();
  }

  // 设置粗细的方法
  void setUnderlineWidth(double width) {
    _underlineWidth = width;
    notifyListeners();
  }

  void setStrikethroughWidth(double width) {
    _strikethroughWidth = width;
    notifyListeners();
  }

  // 根据样式获取下划线路径的方法
  Path getUnderlinePath(Offset start, Offset end, UnderlineMarkerTool tool) {
    final path = Path();

    switch (tool.style) {
      case UnderlineStyle.solid:
        path.moveTo(start.dx, start.dy);
        path.lineTo(end.dx, end.dy);
        break;

      case UnderlineStyle.dashed:
        final dashWidth = 5.0;
        final dashSpace = 5.0;
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
        final dotSpace = 4.0;
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
        final waveWidth = 3.0;
        final waveHeight = 2.0;
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

  // 绘制下划线的方法
  void drawUnderline(Canvas canvas, Offset start, Offset end, Marker marker) {
    final tool = marker.tool as UnderlineMarkerTool;
    final path = getUnderlinePath(start, end, tool);
    canvas.drawPath(path, marker.paint);
  }

  // 添加新的状态标志
  bool isHighlightMode = false;
  bool isUnderlineMode = false;
  var currentMarkerType = MarkerType.highlight;

  // 添加波浪线控制变量
  // bool isWavyUnderline = false;

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
            ..color = _highlightColor.withAlpha(100)
            ..style = PaintingStyle.fill;

          Marker marker = Marker(
            DateTime.now(),
            // _highlightColor,
            paint,
            [],
            range.pageText.pageNumber,
            // strokeWidth: 0.8,
            HighlightMarkerTool(),
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
            ..color = _underlineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = _underlineWidth;

          Marker marker = Marker(
            DateTime.now(),
            paint,
            [],
            range.pageText.pageNumber,
            UnderlineMarkerTool(style: _underlineStyle),
            ranges: range,
          );
          addMarker(marker);
        }
        break;
      case MarkerType.strikethrough:
        for (var range in ranges) {
          Paint paint = Paint()
            ..color = strikethroughColor
            ..strokeWidth = _strikethroughWidth
            ..style = PaintingStyle.fill;

          Marker marker = Marker(
            DateTime.now(),
            paint,
            [],
            range.pageText.pageNumber,
            StrikethroughMarkerTool(),
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
        print(
            '${DateTime.now()} DEBUG: Processing marker with ${marker.points.length} points');
        final paint = marker.paint;
        final rect = PdfRect(
                marker.points[0].x as double,
                marker.points[0].y as double,
                marker.points[1].x as double,
                marker.points[1].y as double)
            .toRectInPageRect(page: page, pageRect: pageRect);
        switch (marker.tool.type) {
          case MarkerType.highlight:
            canvas.drawRect(rect, paint);
            break;
          case MarkerType.underline:
            final underlineMarkerTool = marker.tool as UnderlineMarkerTool;
            drawUnderline(canvas, Offset(rect.left, rect.bottom),
                Offset(rect.right, rect.bottom), marker);
            break;
          case MarkerType.strikethrough:
            canvas.drawLine(Offset(rect.left, (rect.bottom + rect.top) / 2),
                Offset(rect.right, (rect.bottom + rect.top) / 2), paint);
            break;
          // case MarkerType.wavyUnderline:
          //   _drawWavyLine(
          //     canvas,
          //     Offset(rect.left, rect.bottom),
          //     Offset(rect.right, rect.bottom),
          //     paint,
          //   );
          //   break;
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

            switch (marker.tool.type) {
              case MarkerType.highlight:
                canvas.drawRect(rect, marker.paint);
                break;

              case MarkerType.underline:
                final underlineMarkerTool = marker.tool as UnderlineMarkerTool;
                drawUnderline(canvas, Offset(rect.left, rect.bottom),
                    Offset(rect.right, rect.bottom), marker);
                break;

              case MarkerType.strikethrough:
                canvas.drawLine(
                  rect.bottomLeft - Offset(0, rect.height / 2),
                  rect.bottomRight - Offset(0, rect.height / 2),
                  marker.paint,
                );
                break;

              // case MarkerType.wavyUnderline:
              //   _drawWavyLine(
              //     canvas,
              //     Offset(rect.left, rect.bottom),
              //     Offset(rect.right, rect.bottom),
              //     marker.paint,
              //   );
              //   break;
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

  // 添加绘制波浪线的辅助方法
  void _drawWavyLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    final width = end.dx - start.dx;
    const waveHeight = 2.0; // 波浪高度
    const frequency = 10.0; // 波浪频率

    path.moveTo(start.dx, start.dy);

    for (double i = 0; i <= width; i += 1) {
      final y = start.dy + sin(i / frequency * pi) * waveHeight;
      path.lineTo(start.dx + i, y);
    }

    canvas.drawPath(path, paint);
  }

  void setMarkupWidth(MarkerType markerType, double value) {
    switch (markerType) {
      case MarkerType.highlight:
        // _highlightWidth = value;
        break;
      case MarkerType.underline:
        _underlineWidth = value;
        break;
      case MarkerType.strikethrough:
        _strikethroughWidth = value;
        break;
    }
  }

  void setMarkupColor(MarkerType markerType, Color color) {
    switch (markerType) {
      case MarkerType.highlight:
        _highlightColor = color;
        break;
      case MarkerType.underline:
        _underlineColor = color;
        break;
      case MarkerType.strikethrough:
        _strikethroughColor = color;
        break;
    }

    notifyListeners();
  }

  getMarkupColor(MarkerType markerType) {
    switch (markerType) {
      case MarkerType.highlight:
        return _highlightColor;
      case MarkerType.underline:
        return _underlineColor;
      case MarkerType.strikethrough:
        return strikethroughColor;
    }
  }

  IconData? getMarkupIcon(MarkerType markerType) {
    switch (markerType) {
      case MarkerType.highlight:
        return PhosphorIconsLight.textH;
      case MarkerType.underline:
        return PhosphorIconsLight.textUnderline;
      case MarkerType.strikethrough:
        return PhosphorIconsLight.textStrikethrough;
    }
  }
}
