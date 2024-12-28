import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

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
  final GlobalKey brushButtonKey = GlobalKey();
  final GlobalKey underlineButtonKey = GlobalKey();

  bool isHandSelected = true;
  bool isBrushSelected = false;
  bool isUnderlineSelected = false;

  // 添加一个 Map 来跟踪每个节点的展开状态
  final Map<String, bool> _expandedNodes = {};

  // 新增：重置所有工具状态
  void resetToolStates() {
    setState(() {
      isHandSelected = false;
      isBrushSelected = false;
      isUnderlineSelected = false;
    });
    // 同时重置 ViewModel 中的状态
    var appState = Provider.of<ReaderViewModel>(context, listen: false);
    appState.markerVm.isHighlightMode = false;
    appState.markerVm.isUnderlineMode = false;
  }

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

    Widget buildToolBar() {
      var appState = context.watch<ReaderViewModel>();
      return Container(
        color: const Color(0xfff7f7f7),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.all(8.0),
              borderRadius: BorderRadius.circular(8),
              child: const Icon(
                CupertinoIcons.back,
                color: CupertinoColors.systemBlue,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.back_hand_outlined,
                    color: isHandSelected ? CupertinoColors.systemBlue : CupertinoColors.black,
                  ),
                  onPressed: () {
                    resetToolStates();
                    setState(() {
                      isHandSelected = true;
                    });
                  },
                ),
                CupertinoButton(
                  key: brushButtonKey,
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.brush_outlined,
                    color: isBrushSelected 
                        ? appState.markerVm.highlight_color 
                        : CupertinoColors.black,
                  ),
                  onPressed: () async {
                    if (!isBrushSelected) {
                      resetToolStates();
                      setState(() {
                        isBrushSelected = true;
                      });
                      appState.markerVm.isHighlightMode = true;
                    } else {
                      // 显示颜色选择菜单
                      final RenderBox? button = brushButtonKey.currentContext?.findRenderObject() as RenderBox?;
                      final RenderBox? overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;

                      if (button != null && overlay != null) {
                        final buttonSize = button.size;
                        final buttonPosition = button.localToGlobal(Offset.zero);

                        await showMenu(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Colors.white,
                          position: RelativeRect.fromLTRB(
                            buttonPosition.dx,
                            buttonPosition.dy + buttonSize.height,
                            buttonPosition.dx + 200,
                            buttonPosition.dy + buttonSize.height + 200
                          ),
                          items: [
                            PopupMenuItem(
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: 200,
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 笔画样式选择
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.blue),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: 2,
                                              width: 60,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 80,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.blue),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: 4,
                                              width: 60,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // 颜色选择
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        Colors.yellow,
                                        Colors.orange,
                                        Colors.red,
                                        Colors.pink,
                                        Colors.green,
                                        Colors.blue,
                                        Colors.purple,
                                        Colors.brown,
                                        Colors.grey,
                                        Colors.black,
                                      ].map((color) => GestureDetector(
                                        onTap: () {
                                          appState.markerVm.highlight_color = color as MaterialColor;
                                          setState(() {});
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    }
                  },
                ),
                CupertinoButton(
                  key: underlineButtonKey,
                  padding: const EdgeInsets.all(8.0),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    Icons.format_underline_outlined,
                    color: isUnderlineSelected 
                        ? appState.markerVm.underline_color 
                        : CupertinoColors.black,
                  ),
                  onPressed: () async {
                    if (!isUnderlineSelected) {
                      resetToolStates();
                      setState(() {
                        isUnderlineSelected = true;
                      });
                      appState.markerVm.isUnderlineMode = true;
                    } else {
                      final RenderBox? button = underlineButtonKey
                          .currentContext
                          ?.findRenderObject() as RenderBox?;
                      final RenderBox? overlay = Overlay.of(context)
                          .context
                          .findRenderObject() as RenderBox?;

                      if (button != null && overlay != null) {
                        final buttonSize = button.size;
                        final buttonPosition =
                            button.localToGlobal(Offset.zero);

                        await showMenu(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          color: Colors.white,
                          position: RelativeRect.fromLTRB(
                              buttonPosition.dx,
                              buttonPosition.dy + buttonSize.height,
                              buttonPosition.dx + 200,
                              buttonPosition.dy + buttonSize.height + 200),
                          items: [
                            PopupMenuItem(
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: 200,
                                padding: EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 下划线样式选择
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blue),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: 1,
                                              width: 60,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 80,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.blue),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          child: Center(
                                            child: Container(
                                              height: 2,
                                              width: 60,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    // 颜色选择
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        Colors.yellow,
                                        Colors.orange,
                                        Colors.red,
                                        Colors.pink,
                                        Colors.green,
                                        Colors.blue,
                                        Colors.purple,
                                        Colors.brown,
                                        Colors.grey,
                                        Colors.black,
                                      ]
                                          .map((color) => GestureDetector(
                                                onTap: () {
                                                  appState.markerVm
                                                          .underline_color =
                                                      color as MaterialColor;
                                                  appState.markerVm
                                                      .applyUnderline();
                                                  setState(() {});
                                                  Navigator.pop(context);
                                                },
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 2),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.1),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => appState.toggleDarkMode(),
              child: Icon(appState.darkMode
                  ? CupertinoIcons.moon
                  : CupertinoIcons.sun_max),
            ),
          ],
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
          params: PdfViewerParams(
            onViewerReady: (pdfDocument, pdfViewerController) {
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
            enableTextSelection: true,
            onTextSelectionChange: (selections) {
              // print('文本选择变化: $selections');
              // appState.updateTextSelections(selections);
              appState.markerVm.selectedRanges = selections;

              // appState.updateTextSelections(selections);
            },
            pagePaintCallbacks: [
              appState.textSearcher.pageTextMatchPaintCallback,
              appState.markerVm.paintMarkers,
              appState.markerVm.paintUnderlines,
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
                buildToolBar(),
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
