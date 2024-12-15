import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import 'package:synchronized/extension.dart';

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}


class ReaderViewModel extends ChangeNotifier {
  final PdfViewerController pdfViewerController = PdfViewerController();

  bool darkMode = false;

  var currentPage = 0;
  bool isOutlineVisible = false;
  File? selectedFile;
  List<PdfOutlineNode>? outline;

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];

  final ScrollController scrollController = ScrollController();

  var textSelections = [];

  final Map<int, List<Marker>> _markers = {};

  bool _isHighlightButtonVisible = false;
  PdfTextRanges? _currentSelection;

  late final textSearcher = PdfTextSearcher(pdfViewerController)
    ..addListener(_update);

  void _update() {
    notifyListeners();
  }

  List<Marker> get markers => _markers.values.expand((e) => e).toList();

  bool get isHighlightButtonVisible => _isHighlightButtonVisible;

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }
  void addMarker(int pageNumber, Marker marker) {
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.add(marker);
    } else {
      _markers[pageNumber] = [marker];
    }
    notifyListeners();
  }

  void removeMarker(int pageNumber, Marker marker) {
    if (_markers.containsKey(pageNumber)) {
      _markers[pageNumber]!.remove(marker);
      if (_markers[pageNumber]!.isEmpty) {
        _markers.remove(pageNumber);
      }
      notifyListeners();
    }
  }

  void toggleOutline() {
    isOutlineVisible = !isOutlineVisible;

    if (!isOutlineVisible) {
      _isSearching = false;
    }

    print('toggleOutline: $isOutlineVisible');
    print('outline: $outline');
    notifyListeners();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      selectedFile = File(result.files.single.path!);
      notifyListeners();
    }
  }

  Future<void> _loadOutline() async {
    if (selectedFile != null) {
      try {
        final document = await PdfDocument.openFile(selectedFile!.path);
        outline = await document.loadOutline();
        // outline = outline;
        await document.dispose();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('加载大纲时出错: $e');
        }
      }
    }
  }

  Future<void> savePdf(BuildContext context) async {
    if (selectedFile == null) return;

    try {
      // final customDirectory = Directory('/home/z/Dev');
      // if (!await customDirectory.exists()) {
      //   await customDirectory.create(recursive: true);
      // }
      // final filePath = '${customDirectory.path}/saved_pdf.pdf';
      const filePath = 'saved_pdf.pdf';

      final file = File(filePath);
      await selectedFile!.copy(file.path);

      // Start of Selection
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            content: Text('PDF 已保存到此软件运行目录: $filePath'),
            actions: [
              CupertinoDialogAction(
                child: Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            content: Text('保存失败: $e'),
            actions: [
              CupertinoDialogAction(
                child: Text('确定'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void toggleSearch(String query) {
    _isSearching = query.isNotEmpty;
    _searchQuery = query;
    if (_isSearching) {
      _performSearch(query);
    } else {
      _searchResults.clear();
    }
    notifyListeners();
  }

  void _performSearch(String query) {
    // 这里需要根据实际的 PdfViewerController 提供的搜索功能来实现
    // 假设 pdfViewerController 有一个 search 方法返回符合条件的页面列表
    // _searchResults = pdfViewerController.search(query);
    textSearcher.startTextSearch(query, caseInsensitive: true);
  }

  List<int> get searchResults => _searchResults;

  bool get isSearching => _isSearching;

  void zoomUp() {
    pdfViewerController.zoomUp();
    notifyListeners();
  }

  void zoomDown() {
    pdfViewerController.zoomDown();
    notifyListeners();
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

  // 修改：处理文本选择并显示高亮按钮
  // void handleTextSelection(
  //     PdfTextRanges selectedRanges, Offset selectionOffset) {
  //   if (selectedRanges.ranges.isNotEmpty) {
  //     _currentSelection = selectedRanges;
  //     _highlightButtonOffset = selectionOffset;
  //     _isHighlightButtonVisible = true;
  //     notifyListeners();
  //   } else {
  //     _isHighlightButtonVisible = false;
  //     _currentSelection = null;
  //     notifyListeners();
  //   }
  // }

  // 新增：处理高亮按钮点击
  void applyHighlight() {
    if (kDebugMode) {
      debugPrint('applyHighlight: $_currentSelection');
      debugPrint('currentPage: $_currentSelection!.pageText.pageNumber');
      debugPrint('currentPageText: ${_currentSelection!.pageText}');
    }
    if (_currentSelection != null) {
      // 定义标记颜色
      Color markerColor = CupertinoColors.systemYellow;
      // 获取当前页面
      int currentPage = _currentSelection!.pageText.pageNumber;
      // 创建标记
      Marker marker = Marker(markerColor, _currentSelection!);
      // 添加标记
      addMarker(currentPage, marker);
      // 隐藏按钮
      _isHighlightButtonVisible = false;
      _currentSelection = null;
      notifyListeners();
    }
  }

  Future<void> setSelectedFile(File file) async {
    selectedFile = file;
    notifyListeners();
    await _loadOutline();
  }

  @override
  void dispose() {
    scrollController.dispose();
    // pdfViewerController.dispose();
    super.dispose();
  }

  /// 更新文本选择并控制高亮按钮的显示
  void updateTextSelections(PdfTextRanges selections) {
    if (selections.ranges.isNotEmpty) {
      _currentSelection = selections;
      _isHighlightButtonVisible = true;
    } else {
      _currentSelection = null;
      _isHighlightButtonVisible = false;
    }
    notifyListeners();
  }
}
