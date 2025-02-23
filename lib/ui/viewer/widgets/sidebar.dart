import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vm/reader_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/extension.dart';
// import 'package:webf/webf.dart';
// import '../models/webf.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';

// 侧边栏
// 有大纲，搜索等功能

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    var _index = appState.index;

    Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.map((node) {
          final nodeKey = '${node.title}_$indent';
          final isExpanded = appState.outlineExpandedStates[nodeKey] ?? false;
          final isCurrentPage = appState.isCurrentPage(node);

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 16 + indent,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                width: double.infinity,
                child: Row(
                  children: [
                    if (node.children.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          appState.toggleOutlineNode(nodeKey);
                        },
                        child: Icon(
                          isExpanded
                              ? PhosphorIconsLight.caretDown
                              : PhosphorIconsLight.caretRight,
                          size: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    SizedBox(width: node.children.isNotEmpty ? 8 : 0),
                    Expanded(
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: node.dest != null
                            ? () =>
                                appState.pdfViewerController.goToDest(node.dest)
                            : null,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            node.title ?? '',
                            style: TextStyle(
                              color: node.dest != null
                                  ? CupertinoColors.label
                                  : CupertinoColors.systemGrey,
                              fontSize: 14,
                              fontWeight: isCurrentPage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (node.children.isNotEmpty && isExpanded)
                buildOutlineList(node.children, indent: indent + 20),
            ],
          );
        }).toList(),
      );
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          switch (appState.index) {
            0 => Expanded(
                child: appState.outline != null
                    ? Outline()
                    : const Center(child: Text('No outline available')),
              ),
            // 1 => const Expanded(child: Center(child: Text('批注'))),
            2 => const Expanded(child: Center(child: Text('书签'))),
            3 => Expanded(
                child: ThumbnailView(),
              ),
            4 => Expanded(
                child: Column(
                  children: [
                    const SearchBar(),
                    if (appState.isSearching) const SearchSection()
                  ],
                ),
              ),
            _ => Container(),
          }
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
          // appState.toggleOutline();
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
    final appState = context.watch<ReaderViewModel>();
    final controller = appState.pdfViewerController;

    Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.map((node) {
          final nodeKey = '${node.title}_$indent';
          final isExpanded = appState.outlineExpandedStates[nodeKey] ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: 16 + indent,
                  right: 16,
                  top: 8,
                  bottom: 8,
                ),
                width: double.infinity,
                child: Row(
                  children: [
                    if (node.children.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          appState.outlineExpandedStates[nodeKey] = !isExpanded;
                          appState.notifyListeners();
                        },
                        child: Icon(
                          isExpanded
                              ? PhosphorIconsLight.caretDown
                              : PhosphorIconsLight.caretRight,
                          size: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    SizedBox(width: node.children.isNotEmpty ? 8 : 20),
                    Expanded(
                      child: CupertinoButton(
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
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            node.title ?? '',
                            style: TextStyle(
                              color: node.dest != null
                                  ? CupertinoColors.label
                                  : CupertinoColors.systemGrey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (node.children.isNotEmpty && isExpanded)
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
          child: buildOutlineList(appState.outline!),
        ),
      ),
    );
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
              child: const Icon(PhosphorIconsLight.arrowLeft),
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
              child: const Icon(PhosphorIconsLight.arrowRight),
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
            child: Text.rich(createTextSpanForMatch(pageText, widget.match)),
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

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();

    return Container(
      width: 45, // Narrow sidebar
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(-1, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              PhosphorIconsLight.magnifyingGlass,
              color: Colors.black87,
              size: 20,
            ),
            color: Colors.transparent,
            iconSize: 20,
            tooltip: '搜索',
            onPressed: () {
              // Handle navigation to 搜索
              appState.toggleOutline(4);
            },
          ),
          IconButton(
            icon: Icon(
              PhosphorIconsLight.list,
              color: Colors.black87,
              size: 20,
            ),
            color: Colors.transparent,
            iconSize: 20,
            tooltip: '目录',
            onPressed: () {
              // Handle navigation to 目录
              appState.toggleOutline(0);
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.comment_outlined),
          //   color: Colors.black,
          //   tooltip: '批注',
          //   onPressed: () {
          //     // Handle navigation to 批注
          //     appState.toggleOutline(1);
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.bookmark_outline),
          //   color: Colors.black,
          //   tooltip: '书签',
          //   onPressed: () {
          //     // Handle navigation to 书签
          //     appState.toggleOutline(2);
          //   },
          // ),
          IconButton(
            icon: Icon(
              PhosphorIconsLight.images,
              color: Colors.black87,
              size: 20,
            ),
            color: Colors.transparent,
            iconSize: 20,
            tooltip: '缩略图',
            onPressed: () {
              // Handle navigation to 缩略图
              appState.toggleOutline(3);
            },
          ),
        ],
      ),
    );
  }
}



// 缩略图视图
class ThumbnailView extends StatelessWidget {
  const ThumbnailView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    final document = appState.pdfViewerController.documentRef;
    final controller = appState.pdfViewerController;

    return Container(
        color: CupertinoColors.systemGrey6,
        child: document == null
            ? const Center(child: Text('没有文档'))
            : PdfDocumentViewBuilder(
                documentRef: document!,
                builder: (context, document) => ListView.builder(
                  itemCount: document?.pages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(8),
                      height: 240,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => controller.goToPage(
                                pageNumber: index + 1,
                                anchor: PdfPageAnchor.top,
                              ),
                              child: PdfPageView(
                                document: document,
                                pageNumber: index + 1,
                                alignment: Alignment.center,
                              ),
                            ),
                          ),
                          Text(
                            '第 ${index + 1} 页',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ));
  }
}
