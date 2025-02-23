import 'dart:math';

import 'package:flowverse/data/repositories/archive/archive_repository.dart';
import 'package:flowverse/ui/viewer/widgets/bottombar.dart';
import 'package:flowverse/ui/viewer/widgets/rightsidebar.dart';
import 'package:flowverse/ui/viewer/widgets/topbar.dart';
import 'package:flowverse/ui/maker_overlay/vm/marker_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
// import 'package:simple_painter/simple_painter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'custom_text_selection_controls.dart';
import '../../maker_overlay/widgets/marker_overlay_builder.dart';
import '../vm/reader_vm.dart';

import 'sidebar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flowverse/ui/canvas_overlay/widgets/drawing_overlay.dart';
import 'package:flowverse/ui/canvas_overlay/vm/drawing_vm.dart';

class ReaderScreen extends StatelessWidget {
  final String filePath;
  const ReaderScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrawingViewModel()),
        ChangeNotifierProvider(create: (_) => ReaderViewModel()),
        ChangeNotifierProvider(
            create: (_) =>
                MarkerViewModel(archiveRepository: ArchiveRepository())),
      ],
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
  // 添加一个 Map 来跟踪每个节点的展开状态
  // final Map<String, bool> _expandedNodes = {};

  // 加载传递的文件路径
  @override
  void initState() {
    super.initState();
    var appState = context.read<ReaderViewModel>();
    appState.currentPdfPath = widget.selectedFilePath;
    // 设置选中的文件
    if (kDebugMode) {
      debugPrint('selectedFilePath: ${widget.selectedFilePath}');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReaderViewModel>(context, listen: false)
          .setSelectedFile(File(widget.selectedFilePath));
    });
  }

  @override
  void dispose() {
    // 保存高亮
    var markerVm = context.read<MarkerViewModel>();
    markerVm.saveArchive(widget.selectedFilePath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    var markerVm = context.read<MarkerViewModel>();

    return CupertinoPageScaffold(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                TopBar(),
                Expanded(
                  child: Row(
                    children: [
                      LeftSidebar(),
                      if (appState.isSidebarVisible) const SideBar(),
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: buildViewer(),
                            ),
                            BottomBar(),
                          ],
                        ),
                      ),
                      if (appState.isLeftSidebarVisible) const RSideBar(),
                      RightSidebar(),
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

  Widget buildViewer() {
    var appState = context.watch<ReaderViewModel>();
    var markerVm = context.read<MarkerViewModel>();
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

    // 大纲列表
    Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
      var appState = context.watch<ReaderViewModel>();
      var markerVm = context.read<MarkerViewModel>();

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.map((node) {
          final nodeKey = '${node.title}_${indent}';
          final isExpanded = appState.outlineExpandedStates[nodeKey] ?? false;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (node.children.isNotEmpty) {
                    // 使用 ViewModel 中的方法来切换状态
                    appState.toggleOutlineNode(nodeKey);
                  }
                  if (node.dest != null) {
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
                  child: Row(
                    children: [
                      if (node.children.isNotEmpty)
                        Icon(
                          isExpanded
                              ? PhosphorIconsLight.caretDown
                              : PhosphorIconsLight.caretRight,
                          size: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      SizedBox(width: node.children.isNotEmpty ? 8 : 0),
                      Expanded(
                        child: Text(
                          node.title ?? '',
                          style: const TextStyle(
                            color: CupertinoColors.label,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
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

    // 添加放大和缩小按钮的方法
    Widget buildNavigationAndZoomButtons() {
      return Positioned(
        bottom: 20,
        right: 20,
        child: Opacity(
          opacity: 0.7, // 设置按钮透明度
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                  // borderRadius: BorderRadius.circular(5),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(PhosphorIconsLight.arrowLeft,
                      color: CupertinoColors.white),
                  onPressed: () {
                    appState.goToPreviousPage();
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                  // borderRadius: BorderRadius.circular(5),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(PhosphorIconsLight.arrowRight,
                      color: CupertinoColors.white),
                  onPressed: () {
                    appState.goToNextPage();
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                  // borderRadius: BorderRadius.circular(5),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(PhosphorIconsLight.plus,
                      color: CupertinoColors.white),
                  onPressed: () {
                    appState.zoomUp();
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey.withOpacity(0.5),
                  // borderRadius: BorderRadius.circular(5),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(PhosphorIconsLight.minus,
                      color: CupertinoColors.white),
                  onPressed: () {
                    appState.zoomDown();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // appState.pdfViewerController.setZoom(appState.pdfViewerController.centerPosition, zoom);
    Widget buildViewer() {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white,
            appState.darkMode ? BlendMode.difference : BlendMode.dst),
        child: PdfViewer.file(
          appState.selectedFile!.path,
          controller: controller,
          //

          params: PdfViewerParams(
            onViewerReady: (pdfDocument, pdfViewerController) async {
              // 加载保存的高亮
              await markerVm.loadArchive(widget.selectedFilePath);

              const margin = 50.0;
              final zoom = (pdfViewerController.viewSize.width - margin * 2) /
                  pdfDocument.pages[0].width;
              // (viewSize.width - margin * 2) / page.width

              pdfViewerController.setZoom(
                  pdfViewerController.centerPosition, zoom);
            },
            // gnome
            // backgroundColor: const Color(0xfffafafa),
            backgroundColor: const Color(0xfff7f7f7),
            // backgroundColor: const Color.fromARGB(255, 3, 3, 3),
            pageDropShadow: const BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
            selectableRegionInjector: (context, child) {
              // Your customized SelectionArea
              return SelectionArea(
                selectionControls: CustomTextSelectionControls(markerVm),
                contextMenuBuilder: (context, selectableRegionState) =>
                    const SizedBox.shrink(),
                focusNode: FocusNode(),
                // child: EditableText(
                //   controller: appState.textEditingController,
                //   focusNode: FocusNode(),
                //   key: appState.editableTextKey,
                //   style: const TextStyle(),
                //   cursorColor: Colors.blue,
                //   backgroundCursorColor: Colors.grey,)
                child: child,
                // contextMenuBuilder:(context, selectableRegionState) => SizedBox(
                //   height: 0,),
                // contextMenuBuilder: (BuildContext context,
                //     SelectableRegionState selectableRegionState) {
                //   final List<ContextMenuButtonItem> buttonItems = [
                //     ContextMenuButtonItem(
                //         label: '高亮',
                //         onPressed: () {
                //           // selectableRegionState
                //           //     .selectAll(SelectionChangedCause.toolbar);
                //           markerVm.applyMark();
                //         }),
                //     ContextMenuButtonItem(
                //         label: '下划线',
                //         onPressed: () {
                //           markerVm.applyMarkU();
                //           // selectableRegionState
                //           //     .copySelection(SelectionChangedCause.toolbar);
                //         }),
                //     ContextMenuButtonItem(
                //         label: '删除线',
                //         onPressed: () {
                //           markerVm.applyMarkS();
                //           // selectableRegionState
                //           //     .copySelection(SelectionChangedCause.toolbar);
                //         }),
                //   ];
                //   return AdaptiveTextSelectionToolbar.buttonItems(
                //     buttonItems: buttonItems,
                //     anchors: selectableRegionState.contextMenuAnchors,
                //   );
                // },
              );
            },
            enableTextSelection: true,
            // selectionColor: markerVm.selectionColor,
            onTextSelectionChange: (selections) {
              // 只在高亮工具激活时才处理文本选择
              markerVm.selectedRanges = selections;
            },
            pagePaintCallbacks: [
              appState.textSearcher.pageTextMatchPaintCallback,
              markerVm.paintMarkers,
              // markerVm.paintUnderlines,
              // markerVm.paintSavedHighlights, // 恢复保存的高亮绘制回调
            ],
            viewerOverlayBuilder:
                (BuildContext context, Size size, linkHandler) {
              return [
                Stack(
                  children: [
                    buildScrollBar(),
                    buildNavigationAndZoomButtons(),
                  ],
                ),
              ];
            },

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
            //
            // Link handling example
            //
            linkHandlerParams: PdfLinkHandlerParams(
              onLinkTap: (link) {
                if (link.url != null) {
                  navigateToUrl(link.url!);
                } else if (link.dest != null) {
                  controller.goToDest(link.dest);
                }
              },
            ),
            layoutPages: (pages, params) {
              final width =
                  pages.fold(0.0, (prev, page) => max(prev, page.width));
              final pageLayouts = <Rect>[];
              final offset = 0; // 使用第一页作为封面
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
}
