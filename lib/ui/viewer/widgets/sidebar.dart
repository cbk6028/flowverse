import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../vm/reader_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/foundation.dart';
import 'package:synchronized/extension.dart';
import 'dart:ui';
// import 'package:webf/webf.dart';
// import '../models/webf.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

// 侧边栏
// 有大纲，搜索等功能

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    var index = appState.index;
    var theme = Theme.of(context);
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow, // 与阅读器背景颜色一致
            border: Border(
              right: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(1, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              switch (appState.index) {
                0 => Expanded(
                    child: appState.outline != null
                        ? const Outline()
                        : Center(
                            child: Text(
                              'No outline available',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),
                // 1 => const Expanded(child: Center(child: Text('批注'))),
                2 => Expanded(
                    child: Center(
                      child: Text(
                        '书签',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                3 => const Expanded(child: ThumbnailView()),
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
        ),
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
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoSearchTextField(
          placeholder: '搜索 PDF 内容',
          placeholderStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 14,
          ),
          style: TextStyle(
            color: Colors.black87.withOpacity(0.75),
            fontSize: 14,
          ),
          onSubmitted: (value) {},
          onChanged: (value) {
            if (kDebugMode) {
              debugPrint('onChanged: $value');
            }
            appState.toggleSearch(value);
          },
        ),
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
  final int _index = 0;

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
                              ? PhosphorIconsRegular.caretDown
                              : PhosphorIconsRegular.caretRight,
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
              child: const Icon(PhosphorIconsRegular.arrowLeft),
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
              child: const Icon(PhosphorIconsRegular.arrowRight),
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

class LeftSidebar extends StatefulWidget {
  const LeftSidebar({super.key});

  @override
  State<LeftSidebar> createState() => _LeftSidebarState();
}

class _LeftSidebarState extends State<LeftSidebar> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    var theme = Theme.of(context);

    return Stack(
      children: [
        // 实际的侧边栏
        MouseRegion(
          onExit: (_) => setState(() => _isVisible = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _isVisible ? 37 : 8,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow, // 与阅读器背景颜色一致
                    border: Border(
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isVisible ? 1.0 : 0.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 原有的侧边栏按钮
                        _buildButton(
                          icon: PhosphorIconsRegular.magnifyingGlass,
                          tooltip: '搜索',
                          onPressed: () => appState.toggleOutline(4),
                        ),
                        _buildButton(
                          icon: PhosphorIconsRegular.list,
                          tooltip: '目录',
                          onPressed: () => appState.toggleOutline(0),
                        ),
                        _buildButton(
                          icon: PhosphorIconsRegular.images,
                          tooltip: '缩略图',
                          onPressed: () => appState.toggleOutline(3),
                        ),

                        const Spacer(), // 添加弹性空间，将下面的按钮推到底部

                        // 添加分隔线
                        Container(
                          width: 20,
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),

                        // 从底栏移过来的按钮
                        // 上一页按钮
                        _buildButton(
                          icon: PhosphorIconsRegular.caretLeft,
                          tooltip: '上一页',
                          onPressed: () => appState.goToPreviousPage(),
                        ),

                        // 页码显示 - 简化版
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: GestureDetector(
                            onTap: () {
                              // 显示页码输入对话框
                              _showPageInputDialog(context, appState);
                            },
                            child: Text(
                              '${appState.currentPageNumber ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),

                        // 下一页按钮
                        _buildButton(
                          icon: PhosphorIconsRegular.caretRight,
                          tooltip: '下一页',
                          onPressed: () => appState.goToNextPage(),
                        ),

                        const SizedBox(height: 16),

                        // 缩小按钮
                        _buildButton(
                          icon: PhosphorIconsRegular.minus,
                          tooltip: '缩小',
                          onPressed: () => appState.zoomDown(),
                        ),

                        // 缩放百分比显示
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${(appState.pdfViewerController.currentZoom * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),

                        // 放大按钮
                        _buildButton(
                          icon: PhosphorIconsRegular.plus,
                          tooltip: '放大',
                          onPressed: () => appState.zoomUp(),
                        ),

                        const SizedBox(height: 16),

                        // 双页模式切换
                        _buildButton(
                          icon: appState.isDoublePageMode
                              ? PhosphorIconsRegular.bookOpenText
                              : PhosphorIconsRegular.book,
                          tooltip: '双页模式',
                          onPressed: () {
                            appState.isDoublePageMode =
                                !appState.isDoublePageMode;
                          },
                        ),
                        const SizedBox(height: 16), // 底部间距
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 透明的检测区域
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 20, // 更宽的检测区域
          child: MouseRegion(
            onEnter: (_) => setState(() => _isVisible = true),
            child: Container(
              color: Colors.transparent, // 透明区域
            ),
          ),
        ),
      ],
    );
  }

  // 显示页码输入对话框
  void _showPageInputDialog(BuildContext context, ReaderViewModel appState) {
    final TextEditingController controller = TextEditingController();
    controller.text = (appState.currentPageNumber ?? 0).toString();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('跳转到页面'),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () {
              try {
                final pageNumber = int.parse(controller.text);
                if (pageNumber > 0 && pageNumber <= appState.totalPages) {
                  appState.pdfViewerController.goToPage(pageNumber: pageNumber);
                }
              } catch (e) {
                // 解析失败，不做任何操作
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    var theme = Theme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: 16,
        ),
      ),
    );
  }
}

// 缩略图视图
class ThumbnailView extends StatefulWidget {
  const ThumbnailView({super.key});

  @override
  State<ThumbnailView> createState() => _ThumbnailViewState();
}

class _ThumbnailViewState extends State<ThumbnailView> {
  late ScrollController _scrollController;
  int? _lastPageNumber;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPage(int? currentPageNumber, int totalPages) {
    if (currentPageNumber == null ||
        currentPageNumber <= 0 ||
        currentPageNumber > totalPages) {
      return;
    }

    // 只有当页面变化时才滚动
    if (_lastPageNumber != currentPageNumber) {
      _lastPageNumber = currentPageNumber;

      // 计算目标位置（每个缩略图项目高度约为256像素）
      final itemHeight = 256.0;
      final targetOffset = (currentPageNumber - 1) * itemHeight;

      // 使用动画滚动到目标位置
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    final document = appState.pdfViewerController.documentRef;
    final controller = appState.pdfViewerController;
    final currentPageNumber = appState.currentPageNumber;
    final totalPages = appState.totalPages;
    var theme = Theme.of(context);
    // 当页面变化时滚动到当前页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentPage(currentPageNumber, totalPages);
    });

    return Container(
      color: Colors.transparent,
      child: document == null
          ? Center(
              child: Text(
                '没有文档',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
            )
          : PdfDocumentViewBuilder(
              documentRef: document,
              builder: (context, document) => ListView.builder(
                controller: _scrollController,
                itemCount: document?.pages.length,
                itemBuilder: (context, index) {
                  final isCurrentPage = appState.currentPageNumber == index + 1;
                  return Container(
                    margin: const EdgeInsets.all(8),
                    height: 240,
                    child: Column(
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: isCurrentPage
                                ? Border.all(
                                    color: CupertinoColors.systemBlue
                                        .withOpacity(0.6),
                                    width: 2,
                                  )
                                : Border.all(
                                    color: Colors.black.withOpacity(0.1),
                                    width: 1,
                                  ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
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
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '第 ${index + 1} 页',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCurrentPage
                                ? CupertinoColors.systemBlue.withOpacity(0.8)
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
