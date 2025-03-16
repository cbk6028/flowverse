import 'dart:math';

import 'package:flov/data/repositories/archive/archive_repository.dart';
import 'package:flov/domain/models/book/book.dart';
import 'package:flov/ui/viewer/vm/tabs_vm.dart';
import 'package:flov/ui/viewer/widgets/rightsidebar.dart';
import 'package:flov/ui/viewer/widgets/topbar.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flov/utils/file_utils.dart';
import 'package:flov/utils/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// import 'package:simple_painter/simple_painter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import 'custom_text_selection_controls.dart';
import '../../overlay_marker/widgets/marker_overlay_builder.dart';
import '../vm/reader_vm.dart';

import 'sidebar.dart';
import 'package:flov/ui/overlay_canvas/widgets/drawing_overlay.dart';
import 'package:flov/ui/overlay_canvas/vm/drawing_vm.dart';
import 'package:flov/ui/viewer/widgets/tabs_bar.dart';

class ReaderScreen extends StatelessWidget {
  final String filePath;
  final Book book;
  const ReaderScreen({Key? key, required this.filePath, required this.book})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // // 获取上层的 DashboardViewModel
    // final dashboardVm = context.read<DashboardViewModel>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrawingViewModel()),
        ChangeNotifierProvider(create: (_) => ReaderViewModel()),
        // 添加标签页管理器
        ChangeNotifierProvider(create: (_) => TabsViewModel()),
        // 使用 value 构造函数共享上层的 DashboardViewModel
        // ChangeNotifierProvider.value(value: dashboardVm),
        ChangeNotifierProvider(
            create: (_) =>
                MarkerViewModel(archiveRepository: ArchiveRepository())),
      ],
      child: MyHomePage(selectedFilePath: filePath, book: book),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String selectedFilePath;
  final Book book;

  const MyHomePage(
      {Key? key, required this.selectedFilePath, required this.book})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 添加一个 Map 来跟踪每个节点的展开状态
  // final Map<String, bool> _expandedNodes = {};

  // 加载传递的文件路径
  @override
  void initState() {
    super.initState();
    var appState = context.read<ReaderViewModel>();
    var tabsVm = context.read<TabsViewModel>();

    // 设置当前PDF路径
    appState.currentPdfPath = widget.selectedFilePath;

    // 添加初始标签页
    tabsVm.addTab(widget.selectedFilePath, widget.book);

    // 设置最后一个标签页关闭时的回调
    tabsVm.onLastTabClosed = () {
      // 清理PDF阅读器状态
      appState.clearReaderState();
      // 返回到仪表盘页面
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    };

    // 设置选中的文件
    if (kDebugMode) {
      debugPrint('selectedFilePath: ${widget.selectedFilePath}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReaderViewModel>(context, listen: false)
          .setSelectedFile(File(widget.selectedFilePath));
    });

    // 加载保存的高亮
    var markerVm = context.read<MarkerViewModel>();
    markerVm.loadArchive(widget.book);

    // var bookRepository = BookRepository().loadBooks();
    appState.currentPage = widget.book.lastReadPage;

    appState.currentBook = widget.book;

    logger.i('currentPage: ${appState.currentPage}');
  }

  @override
  void dispose() {
    // 保存高亮
    var markerVm = context.read<MarkerViewModel>();
    markerVm.saveArchive(widget.book);
    super.dispose();
  }

  // 处理标签页切换
  void _handleTabChange() {
    var appState = context.read<ReaderViewModel>();
    var tabsVm = context.read<TabsViewModel>();
    var markerVm = context.read<MarkerViewModel>();

    // 获取当前活动标签页
    final activeTab = tabsVm.activeTab;
    if (activeTab != null) {
      // 保存当前标签页的状态
      if (appState.currentPdfPath.isNotEmpty) {
        markerVm.saveArchive(widget.book);
      }

      // 切换到新标签页
      appState.currentPdfPath = activeTab.filePath;
      appState.setSelectedFile(File(activeTab.filePath));
      appState.currentPage = activeTab.book.lastReadPage;

      // 加载新标签页的高亮
      markerVm.loadArchive(activeTab.book);
    }
  }

  // 打开新文件
  Future<void> _openNewFile() async {
    var tabsVm = context.read<TabsViewModel>();

    // 使用文件选择器选择PDF文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;

      // 检查是否已经打开了该文件
      int existingTabIndex = tabsVm.findTabByFilePath(filePath);
      if (existingTabIndex >= 0) {
        // 如果已经打开，切换到该标签页
        tabsVm.switchToTab(existingTabIndex);
      } else {
        // 如果没有打开，创建新标签页
        // 创建一个新的Book对象
        final fileName = filePath.split(Platform.pathSeparator).last;
        final newBook = Book(
          await FileUtils.calculateFileHash(filePath),
          fileName,
          filePath,
          '', // 封面图片路径为空
          lastReadPage: 1,
          lastReadTime: DateTime.now(),
          totalPages: 0,
          readProgress: 0.0,
          author: '',
          fileFormat: 'PDF',
        );

        // 添加新标签页
        tabsVm.addTab(filePath, newBook);
      }

      // 处理标签页切换
      _handleTabChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    var tabsVm = context.watch<TabsViewModel>();
    var markerVm = context.watch<MarkerViewModel>();
    var drawingProvider = context.watch<DrawingViewModel>();

    // 监听标签页变化
    if (tabsVm.activeTab != null &&
        appState.currentPdfPath != tabsVm.activeTab!.filePath) {
      // 当活动标签页变化时，更新阅读器状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleTabChange();
      });
    }

    return WillPopScope(
      onWillPop: () async {
        // 处理返回事件
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('确认退出'),
            content: const Text('是否要保存并返回到书架？'),
            actions: [
              CupertinoDialogAction(
                child: const Text('取消'),
                onPressed: () =>
                    Navigator.of(context).pop({'action': 'cancel'}),
              ),
              CupertinoDialogAction(
                child: const Text('确认'),
                onPressed: () =>
                    Navigator.of(context).pop({'action': 'confirm'}),
              ),
            ],
          ),
        );

        if (result != null && result['action'] == 'confirm') {
          // 保存当前标签页的状态
          if (appState.currentPdfPath.isNotEmpty) {
            await markerVm.saveArchive(widget.book);
          }
          return true;
        }
        return false;
      },
      child: NotificationListener<TabsNotification>(
        onNotification: (notification) {
          // 处理打开新文件的通知
          _handleNewFileRequest(notification.filePath);
          return true;
        },
        child: Material(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // const TabsBar(),
                    TopBar(),
                    Expanded(
                      child: Row(
                        children: [
                          const LeftSidebar(),
                          if (appState.isSidebarVisible) const SideBar(),
                          Expanded(flex: 3, child: buildViewer()),
                          if (appState.isLeftSidebarVisible) const RSideBar(),
                          const RightSidebar(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildViewer() {
    var appState = context.watch<ReaderViewModel>();
    var markerVm = context.read<MarkerViewModel>();
    final controller = appState.pdfViewerController;
    var tabsVm = context.watch<TabsViewModel>();

    if (kDebugMode) {
      debugPrint('Controller: $controller');
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

    // 大纲列表
    // Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
    //   var appState = context.watch<ReaderViewModel>();
    //   var markerVm = context.read<MarkerViewModel>();

    //   return Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: nodes.map((node) {
    //       final nodeKey = '${node.title}_${indent}';
    //       final isExpanded = appState.outlineExpandedStates[nodeKey] ?? false;

    //       return Column(
    //         mainAxisSize: MainAxisSize.min,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           CupertinoButton(
    //             padding: EdgeInsets.zero,
    //             onPressed: () {
    //               if (node.children.isNotEmpty) {
    //                 // 使用 ViewModel 中的方法来切换状态
    //                 appState.toggleOutlineNode(nodeKey);
    //               }
    //               if (node.dest != null) {
    //                 controller.goToDest(node.dest);
    //               }
    //             },
    //             child: Container(
    //               padding: EdgeInsets.only(
    //                 left: 16 + indent,
    //                 right: 16,
    //                 top: 8,
    //                 bottom: 8,
    //               ),
    //               width: double.infinity,
    //               child: Row(
    //                 children: [
    //                   if (node.children.isNotEmpty)
    //                     Icon(
    //                       isExpanded
    //                           ? PhosphorIconsRegular.caretDown
    //                           : PhosphorIconsRegular.caretRight,
    //                       size: 12,
    //                       color: CupertinoColors.systemGrey,
    //                     ),
    //                   SizedBox(width: node.children.isNotEmpty ? 8 : 0),
    //                   Expanded(
    //                     child: Text(
    //                       node.title ?? '',
    //                       style: const TextStyle(
    //                         color: CupertinoColors.label,
    //                         fontSize: 14,
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //           if (node.children.isNotEmpty && isExpanded)
    //             Padding(
    //               padding: const EdgeInsets.only(left: 0),
    //               child: buildOutlineList(node.children, indent: indent + 20),
    //             ),
    //         ],
    //       );
    //     }).toList(),
    //   );
    // }

    // 添加放大和缩小按钮的方法
    // Widget buildNavigationAndZoomButtons() {
    //   return Positioned(
    //     bottom: 20,
    //     right: 20,
    //     child: Opacity(
    //       opacity: 0.7, // 设置按钮透明度
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Container(
    //             decoration: BoxDecoration(
    //               color: CupertinoColors.systemGrey.withOpacity(0.5),
    //               // borderRadius: BorderRadius.circular(5),
    //             ),
    //             child: CupertinoButton(
    //               padding: const EdgeInsets.all(8.0),
    //               child: const Icon(PhosphorIconsRegular.arrowLeft,
    //                   color: CupertinoColors.white),
    //               onPressed: () {
    //                 appState.goToPreviousPage();
    //               },
    //             ),
    //           ),
    //           Container(
    //             decoration: BoxDecoration(
    //               color: CupertinoColors.systemGrey.withOpacity(0.5),
    //               // borderRadius: BorderRadius.circular(5),
    //             ),
    //             child: CupertinoButton(
    //               padding: const EdgeInsets.all(8.0),
    //               child: const Icon(PhosphorIconsRegular.arrowRight,
    //                   color: CupertinoColors.white),
    //               onPressed: () {
    //                 appState.goToNextPage();
    //               },
    //             ),
    //           ),
    //           Container(
    //             decoration: BoxDecoration(
    //               color: CupertinoColors.systemGrey.withOpacity(0.5),
    //               // borderRadius: BorderRadius.circular(5),
    //             ),
    //             child: CupertinoButton(
    //               padding: const EdgeInsets.all(8.0),
    //               child: const Icon(PhosphorIconsRegular.plus,
    //                   color: CupertinoColors.white),
    //               onPressed: () {
    //                 appState.zoomUp();
    //               },
    //             ),
    //           ),
    //           Container(
    //             decoration: BoxDecoration(
    //               color: CupertinoColors.systemGrey.withOpacity(0.5),
    //               // borderRadius: BorderRadius.circular(5),
    //             ),
    //             child: CupertinoButton(
    //               padding: const EdgeInsets.all(8.0),
    //               child: const Icon(PhosphorIconsRegular.minus,
    //                   color: CupertinoColors.white),
    //               onPressed: () {
    //                 appState.zoomDown();
    //               },
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }

    // appState.pdfViewerController.setZoom(appState.pdfViewerController.centerPosition, zoom);
    Widget buildViewer() {
      var theme = Theme.of(context);
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white,
            appState.darkMode ? BlendMode.difference : BlendMode.dst),
        child: PdfViewer.file(
          appState.currentPdfPath,
          controller: controller,
          params: PdfViewerParams(
            // 基本设置
            backgroundColor: theme.colorScheme.surfaceContainerLow,
            pageDropShadow: const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
            // 页面变化事件
            onViewerReady: (pdfDocument, pdfViewerController) async {
              const margin = 50.0;
              final zoom = (pdfViewerController.viewSize.width - margin * 2) /
                  pdfDocument.pages[0].width;
              pdfViewerController.setZoom(
                  pdfViewerController.centerPosition, zoom);

              // 文档加载完成后，更新标签页信息
              appState.setTotalPages(pdfDocument.pages.length);
              appState.setOutline(await pdfDocument.loadOutline());

              // 更新标签页中的书籍信息
              if (tabsVm.activeTabIndex >= 0) {
                final currentBook = tabsVm.activeTab!.book;
                final updatedBook = currentBook.copyWith(
                  totalPages: pdfDocument.pages.length,
                  readProgress: pdfDocument.pages.length > 0 &&
                          appState.currentPageNumber != null
                      ? appState.currentPageNumber! / pdfDocument.pages.length
                      : 0.0,
                );
                tabsVm.updateTab(tabsVm.activeTabIndex, book: updatedBook);
              }
            },
            // 页面变化事件
            onPageChanged: (pageNumber) {
              if (pageNumber != null) {
                appState.setCurrentPage(pageNumber);

                // 更新标签页中的书籍信息
                if (tabsVm.activeTabIndex >= 0) {
                  final currentBook = tabsVm.activeTab!.book;
                  final updatedBook = currentBook.copyWith(
                    lastReadPage: pageNumber,
                    lastReadTime: DateTime.now(),
                    readProgress: appState.totalPages > 0
                        ? pageNumber / appState.totalPages
                        : 0.0,
                  );
                  tabsVm.updateTab(tabsVm.activeTabIndex, book: updatedBook);
                }
              }
            },
            // 文本选择
            selectableRegionInjector: (context, child) {
              // Your customized SelectionArea
              return SelectionArea(
                selectionControls: CustomTextSelectionControls(markerVm),
                contextMenuBuilder: (context, selectableRegionState) =>
                    const SizedBox.shrink(),
                focusNode: FocusNode(),
                child: child,
              );
            },
            enableTextSelection: true,
            // selectionColor: markerVm.selectionColor,
            onTextSelectionChange: (selections) {
              // 只在高亮工具激活时才处理文本选择
              markerVm.selectedRanges = selections;
            },
            // 绘制回调
            pagePaintCallbacks: [
              appState.textSearcher.pageTextMatchPaintCallback,
              markerVm.paintMarkers,
              // markerVm.paintUnderlines,
              // markerVm.paintSavedHighlights, // 恢复保存的高亮绘制回调
            ],
            // 覆盖层构建器
            viewerOverlayBuilder:
                (BuildContext context, Size size, linkHandler) {
              return [
                Stack(
                  children: [
                    buildScrollBar(),
                    // buildNavigationAndZoomButtons(),
                  ],
                ),
              ];
            },
            // 页面覆盖层构建器
            pageOverlaysBuilder: (context, pageRect, page) {
              return [
                MarkerOverlayBuilder(
                  pageRect: pageRect,
                  page: page,
                  markers: markerVm.archive.markers[page.pageNumber] ?? [],
                  markerVm: markerVm,
                ),
                DrawingOverlay(
                  pageRect: pageRect,
                  page: page,
                  strokes: markerVm.archive.strokes[page.pageNumber] ?? [],
                ),
              ];
            },
            // 链接处理
            linkHandlerParams: PdfLinkHandlerParams(
              onLinkTap: (link) {
                if (link.url != null) {
                  navigateToUrl(link.url!);
                } else if (link.dest != null) {
                  controller.goToDest(link.dest);
                }
              },
            ),
            // 页面布局
            layoutPages: (pages, params) {
              final width =
                  pages.fold(0.0, (prev, page) => max(prev, page.width));
              final pageLayouts = <Rect>[];
              const offset = 0; // 使用第一页作为封面
              double y = params.margin;

              for (int i = 0; i < pages.length; i++) {
                final page = pages[i];

                if (!appState.isDoublePageMode) {
                  // 单页模式
                  pageLayouts.add(
                    Rect.fromLTWH(
                      params.margin,
                      y,
                      page.width,
                      page.height,
                    ),
                  );
                  y += page.height + params.margin;
                  // + params.margin;
                  continue;
                }

                // 双页模式
                final pos = i + offset;
                final isLeft = (pos & 1) == 0;

                final otherSide = (pos ^ 1) - offset;
                final h = 0 <= otherSide && otherSide < pages.length
                    ? max(page.height, pages[otherSide].height)
                    : page.height;

                // 控制每页的 x y 位置（相对位置）
                pageLayouts.add(
                  Rect.fromLTWH(
                    isLeft
                        ? width + params.margin - page.width
                        : params.margin + params.margin / 2.0 + width,
                    y + (h - page.height) / 2,
                    page.width,
                    page.height,
                  ),
                );

                if (pos & 1 == 1 || i + 1 == pages.length) {
                  y += h + params.margin;
                }
              }

              return PdfPageLayout(
                pageLayouts: pageLayouts,
                documentSize: Size(
                  appState.isDoublePageMode
                      ? (params.margin + width) * 2 + params.margin
                      : params.margin * 2 + width,
                  y,
                ),
              );
            },
          ),
        ),
      );
    }

    return buildViewer();
  }

  Future<void> navigateToUrl(Uri url) async {
    if (await shouldOpenUrl(context, url)) {
      await launchUrl(url);
    }
  }

  Future<bool> shouldOpenUrl(BuildContext context, Uri url) async {
    final result = await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Navigate to URL?'),
          content: SelectionArea(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                      text:
                          'Do you want to navigate to the following location?\n'),
                  TextSpan(
                    text: url.toString(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // 处理新文件请求
  void _handleNewFileRequest(String filePath) async {
    var tabsVm = context.read<TabsViewModel>();

    // 检查是否已经打开了该文件
    int existingTabIndex = tabsVm.findTabByFilePath(filePath);
    if (existingTabIndex >= 0) {
      // 如果已经打开，切换到该标签页
      tabsVm.switchToTab(existingTabIndex);
    } else {
      // 如果没有打开，创建新标签页
      // 创建一个新的Book对象
      final fileName = filePath.split(Platform.pathSeparator).last;
      final newBook = Book(
        await FileUtils.calculateFileHash(filePath),
        fileName,
        filePath,
        '', // 封面图片路径为空
        lastReadPage: 1,
        lastReadTime: DateTime.now(),
        totalPages: 0,
        readProgress: 0.0,
        author: '',
        fileFormat: 'PDF',
      );

      // 添加新标签页
      tabsVm.addTab(filePath, newBook);
    }

    // 处理标签页切换
    _handleTabChange();
  }
}
