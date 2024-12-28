import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

typedef PageNumber = int;

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class MarkerVewModel extends ChangeNotifier {
  // ReaderMarkerViewModel(this.readerViewModel);
  // List<PdfTextRanges> selectedRanges = [];
  final Map<PageNumber, List<Marker>> _markers = {};
  final Map<PageNumber, List<Marker>> _underlinemarkers = {};

  var underline_color = Colors.yellow;
  var highlight_color = Colors.yellow;

  // 添加新的状态标志
  bool isHighlightMode = false;

  // 添加下划线模式标志
  bool isUnderlineMode = false;

  // 修改 selectedRanges 的 setter
  set selectedRanges(List<PdfTextRanges> ranges) {
    _selectedRanges = ranges;
    
    // 实时应用效果
    if (isHighlightMode && ranges.isNotEmpty) {
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
    
    notifyListeners();
  }

  List<PdfTextRanges> get selectedRanges => _selectedRanges;
  List<PdfTextRanges> _selectedRanges = [];

  // 新增：处理高亮按钮点击
  void applyHighlight() {
    if (kDebugMode) {
      // debugPrint('applyHighlight: $selectedRanges');
      // debugPrint('currentPage: $selectedRanges!.pageText.pageNumber');
      // debugPrint('currentPageText: ${selectedRanges!.pageText}');
    }

    print(selectedRanges!.length);
    for (var i = 0; i < selectedRanges!.length; i++) {
      if (selectedRanges.isNotEmpty) {
        // 定义标记颜色
        Color markerColor = highlight_color;
        // 获取当前页面
        int currentPage = selectedRanges![i].pageText.pageNumber;
        // 创建标记
        Marker marker = Marker(markerColor, selectedRanges![i]);
        // 添加标记
        addMarker(currentPage, marker);
        // 隐藏按钮
        selectedRanges = [];
      }
    }

    notifyListeners();
  }

// 新增：添加标记
  void addMarker(PageNumber pageNumber, Marker marker) {
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.add(marker);
    } else {
      _markers[pageNumber] = [marker];
    }
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
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.remove(marker);
      if (_markers[pageNumber]!.isEmpty) {
        _markers.remove(pageNumber);
      }
      // notifyListeners();
    }
  }

  void paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
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
          canvas.drawRect(
            f.bounds.toRectInPageRect(page: page, pageRect: pageRect),
            paint,
          );
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
          final rect = f.bounds.toRectInPageRect(page: page, pageRect: pageRect);
          canvas.drawLine(
            rect.bottomLeft,
            rect.bottomRight,
            paint,
          );
        }
      }
    }
  }

  void applyUnderline() {
    for (var i = 0; i < selectedRanges!.length; i++) {
      if (selectedRanges.isNotEmpty) {
        // 定义标记颜色
        Color markerColor = underline_color;
        // 获取当前页面
        int currentPage = selectedRanges![i].pageText.pageNumber;
        // 创建标记
        Marker marker = Marker(markerColor, selectedRanges![i]);
        // 添加标记
        addUnderlineMarker(currentPage, marker);
        // 隐藏按钮
        selectedRanges = [];
      }
    }

    notifyListeners();
  }
}
