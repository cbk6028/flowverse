import 'package:flowverse/screens/topbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_text_selection_controls.dart';

import '../view_models/reader_vm.dart';

import 'sidebar.dart';

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
  // 添加一个 Map 来跟踪每个节点的展开状态
  final Map<String, bool> _expandedNodes = {};

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
    var appState = context.read<ReaderViewModel>();
    appState.markerVm.saveHighlights(widget.selectedFilePath);
    super.dispose();
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

    // 大纲列表
    Widget buildOutlineList(List<PdfOutlineNode> nodes, {double indent = 0}) {
      var appState = context.watch<ReaderViewModel>();

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
                              ? CupertinoIcons.chevron_down
                              : CupertinoIcons.chevron_right,
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
                  child: const Icon(CupertinoIcons.back,
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
                  child: const Icon(CupertinoIcons.forward,
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
                  child: const Icon(CupertinoIcons.add,
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
                  child: const Icon(CupertinoIcons.minus,
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
            onViewerReady: (pdfDocument, pdfViewerController) {
              // appState.pdfDocument = pdfDocument;
              // appState.pdfViewerController = pdfViewerController;

              // 加载保存的高亮
              appState.markerVm.loadHighlights(widget.selectedFilePath);

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
                selectionControls: CustomTextSelectionControls(appState),
                contextMenuBuilder: (context, selectableRegionState) => const SizedBox.shrink(),
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
                //           appState.markerVm.applyMark();
                //         }),
                //     ContextMenuButtonItem(
                //         label: '下划线',
                //         onPressed: () {
                //           appState.markerVm.applyMarkU();
                //           // selectableRegionState
                //           //     .copySelection(SelectionChangedCause.toolbar);
                //         }),
                //     ContextMenuButtonItem(
                //         label: '删除线',
                //         onPressed: () {
                //           appState.markerVm.applyMarkS();
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
            // selectionColor: appState.markerVm.selectionColor,
            onTextSelectionChange: (selections) {
              // 只在高亮工具激活时才处理文本选择
              // if (appState.topbarVm.isHandSelected == false) {
              appState.markerVm.selectedRanges = selections;
              // appState.markerVm.applyMark(selections);
              // }
            },
            pagePaintCallbacks: [
              appState.textSearcher.pageTextMatchPaintCallback,
              appState.markerVm.paintMarkers,
              // appState.markerVm.paintUnderlines,
              // appState.markerVm.paintSavedHighlights, // 恢复保存的高亮绘制回调
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
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      // navigationBar: buildToolBar(),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // buildToolBar(),
                TopBar(),
                // Divider(
                //   color: Colors.black,
                //   thickness: 0.1,
                // ),
                Expanded(
                  child: Row(
                    children: [
                      LeftSidebar(),
                      if (appState.isSidebarVisible) const SideBar(),
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            buildViewer(),
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
}
