import 'package:file_picker/file_picker.dart';
import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import 'package:synchronized/extension.dart';

import 'dict_vm.dart';

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class ReaderViewModel extends ChangeNotifier {
  final PdfViewerController pdfViewerController = PdfViewerController();

  bool darkMode = false;

  int index = -1;
  int rindex = -1;

  var currentPage = 0;
  // bool isOutlineVisible = false;
  bool isSidebarVisible = false;
  File? selectedFile;
  List<PdfOutlineNode>? outline;

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];

  final ScrollController scrollController = ScrollController();

  final MarkerVewModel markerVm = MarkerVewModel();
  final DictViewModel dictVm = DictViewModel();

  

  

  late final textSearcher = PdfTextSearcher(pdfViewerController)
    ..addListener(_update);

  var isLeftSidebarVisible = false;

  void _update() {
    notifyListeners();
  }


  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  // void addMarker(int pageNumber, Marker marker) {
  //   if (_markers.containsKey(pageNumber)) {
  //     _markers[pageNumber]!.add(marker);
  //   } else {
  //     _markers[pageNumber] = [marker];
  //   }
  //   notifyListeners();
  // }

  // void removeMarker(int pageNumber, Marker marker) {
  //   if (_markers.containsKey(pageNumber)) {
  //     _markers[pageNumber]!.remove(marker);
  //     if (_markers[pageNumber]!.isEmpty) {
  //       _markers.remove(pageNumber);
  //     }
  //     notifyListeners();
  //   }
  // }

  void toggleOutline(int index) {
    if (this.index == index) {
      isSidebarVisible = !isSidebarVisible;
    }else {
      isSidebarVisible = true;
      this.index = index;
    }

    print('toggleOutline: $isSidebarVisible');
    // print('outline: $outline');
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
    // print(pdfViewerController.currentZoom);
    notifyListeners();
  }

  void zoomDown() {
    pdfViewerController.zoomDown();
    notifyListeners();
  }


  // 修改：处理文本选择并显示高亮按钮
  // void handleTextSelection(
  //     PdfTextRanges selectedRanges, Offset selectionOffset) {
  //   if (selectedRanges.ranges.isNotEmpty) {
  //     currentSelection = selectedRanges;
  //     _highlightButtonOffset = selectionOffset;
  //     _isHighlightButtonVisible = true;
  //     notifyListeners();
  //   } else {
  //     _isHighlightButtonVisible = false;
  //     currentSelection = null;
  //     notifyListeners();
  //   }
  // }



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

  void goToPreviousPage() {
    int currentPage = pdfViewerController.pageNumber!;
    int previousPage = currentPage - 1;
    pdfViewerController.goToPage(pageNumber: previousPage);
    notifyListeners();
  }

  void goToNextPage() {
    int? currentPage = pdfViewerController.pageNumber;
    int nextPage = currentPage! + 1;
    pdfViewerController.goToPage(pageNumber: nextPage);
    notifyListeners();
  }

  void toggleROutline(int index) {
    print(index);
    if (rindex == index) {
      isLeftSidebarVisible = !isLeftSidebarVisible;
    }else {
      isLeftSidebarVisible = true;
      rindex = index;
    }

    notifyListeners();
  }

}

