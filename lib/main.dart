// Start of Selectino
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';
import 'package:provider/provider.dart';
// import 'package:pdfrx/src/pdf_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: const CupertinoApp(
        theme: CupertinoThemeData(),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        home: MyHomePage(),
      ),
    );
  }
}

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class MyAppState extends ChangeNotifier {
  var currentPage = 0;
  bool _isOutlineVisible = false;
  File? _selectedFile;
  List<PdfOutlineNode>? _outline;

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];

  final ScrollController scrollController = ScrollController();
  final PdfViewerController pdfViewerController = PdfViewerController();

  final Map<int, List<Marker>> _markers = {};

  bool _isHighlightButtonVisible = false;
  Offset _highlightButtonOffset = Offset.zero;
  PdfTextRanges? _currentSelection;

  List<Marker> get markers => _markers.values.expand((e) => e).toList();

  bool get isHighlightButtonVisible => _isHighlightButtonVisible;
  Offset get highlightButtonOffset => _highlightButtonOffset;

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

  void _toggleOutline() {
    _isOutlineVisible = !_isOutlineVisible;
    notifyListeners();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      _selectedFile = File(result.files.single.path!);
      notifyListeners();
    }
  }

  Future<void> _loadOutline() async {
    if (_selectedFile != null) {
      final document = await PdfDocument.openFile(_selectedFile!.path);
      final outline = await document.loadOutline();
      _outline = outline;
      await document.dispose();
    }
  }

  Future<void> _savePdf(BuildContext context) async {
    if (_selectedFile == null) return;

    try {
      // final customDirectory = Directory('/home/z/Dev');
      // if (!await customDirectory.exists()) {
      //   await customDirectory.create(recursive: true);
      // }
      // final filePath = '${customDirectory.path}/saved_pdf.pdf';
      const filePath = 'saved_pdf.pdf';

      final file = File(filePath);
      await _selectedFile!.copy(file.path);

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

  void _paintMarkers(Canvas canvas, Rect pageRect, PdfPage page) {
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
  void handleTextSelection(
      PdfTextRanges selectedRanges, Offset selectionOffset) {
    if (selectedRanges.ranges.isNotEmpty) {
      _currentSelection = selectedRanges;
      _highlightButtonOffset = selectionOffset;
      _isHighlightButtonVisible = true;
      notifyListeners();
    } else {
      _isHighlightButtonVisible = false;
      _currentSelection = null;
      notifyListeners();
    }
  }

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

  @override
  void dispose() {
    scrollController.dispose();
    // pdfViewerController.dispose();
    super.dispose();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final controller = appState.pdfViewerController;

    if (kDebugMode) {
      debugPrint('Controller: ${controller}');
    }

    // 搜索框
    Widget buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: CupertinoSearchTextField(
          placeholder: '搜索 PDF 内容',
          onSubmitted: (value) {
            appState.toggleSearch(value);
          },
          onChanged: (value) {
            if (value.isEmpty) {
              appState.toggleSearch('');
            }
          },
        ),
      );
    }

    // 大纲列表

    Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.map((node) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (node.dest != null) {
                    if (kDebugMode) {
                      debugPrint('goToDest Controller: $controller');
                      debugPrint('Dest: ${node.dest?.pageNumber}');
                    }

                    controller.goToDest(node.dest);
                    // Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16 + indent,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  width: double.infinity,
                  child: Text(
                    node.title ?? '',
                    style: const TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (node.children.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 0),
                  child: buildOutlineList(node.children, indent: indent + 20),
                ),
            ],
          );
        }).toList(),
      );
    }

    Widget buildOutlineSection() {
      if (!appState._isOutlineVisible || appState._outline == null) {
        return Container();
      }
      return Container(
        width: 250,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildSearchBar(),
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  child: buildOutlineList(appState._outline!),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 添加放大和缩小按钮的方法
    Widget buildZoomButtons() {
      return Positioned(
        bottom: 20,
        right: 20,
        child: Opacity(
          opacity: 0.7, // 设置按钮透明度
          child: Column(
            children: [
              CupertinoButton(
                padding: EdgeInsets.all(12.0),
                color: CupertinoColors.systemGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
                child: const Icon(CupertinoIcons.add,
                    color: CupertinoColors.white),
                onPressed: () {
                  appState.zoomUp();
                },
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: EdgeInsets.all(12.0),
                color: CupertinoColors.systemGrey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
                child: const Icon(CupertinoIcons.minus,
                    color: CupertinoColors.white),
                onPressed: () {
                  controller.zoomDown();
                },
              ),
            ],
          ),
        ),
      );
    }

    // 添加标记按钮
    Widget buildAddMarkerButton() {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.add_circled),
        onPressed: () {
          // 获取当前页面
          int currentPage = appState.currentPage;
          // 定义标记颜色
          Color markerColor = CupertinoColors.systemYellow;
          // 定义标记范围（示例）
          // PdfTextRanges ranges = PdfTextRanges() // 根据实际需求获取范围
          // Marker marker = Marker(markerColor, ranges);
          // appState.addMarker(currentPage, marker);
        },
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // middle: const Text('PDF 阅读器'), // 删除标题
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: appState._toggleOutline,
          child: const Icon(CupertinoIcons.list_bullet),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.doc),
              onPressed: () async {
                await appState._pickFile();
                if (appState._selectedFile != null) {
                  await appState._loadOutline();
                }
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => appState._savePdf(context),
              child: const Icon(CupertinoIcons.arrow_down_doc),
            ),
          ],
        ),
        // 新增：高亮按钮放在中间
        middle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              padding: EdgeInsets.all(8.0),
              // color: CupertinoColors,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.pencil_outline,
                color: CupertinoColors.systemRed,
              ),
              onPressed: () {},
            ),
            CupertinoButton(
              padding: EdgeInsets.all(8.0),
              // color: CupertinoColors,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.paintbrush,
                color: CupertinoColors.systemYellow,
              ),
              onPressed: () {
                if (kDebugMode) {
                  debugPrint(
                      'applyHighlight: ${appState.isHighlightButtonVisible}');
                }
                if (appState.isHighlightButtonVisible) {
                  appState.applyHighlight();
                }
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.all(8.0),
              // color: CupertinoColors,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.underline,
                color: CupertinoColors.systemBlue,
              ),
              onPressed: () {
                // if (appState.isHighlightButtonVisible) {
                //   appState.applyHighlight();
                // }
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (!appState.isSearching &&
                          appState._isOutlineVisible &&
                          appState._outline != null)
                        buildOutlineSection(),
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            appState.isSearching
                                ? const Center(child: Text('搜索结果'))
                                : (appState._selectedFile == null
                                    ? const Center(child: Text('请选择PDF文件'))
                                    : PdfViewer.file(
                                        appState._selectedFile!.path,
                                        controller: controller,
                                        params: PdfViewerParams(
                                          enableTextSelection: true,
                                          pagePaintCallbacks: [
                                            (canvas, converter, pageNumber) {
                                              // if (kDebugMode) {
                                              //   debugPrint(
                                              //       'pageNumber: $pageNumber');
                                              // }
                                              appState._paintMarkers(canvas,
                                                  converter, pageNumber);

                                              // if (selections.isNotEmpty) {
                                              //   appState.handleTextSelection(
                                              //       selections.first,
                                              //       Offset(100, 100));
                                              // }
                                            }
                                          ],
                                          onTextSelectionChange: (selections) {
                                            print("hahhh");
                                            if (kDebugMode) {
                                              debugPrint(
                                                  'selections: ${selections.isNotEmpty}');
                                              debugPrint(
                                                  'selections: ${selections.first}');
                                            }
                                            if (selections.isNotEmpty) {
                                              appState.handleTextSelection(
                                                  selections.first,
                                                  Offset(100, 100));
                                            }
                                          },
                                          viewerOverlayBuilder:
                                              (BuildContext context, Size size,
                                                  linkHandler) {
                                            return [
                                              Stack(
                                                children: [
                                                  PdfViewerScrollThumb(
                                                    controller: controller,
                                                    orientation:
                                                        ScrollbarOrientation
                                                            .right,
                                                    thumbSize:
                                                        const Size(40, 25),
                                                    thumbBuilder: (context,
                                                        size,
                                                        pageNumber,
                                                        controller) {
                                                      if (pageNumber == null)
                                                        return null;
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: CupertinoColors
                                                              .systemGrey
                                                              .withOpacity(0.7),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            pageNumber
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  CupertinoColors
                                                                      .white,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ];
                                          },
                                        ),
                                      )),
                            buildZoomButtons(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
