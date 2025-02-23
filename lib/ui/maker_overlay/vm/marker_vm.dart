import 'dart:math';
import 'package:flowverse/data/repositories/archive/archive_repository.dart';
import 'package:flowverse/domain/models/action/action.dart';
import 'package:flowverse/domain/models/annotation/strikethrough.dart';
import 'package:flowverse/domain/models/annotation/text_highlighter.dart';
import 'package:flowverse/domain/models/annotation/underline.dart';
import 'package:flowverse/domain/models/archive/archive.dart';
import 'package:flowverse/domain/models/action/draw_action.dart';
// import 'package:flowverse/domain/models/stroke.dart';
import 'package:flowverse/config/type.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:convert';
import 'dart:io';

class MarkerViewModel extends ChangeNotifier {
  MarkerViewModel({required ArchiveRepository archiveRepository})
      : _archiveRepository = archiveRepository;
  final ArchiveRepository _archiveRepository;

  late Archive archive;

  Underline _underline = Underline();
  Strikethrough _strikethrough = Strikethrough();
  TextHighlighter _highlight = TextHighlighter();
  // 撤销和重做栈
  Action action = Action();

  List<PdfTextRanges> selectedRanges = [];

  Color get strikethroughColor => _strikethrough.color;
  Color get underlineColor => _underline.color;
  Color get highlightColor => _highlight.color;

  // 添加下划线样式属性
  UnderlineStyle get underlineStyle => _underline.style;
  double get underlineWidth => _underline.width;
  double get strikethroughWidth => _strikethrough.width;

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
    _underline.style = style;
    notifyListeners();
  }

  // 设置粗细的方法
  void setUnderlineWidth(double width) {
    _underline.width = width;
    notifyListeners();
  }

  void setStrikethroughWidth(double width) {
    _strikethrough.width = width;
    notifyListeners();
  }

  // 绘制下划线的方法
  void drawUnderline(Canvas canvas, Offset start, Offset end, Marker marker) {
    final tool = marker.tool as UnderlineMarkerTool;
    final path = tool.getUnderlinePath(start, end);
    canvas.drawPath(path, marker.paint);
  }

  // 添加新的状态标志
  bool isHighlightMode = false;
  bool isUnderlineMode = false;
  var currentMarkerType = MarkerType.highlight;

  // 检查是否可以撤销
  bool get canUndo => action.undoStack.isNotEmpty;

  // 检查是否可以重做
  bool get canRedo => action.redoStack.isNotEmpty;

  void addStroke(Stroke stroke, int pageNumber) {
    print('MarkerViewModel - addStroke: 开始添加笔画');
    print('MarkerViewModel - addStroke: 目标页码 = $pageNumber');
    print('MarkerViewModel - addStroke: 笔画页码 = ${stroke.pageNumber}');
    print('MarkerViewModel - addStroke: 笔画点数 = ${stroke.points.length}');
    
    // 确保页面笔画列表存在
    if (!archive.strokes.containsKey(pageNumber)) {
      print('MarkerViewModel - addStroke: 为页码 $pageNumber 创建新的笔画列表');
      archive.strokes[pageNumber] = [];
    }
    
    try {
      archive.strokes[pageNumber]!.add(stroke);
      print('MarkerViewModel - addStroke: 笔画添加成功');
      print('MarkerViewModel - addStroke: 当前页面笔画总数: ${archive.strokes[pageNumber]?.length}');
    } catch (e, stackTrace) {
      print('MarkerViewModel - addStroke: 添加笔画时出错: $e');
      print('Stack trace: $stackTrace');
    }

    // 记录添加操作
    action.undoStack.add(DrawAction(
      actionType: DrawActionType.addStroke,
      pageNumber: pageNumber,
      stroke: stroke,
    ));
    action.redoStack.clear();

    notifyListeners();
  }

  void removeStroke(int pageNumber, Stroke stroke) {
    if (archive.strokes[pageNumber]?.contains(stroke) ?? false) {
      archive.strokes[pageNumber]?.remove(stroke);

      // 记录删除操作
      action.undoStack.add(DrawAction(
        actionType: DrawActionType.removeStroke,
        pageNumber: pageNumber,
        stroke: stroke,
      ));
      action.redoStack.clear();

      // 如果页面的笔画列表为空，删除该页面的记录
      if (archive.strokes[pageNumber]?.isEmpty ?? false) {
        archive.strokes.remove(pageNumber);
      }

      notifyListeners();
    }
  }

  void addMarker(Marker marker) {
    if (!archive.markers.containsKey(marker.pageNumber)) {
      archive.markers[marker.pageNumber] = [];
    }
    archive.markers[marker.pageNumber]!.add(marker);
    action.undoStack.add(DrawAction(
      actionType: DrawActionType.addMarker,
      pageNumber: marker.pageNumber,
      marker: marker,
    ));
    action.redoStack.clear();
    notifyListeners();
  }

  void removeMarker(int pageNumber, Marker marker) {
    if (archive.markers[pageNumber]?.contains(marker) ?? false) {
      archive.markers[pageNumber]?.remove(marker);

      // 记录删除操作
      action.undoStack.add(DrawAction(
        actionType: DrawActionType.removeMarker,
        pageNumber: pageNumber,
        marker: marker,
      ));
      action.redoStack.clear();

      // 如果页面的标注列表为空，删除该页面的记录
      if (archive.markers[pageNumber]?.isEmpty ?? false) {
        archive.markers.remove(pageNumber);
      }

      notifyListeners();
    }
  }

  void undo() {
    action.undo(archive);
    notifyListeners();
  }

  void redo() {
    action.redo(archive);
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
            ..color = _highlight.color.withAlpha(100)
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
            ..color = _underline.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = _underline.width;

          Marker marker = Marker(
            DateTime.now(),
            paint,
            [],
            range.pageText.pageNumber,
            UnderlineMarkerTool(style: _underline.style),
            ranges: range,
          );
          addMarker(marker);
        }
        break;
      case MarkerType.strikethrough:
        for (var range in ranges) {
          Paint paint = Paint()
            ..color = _strikethrough.color
            ..strokeWidth = _strikethrough.width
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
  }

  // 获取指定页面的所有标注
  List<Marker>? getMarkersForPage(int pageNumber) {
    return archive.markers[pageNumber];
  }

  // 保存归档到文件
  Future<void> saveArchive(String pdfPath) async {
    _archiveRepository.saveArchive(pdfPath, archive);
  }

  Future<void> loadArchive(String pdfPath) async {
    archive = await _archiveRepository.loadArchive(pdfPath);
    notifyListeners();
  }

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
    final lmarkers = archive.markers[page.pageNumber];
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
  // void _drawWavyLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  //   final path = Path();
  //   final width = end.dx - start.dx;
  //   const waveHeight = 2.0; // 波浪高度
  //   const frequency = 10.0; // 波浪频率

  //   path.moveTo(start.dx, start.dy);

  //   for (double i = 0; i <= width; i += 1) {
  //     final y = start.dy + sin(i / frequency * pi) * waveHeight;
  //     path.lineTo(start.dx + i, y);
  //   }

  //   canvas.drawPath(path, paint);
  // }

  void setMarkupWidth(MarkerType markerType, double value) {
    switch (markerType) {
      case MarkerType.highlight:
        // _highlightWidth = value;
        break;
      case MarkerType.underline:
        _underline.width = value;
        break;
      case MarkerType.strikethrough:
        _strikethrough.width = value;
        break;
    }
  }

  void setMarkupColor(MarkerType markerType, Color color) {
    switch (markerType) {
      case MarkerType.highlight:
        _highlight.color = color;
        break;
      case MarkerType.underline:
        _underline.color = color;
        break;
      case MarkerType.strikethrough:
        _strikethrough.color = color;
        break;
    }

    notifyListeners();
  }

  getMarkupColor(MarkerType markerType) {
    switch (markerType) {
      case MarkerType.highlight:
        return _highlight.color;
      case MarkerType.underline:
        return _underline.color;
      case MarkerType.strikethrough:
        return _strikethrough.color;
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
