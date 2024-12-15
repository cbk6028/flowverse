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

    ObstructingPreferredSizeWidget? buildToolBar() {
      return CupertinoNavigationBar(
        // backgroundColor: Colors.transparent,
        // border: const Border(bodttom: BorderSide(color: Colors.black12)),
        leading: CupertinoButton(
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
            // CupertinoButton(
            //   padding: EdgeInsets.zero,
            //   onPressed: () => appState.printPdf(context),
            //   child: const Icon(CupertinoIcons.printer),
            // ),
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
                // if (kDebugMode) {
                //   debugPrint('selections: ${appState.markerVm.selectedRanges?.isEmpty}');
                // }
                if (appState.markerVm.selectedRanges!.isNotEmpty) {
                  appState.markerVm.applyHighlight();
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
                if (appState.markerVm.selectedRanges!.isNotEmpty) {
                  appState.markerVm.applyUnderline();
                }
              },
            ),
          ],
        ),
      );
    }

    Widget buildViewer() {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Colors.white,
            appState.darkMode ? BlendMode.difference : BlendMode.dst),
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
      navigationBar: buildToolBar(),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Divider(
                  color: Colors.black,
                  thickness: 0.1,
                ),
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
                            // buildZoomButtons(),
                          ],
                        ),
                      ),
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
