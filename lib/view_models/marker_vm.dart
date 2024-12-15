import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

typedef PageNumber = int;

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class MarkerVewModel extends ChangeNotifier {
  // ReaderMarkerViewModel(this.readerViewModel);
  List<PdfTextRanges> selectedRanges = [];
  final Map<PageNumber, List<Marker>> _markers = {};
  final Map<PageNumber, List<Marker>> _underlinemarkers = {};

  // 新增：处理高亮按钮点击
  void applyHighlight() {
    if (kDebugMode) {
      // debugPrint('applyHighlight: $selectedRanges');
      // debugPrint('currentPage: $selectedRanges!.pageText.pageNumber');
      // debugPrint('currentPageText: ${selectedRanges!.pageText}');
    }

    for (var i = 0; i < selectedRanges!.length; i++) {
      if (selectedRanges.isNotEmpty) {
        // 定义标记颜色
        Color markerColor = CupertinoColors.systemYellow;
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
        ..strokeWidth = 2;

      for (final range in marker.ranges.ranges) {
        final f = PdfTextRangeWithFragments.fromTextRange(
          marker.ranges.pageText,
          range.start,
          range.end,
        );
        if (f != null) {
          // canvas.drawRect(
          //   f.bounds.toRectInPageRect(page: page, pageRect: pageRect),
          //   paint,
          // );
          canvas.drawLine(
              f.bounds
                  .toRectInPageRect(page: page, pageRect: pageRect)
                  .bottomLeft,
              f.bounds
                  .toRectInPageRect(page: page, pageRect: pageRect)
                  .bottomRight,
              paint);
        }
      }
    }
  }

  void applyUnderline() {
    for (var i = 0; i < selectedRanges!.length; i++) {
      if (selectedRanges.isNotEmpty) {
        // 定义标记颜色
        Color markerColor = CupertinoColors.systemYellow;
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
