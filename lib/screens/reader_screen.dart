import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/extension.dart';

class Marker {
  final Color color;
  final PdfTextRanges ranges;

  Marker(this.color, this.ranges);
}

class MyAppState extends ChangeNotifier {
  final PdfViewerController pdfViewerController = PdfViewerController();

  var currentPage = 0;
  bool _isOutlineVisible = false;
  File? _selectedFile;
  List<PdfOutlineNode>? _outline;

  bool _isSearching = false;
  String _searchQuery = '';
  List<int> _searchResults = [];

  final ScrollController scrollController = ScrollController();

  var _textSelections = [];

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

    print('toggleOutline: $_isOutlineVisible');
    print('outline: $_outline');
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
      try {
        final document = await PdfDocument.openFile(_selectedFile!.path);
        final outline = await document.loadOutline();
        _outline = outline;
        await document.dispose();
        notifyListeners();
      } catch (e) {
        if (kDebugMode) {
          print('加载大纲时出错: $e');
        }
      }
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
    _selectedFile = file;
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

class _PdfPageTextRefCount {
  _PdfPageTextRefCount(this.pageText);
  final PdfPageText pageText;
  int refCount = 0;
}

class PdfPageTextCache {
  final PdfTextSearcher textSearcher;
  PdfPageTextCache({
    required this.textSearcher,
  });

  final _pageTextRefs = <int, _PdfPageTextRefCount>{};

  /// load the text of the given page number.
  Future<PdfPageText> loadText(int pageNumber) async {
    final ref = _pageTextRefs[pageNumber];
    if (ref != null) {
      ref.refCount++;
      return ref.pageText;
    }
    return await synchronized(() async {
      var ref = _pageTextRefs[pageNumber];
      if (ref == null) {
        final pageText = await textSearcher.loadText(pageNumber: pageNumber);
        ref = _pageTextRefs[pageNumber] = _PdfPageTextRefCount(pageText!);
      }
      ref.refCount++;
      return ref.pageText;
    });
  }

  /// Release the text of the given page number.
  void releaseText(int pageNumber) {
    final ref = _pageTextRefs[pageNumber]!;
    ref.refCount--;
    if (ref.refCount == 0) {
      _pageTextRefs.remove(pageNumber);
    }
  }
}

//
// 文本搜索视图
//
class TextSearchView extends StatefulWidget {
  const TextSearchView({
    Key? key,
    required this.textSearcher,
    required this.onSearchEmpty,
  }) : super(key: key);

  final PdfTextSearcher textSearcher;
  final VoidCallback onSearchEmpty;

  @override
  State<TextSearchView> createState() => _TextSearchViewState();
}

class _TextSearchViewState extends State<TextSearchView> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController searchTextController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final PdfPageTextCache pageTextStore =
      PdfPageTextCache(textSearcher: widget.textSearcher);

  @override
  void initState() {
    widget.textSearcher.addListener(_searchResultUpdated);
    searchTextController.addListener(_searchTextUpdated);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    widget.textSearcher.removeListener(_searchResultUpdated);
    searchTextController.removeListener(_searchTextUpdated);
    searchTextController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _searchTextUpdated() {
    final query = searchTextController.text;
    if (query.isEmpty) {
      widget.onSearchEmpty();
    }
    widget.textSearcher.startTextSearch(query);
  }

  int? _currentSearchSession;
  final _matchIndexToListIndex = <int>[];
  final _listIndexToMatchIndex = <int>[];

  void _searchResultUpdated() {
    if (_currentSearchSession != widget.textSearcher.searchSession) {
      _currentSearchSession = widget.textSearcher.searchSession;
      _matchIndexToListIndex.clear();
      _listIndexToMatchIndex.clear();
    }
    for (int i = _matchIndexToListIndex.length;
        i < widget.textSearcher.matches.length;
        i++) {
      if (i == 0 ||
          widget.textSearcher.matches[i - 1].pageNumber !=
              widget.textSearcher.matches[i].pageNumber) {
        _listIndexToMatchIndex
            .add(-widget.textSearcher.matches[i].pageNumber); // 负索引用于指示页标题
      }
      _matchIndexToListIndex.add(_listIndexToMatchIndex.length);
      _listIndexToMatchIndex.add(i);
    }

    if (mounted) setState(() {});
  }

  static const double itemHeight = 50;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.textSearcher.isSearching
            ? LinearProgressIndicator(
                value: widget.textSearcher.searchProgress,
                minHeight: 4,
              )
            : const SizedBox(height: 4),
        Row(
          children: [
            // const SizedBox(width: 8),
            // Expanded(
            //   child: Stack(
            //     alignment: Alignment.centerLeft,
            //     children: [
            //       // CupertinoSearchTextField(
            //       //   autofocus: true,
            //       //   focusNode: focusNode,
            //       //   controller: searchTextController,
            //       //   placeholder: '搜索 PDF 内容',
            //       //   onSubmitted: (value) {},
            //       // ),
            //       // if (widget.textSearcher.hasMatches)
            //       //   Align(
            //       //     alignment: Alignment.centerRight,
            //       //     child: Text(
            //       //       '${widget.textSearcher.currentIndex! + 1} / ${widget.textSearcher.matches.length}',
            //       //       style: const TextStyle(
            //       //         fontSize: 12,
            //       //         color: CupertinoColors.systemGrey,
            //       //       ),
            //       //     ),
            //       //   ),
            //     ],
            //   ),
            // ),
            // const SizedBox(width: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: (widget.textSearcher.currentIndex ?? 0) > 0
                  ? () async {
                      await widget.textSearcher.goToPrevMatch();
                      _conditionScrollPosition();
                    }
                  : null,
              child: const Icon(CupertinoIcons.arrow_left),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: (widget.textSearcher.currentIndex ?? 0) <
                      widget.textSearcher.matches.length
                  ? () async {
                      await widget.textSearcher.goToNextMatch();
                      _conditionScrollPosition();
                    }
                  : null,
              child: const Icon(CupertinoIcons.arrow_right),
            ),

            // CupertinoButton(
            //   padding: EdgeInsets.zero,
            //   onPressed: searchTextController.text.isNotEmpty
            //       ? () {
            //           searchTextController.text = '';
            //           widget.textSearcher.resetTextSearch();
            //           focusNode.requestFocus();
            //         }
            //       : null,
            //   child: const Icon(CupertinoIcons.clear_circled),
            // ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            key: Key(searchTextController.text),
            controller: scrollController,
            itemCount: _listIndexToMatchIndex.length,
            itemBuilder: (context, index) {
              final matchIndex = _listIndexToMatchIndex[index];
              if (matchIndex >= 0 &&
                  matchIndex < widget.textSearcher.matches.length) {
                final match = widget.textSearcher.matches[matchIndex];
                return SearchResultTile(
                  key: ValueKey(index),
                  match: match,
                  onTap: () async {
                    await widget.textSearcher.goToMatchOfIndex(matchIndex);
                    if (mounted) setState(() {});
                  },
                  pageTextStore: pageTextStore,
                  height: itemHeight,
                  isCurrent: matchIndex == widget.textSearcher.currentIndex,
                );
              } else {
                return Container(
                  height: itemHeight,
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '第 ${-matchIndex} 页',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _conditionScrollPosition() {
    final pos = scrollController.position;
    final newPos =
        itemHeight * _matchIndexToListIndex[widget.textSearcher.currentIndex!];
    if (newPos + itemHeight > pos.pixels + pos.viewportDimension) {
      scrollController.animateTo(
        newPos + itemHeight - pos.viewportDimension,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    } else if (newPos < pos.pixels) {
      scrollController.animateTo(
        newPos,
        duration: const Duration(milliseconds: 300),
        curve: Curves.decelerate,
      );
    }

    if (mounted) setState(() {});
  }
}

class ReaderScreen extends StatelessWidget {
  final String filePath;

  ReaderScreen({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyAppState(),
      child: MyHomePage(selectedFilePath: filePath),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String selectedFilePath;

  const MyHomePage({Key? key, required this.selectedFilePath})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 加载传递的文件路径
  @override
  void initState() {
    super.initState();
    // 设置选中的文件
    if (kDebugMode) {
      debugPrint('selectedFilePath: ${widget.selectedFilePath}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyAppState>(context, listen: false)
          .setSelectedFile(File(widget.selectedFilePath));
      // setState(() {
      // appState.setSelectedFile(File(widget.selectedFilePath));
      // _selectedFile = File(widget.selectedFilePath);
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final controller = appState.pdfViewerController;

    if (kDebugMode) {
      debugPrint('Controller: ${controller}');
    }

    // appState.setSelectedFile(_selectedFile!);

    // 搜索框
    Widget buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: CupertinoSearchTextField(
          placeholder: '搜索 PDF 内容',
          onSubmitted: (value) {
            // if (kDebugMode) {
            //   debugPrint('onSubmitted: $value');
            // }
            // appState.toggleSearch(value);
          },
          onChanged: (value) {
            if (kDebugMode) {
              debugPrint('onChanged: $value');
            }
            appState.toggleSearch(value);
            // if (value.isEmpty) {
            //   appState.toggleSearch('');
            // }
          },
        ),
      );
    }

    Widget buildScrollBar() {
      return PdfViewerScrollThumb(
        controller: controller,
        orientation: ScrollbarOrientation.right,
        thumbSize: const Size(40, 25),
        thumbBuilder: (context, size, pageNumber, controller) {
          if (pageNumber == null) return null;
          return Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                pageNumber.toString(),
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      );
    }

    // 搜索框和搜索结果视图
    Widget buildSearchSection() {
      return Expanded(
        child: TextSearchView(
          textSearcher: appState.textSearcher,
          onSearchEmpty: () {
            setState(() {
              // 当搜索框为空时，显示大纲
              appState._toggleOutline();
            });
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

    Widget buildSideBar() {
      if (!appState._isOutlineVisible || appState._outline == null) {
        return Container();
      }
      return Container(
        width: 250,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildSearchBar(),
            appState.isSearching
                ? buildSearchSection()
                : Expanded(
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
                  appState.zoomDown();
                },
              ),
            ],
          ),
        ),
      );
    }

    ObstructingPreferredSizeWidget? buildToolBar() {
      return CupertinoNavigationBar(
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
                CupertinoIcons.paintbrush,
                color: CupertinoColors.systemYellow,
              ),
              onPressed: () {
                if (kDebugMode) {
                  debugPrint('selections: ${appState._textSelections.isEmpty}');
                }
                if (appState._textSelections.isNotEmpty) {
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
            CupertinoButton(
              padding: EdgeInsets.all(8.0),
              // color: CupertinoColors,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.systemBlue,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }

    Widget buildViewer() {
      return PdfViewer.file(
        appState._selectedFile!.path,
        controller: controller,
        params: PdfViewerParams(
          enableTextSelection: true,
          onTextSelectionChange: (selections) {
            print('文本选择变化: $selections');
            // appState.updateTextSelections(selections);
          },
          pagePaintCallbacks: [
            appState.textSearcher.pageTextMatchPaintCallback,
            appState._paintMarkers,
          ],
          viewerOverlayBuilder: (BuildContext context, Size size, linkHandler) {
            return [
              Stack(
                children: [
                  buildScrollBar(),
                  buildZoomButtons(),
                ],
              ),
            ];
          },
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: buildToolBar(),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (appState._isOutlineVisible)
                        // buildOutlineSection(),
                        buildSideBar(),
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            buildViewer(),
                            // buildZoomButtons(),
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

class SearchResultTile extends StatefulWidget {
  const SearchResultTile({
    super.key,
    required this.match,
    required this.onTap,
    required this.pageTextStore,
    required this.height,
    required this.isCurrent,
  });

  final PdfTextRangeWithFragments match;
  final void Function() onTap;
  final PdfPageTextCache pageTextStore;
  final double height;
  final bool isCurrent;

  @override
  State<SearchResultTile> createState() => _SearchResultTileState();
}

class _SearchResultTileState extends State<SearchResultTile> {
  PdfPageText? pageText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _release() {
    if (pageText != null) {
      widget.pageTextStore.releaseText(pageText!.pageNumber);
    }
  }

  Future<void> _load() async {
    _release();
    pageText = await widget.pageTextStore.loadText(widget.match.pageNumber);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text.rich(createTextSpanForMatch(pageText, widget.match));

    return SizedBox(
      height: widget.height,
      child: Material(
        color: widget.isCurrent
            ? DefaultSelectionStyle.of(context).selectionColor!
            : null,
        child: InkWell(
          onTap: () => widget.onTap(),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black12,
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: text,
          ),
        ),
      ),
    );
  }

  TextSpan createTextSpanForMatch(
      PdfPageText? pageText, PdfTextRangeWithFragments match,
      {TextStyle? style}) {
    style ??= const TextStyle(
      fontSize: 14,
    );
    if (pageText == null) {
      return TextSpan(
        text: match.fragments.map((f) => f.text).join(),
        style: style,
      );
    }
    final fullText = pageText.fullText;
    int first = 0;
    for (int i = match.fragments.first.index - 1; i >= 0;) {
      if (fullText[i] == '\n') {
        first = i + 1;
        break;
      }
      i--;
    }
    int last = fullText.length;
    for (int i = match.fragments.last.end; i < fullText.length; i++) {
      if (fullText[i] == '\n') {
        last = i;
        break;
      }
    }

    final header =
        fullText.substring(first, match.fragments.first.index + match.start);
    final body = fullText.substring(match.fragments.first.index + match.start,
        match.fragments.last.index + match.end);
    final footer =
        fullText.substring(match.fragments.last.index + match.end, last);

    return TextSpan(
      children: [
        TextSpan(text: header),
        TextSpan(
          text: body,
          style: const TextStyle(
            backgroundColor: Colors.yellow,
          ),
        ),
        TextSpan(text: footer),
      ],
      style: style,
    );
  }
}
