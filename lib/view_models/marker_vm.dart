import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:convert';
import 'dart:io';

typedef PageNumber = int;

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class Stroke {
  final Color color;
  final double strokeWidth;
  final PdfTextRanges ranges;

  Stroke(this.color, this.ranges, {this.strokeWidth = 0.8});
}

class SavedHighlight {
  final Color color;
  final int pageNumber;
  final Rect bounds;  // 保存相对于页面的比例位置
  final double alpha;

  SavedHighlight({
    required this.color,
    required this.pageNumber,
    required this.bounds,
    this.alpha = 100,
  });

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'pageNumber': pageNumber,
      'bounds': {
        'left': bounds.left,
        'top': bounds.top,
        'right': bounds.right,
        'bottom': bounds.bottom,
      },
      'alpha': alpha,
    };
  }

  // 从JSON恢复
  factory SavedHighlight.fromJson(Map<String, dynamic> json) {
    return SavedHighlight(
      color: Color(json['color']),
      pageNumber: json['pageNumber'],
      bounds: Rect.fromLTRB(
        json['bounds']['left'],
        json['bounds']['top'],
        json['bounds']['right'],
        json['bounds']['bottom'],
      ),
      alpha: json['alpha'],
    );
  }
}

class MarkerVewModel extends ChangeNotifier {
  final readerVm;

  MarkerVewModel(this.readerVm);
  // ReaderMarkerViewModel(this.readerViewModel);
  // List<PdfTextRanges> selectedRanges = [];
  final Map<PageNumber, List<Marker>> _markers = {};
  final Map<PageNumber, List<Marker>> _underlinemarkers = {};

  var selectionColor = Colors.yellow;

  var underline_color = Colors.yellow;
  var highlight_color = Colors.yellow;

  // 添加新的状态标志
  bool isHighlightMode = false;

  // 添加下划线模式标志
  bool isUnderlineMode = false;

  // 撤销和重做栈
  final List<Map<PageNumber, List<Marker>>> _undoStack = [];
  final List<Map<PageNumber, List<Marker>>> _redoStack = [];

  // 保存的高亮列表
  final List<SavedHighlight> _savedHighlights = [];

  // 修改 selectedRanges 的 setter
  set selectedRanges(List<PdfTextRanges> ranges) {
    _selectedRanges = ranges;

    // 实时应用效果
    if (isHighlightMode && ranges.isNotEmpty) {
      // selectionColor = highlight_color;
      // readerVm.notifyListeners();
      // 如果在高亮模式下且有选择文本，直接应用高亮
      for (var range in ranges) {
        int currentPage = range.pageText.pageNumber;
        Marker marker = Marker(highlight_color, range);
        addMarker(currentPage, marker);
      }
    } else if (isUnderlineMode && ranges.isNotEmpty) {
      // 如果在下划线模式下且有选择文本，直接应用下划线
      for (var range in ranges) {
        int currentPage = range.pageText.pageNumber;
        Marker marker = Marker(underline_color, range);
        addUnderlineMarker(currentPage, marker);
      }
    }

    // notifyListeners();
  }

  List<PdfTextRanges> get selectedRanges => _selectedRanges;
  List<PdfTextRanges> _selectedRanges = [];

// 新增：添加标记
  void addMarker(PageNumber pageNumber, Marker marker) {
    _undoStack.add(Map.from(_markers));
    _redoStack.clear();
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.add(marker);
    } else {
      _markers[pageNumber] = [marker];
    }
    // notifyListeners();
  }

  void addUnderlineMarker(PageNumber pageNumber, Marker marker) {
    if (_underlinemarkers.containsKey(pageNumber)) {
      _underlinemarkers[pageNumber]!.add(marker);
    } else {
      _underlinemarkers[pageNumber] = [marker];
    }
  }

  // 新增：移除标记
  void removeMarker(PageNumber pageNumber, Marker marker) {
    _undoStack.add(Map.from(_markers));
    _redoStack.clear();
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.remove(marker);
      if (_markers[pageNumber]!.isEmpty) {
        _markers.remove(pageNumber);
      }
      // notifyListeners();
    }
  }

  // 添加撤销功能
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(Map.from(_markers));
      _markers.clear();
      _markers.addAll(_undoStack.removeLast());
      // notifyListeners();
      readerVm.notifyListeners();
    }
  }

  // 添加重做功能
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(Map.from(_markers));
      _markers.clear();
      _markers.addAll(_redoStack.removeLast());
      // notifyListeners();
      readerVm.notifyListeners();
    }
  }

  // 保存高亮到文件
  Future<void> saveHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    final highlightsJson = _savedHighlights.map((h) => h.toJson()).toList();
    debugPrint(savePath);
    await File(savePath).writeAsString(jsonEncode(highlightsJson));
  }

  // 从文件加载高亮
  Future<void> loadHighlights(String pdfPath) async {
    final savePath = '${pdfPath}_highlights.json';
    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      final List<dynamic> highlightsJson = jsonDecode(content);
      _savedHighlights.clear();
      _savedHighlights.addAll(
        // ignore: unnecessary_cast
        highlightsJson.map((json) => SavedHighlight.fromJson(json)).toList(),
      );
      readerVm.notifyListeners();
    }
  }

  // 在绘制时保存高亮信息
  void _saveHighlight(PdfPage page,  Rect bounds, Color color) {
    // 转换为相对坐标
    // final relativeRect = Rect.fromLTRB(
    //   bounds.left / page.width,
    //   bounds.top / page.height,
    //   bounds.right / page.width,
    //   bounds.bottom / page.height,
    // );
    // _savedHighlights.add(SavedHighlight(
    //   color: color,
    //   pageNumber: page.pageNumber,
    //   bounds: relativeRect,
    // ));
    _savedHighlights.add(SavedHighlight(
      color: color,
      pageNumber: page.pageNumber,
      bounds: bounds,
    ));
  }

  //  highlightRect 传入的
  void paintMarkers(Canvas canvas, Rect highlightRect, PdfPage page) {
    final markers = _markers[page.pageNumber];
    if (markers == null) return;

    for (final marker in markers) {
      final paint = Paint()
        ..color = marker.color.withAlpha(100)
        ..style = PaintingStyle.fill;

      for (final range in marker.ranges.ranges) {
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );

        if (f != null) {
          final bounds = f.bounds.toRectInPageRect(page: page, pageRect: highlightRect);
          canvas.drawRect(bounds, paint);
          // 保存高亮信息
          _saveHighlight(page, bounds, marker.color);
        }
      }
    }
  }

  void paintUnderlines(Canvas canvas, Rect pageRect, PdfPage page) {
    final markers = _underlinemarkers[page.pageNumber];
    if (markers == null) return;

    for (final marker in markers) {
      final paint = Paint()
        ..color = marker.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;

      for (final range in marker.ranges.ranges) {
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );
        if (f != null) {
          final rect =
              f.bounds.toRectInPageRect(page: page, pageRect: pageRect);
          canvas.drawLine(
            rect.bottomLeft,
            rect.bottomRight,
            paint,
          );
        }
      }
    }
  }

  // 绘制保存的高亮
  void paintSavedHighlights(Canvas canvas, Rect pageRect, PdfPage page) {
    final highlights = _savedHighlights.where((h) => h.pageNumber == page.pageNumber);
    
    for (final highlight in highlights) {
      final paint = Paint()
        ..color = highlight.color.withAlpha(highlight.alpha.toInt())
        ..style = PaintingStyle.fill;

      // 从相对坐标转换为实际坐标
      // final actualRect = Rect.fromLTRB(
      //   highlight.bounds.left * page.width,
      //   highlight.bounds.top * page.height,
      //   highlight.bounds.right * page.width,
      //   highlight.bounds.bottom * page.height,
      // );

      // 转换为页面坐标系
      // final displayRect = Rect.fromLTRB(
      //   pageRect.left + (actualRect.left / page.width) * pageRect.width,
      //   pageRect.top + (actualRect.top / page.height) * pageRect.height,
      //   pageRect.left + (actualRect.right / page.width) * pageRect.width,
      //   pageRect.top + (actualRect.bottom / page.height) * pageRect.height,
      // );

      canvas.drawRect(highlight.bounds, paint);
    }
  }
}
