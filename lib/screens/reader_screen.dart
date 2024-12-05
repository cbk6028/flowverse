// import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/extension.dart';

import '../viewmodels/reader_vm.dart';

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
              if (matchIndex >= 0) {
                // 确保 matchIndex 在有效范围内
                if (matchIndex >= widget.textSearcher.matches.length) {
                  return Container(); // 返回空容器，避免越界
                }
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
                // 页码显示
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
      create: (_) => ReaderViewModel(),
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
      Provider.of<ReaderViewModel>(context, listen: false)
          .setSelectedFile(File(widget.selectedFilePath));
      // setState(() {
      // appState.setSelectedFile(File(widget.selectedFilePath));
      // _selectedFile = File(widget.selectedFilePath);
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    final controller = appState.pdfViewerController;

    if (kDebugMode) {
      debugPrint('Controller: ${controller}');
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
              appState.toggleOutline();
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
                padding: const EdgeInsets.all(12.0),
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
                padding: const EdgeInsets.all(12.0),
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
          onPressed: appState.toggleOutline,
          child: const Icon(CupertinoIcons.list_bullet),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => appState.toggleDarkMode(),
              child: Icon(appState.darkMode
                    ? CupertinoIcons.moon
                  : CupertinoIcons.sun_max),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => appState.savePdf(context),
              child: const Icon(CupertinoIcons.arrow_down_doc),
            ),
          ],
        ),
        // 新增：高亮按钮放在中间
        middle: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
              // color: CupertinoColors,
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.paintbrush,
                color: CupertinoColors.systemYellow,
              ),
              onPressed: () {
                if (kDebugMode) {
                  debugPrint('selections: ${appState.textSelections.isEmpty}');
                }
                if (appState.textSelections.isNotEmpty) {
                  appState.applyHighlight();
                }
              },
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
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
              padding: const EdgeInsets.all(8.0),
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
      return ColorFiltered(
        colorFilter:  ColorFilter.mode(Colors.white, appState.darkMode ? BlendMode.difference : BlendMode.dst),
        child: PdfViewer.file(
          appState.selectedFile!.path,
          controller: controller,
          params: PdfViewerParams(
            backgroundColor: const Color(0xfffafafa),
            pageDropShadow: const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
            enableTextSelection: true,
            onTextSelectionChange: (selections) {
              print('文本选择变化: $selections');
              // appState.updateTextSelections(selections);
            },
            pagePaintCallbacks: [
              appState.textSearcher.pageTextMatchPaintCallback,
              appState.paintMarkers,
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
                      if (appState.isOutlineVisible) const SideBar(),
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

// ##############################################################################################################################
// #                                                                                                                                          侧边栏                                                                                                                                                          #
// ##############################################################################################################################

// 侧边栏
// 有大纲，搜索等功能
class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int? _index = 0; // 移到类级别

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReaderViewModel>();

    if (!viewModel.isOutlineVisible || viewModel.outline == null) {
      return Container();
    }
    return Container(
      width: 250,
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SearchBar(),
          if (viewModel.isSearching)
            // Container()
          SearchSection()
          else ...[
            // 使用 spread operator (...) 来展开多个 widget
            CupertinoSlidingSegmentedControl<int>(
              children: const {
                0: Text('目录'),
                1: Text('批注'),
                2: Text('书签'),
                3: Text('缩略图'),
              },
              groupValue: _index,
              onValueChanged: (value) {
                if (kDebugMode) {
                  debugPrint('value: $value');
                }
                setState(() {
                  _index = value;
                });
              },
            ),
            const SizedBox(
              height: 20,
            ),
            switch (_index) {
              0 => const Outline(),
              1 => const Expanded(child: Center(child: Text('批注'))),
              2 => const Expanded(child: Center(child: Text('书签'))),
              3 => const Expanded(child: Center(child: Text('缩略图'))),
              _ => Container(),
            }
          ],
        ],
      ),
    );
  }
}

// 搜索
class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CupertinoSearchTextField(
        placeholder: '搜索 PDF 内容',
        onSubmitted: (value) {},
        onChanged: (value) {
          if (kDebugMode) {
            debugPrint('onChanged: $value');
          }
          appState.toggleSearch(value);
        },
      ),
    );
  }
}

class SearchSection extends StatelessWidget {
  const SearchSection({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();

    // 搜索框和搜索结果视图
    return Expanded(
      child: TextSearchView(
        textSearcher: appState.textSearcher,
        onSearchEmpty: () {
          // setState(() {
          // 当搜索框为空时，显示大纲
          appState.toggleOutline();
          // });
        },
      ),
    );
  }
}

// 选项
class SideBarSegment extends StatefulWidget {
  const SideBarSegment({super.key});

  @override
  State<SideBarSegment> createState() => _SideBarSegmentState();
}

class _SideBarSegmentState extends State<SideBarSegment> {
  int? _index = 0;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class Outline extends StatelessWidget {
  const Outline({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ReaderViewModel>().pdfViewerController;

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

    return Expanded(
      child: CupertinoScrollbar(
        child: SingleChildScrollView(
          child: buildOutlineList(context.watch<ReaderViewModel>().outline!),
        ),
      ),
    );
  }
}
