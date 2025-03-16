import 'package:flov/domain/models/annotation/underline.dart';
import 'package:flov/domain/models/tool/shape.dart';
import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flov/ui/home/vm/dashboard_vm.dart';
import 'package:flov/ui/overlay_canvas/vm/drawing_vm.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flov/ui/viewer/vm/tabs_vm.dart';
import 'package:flov/ui/viewer/widgets/color_picker.dart';
import 'package:flov/ui/viewer/widgets/stroke_width_slider.dart';
import 'package:flov/ui/viewer/widgets/tabs_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../vm/reader_vm.dart';

part 'drawing.dart';
part 'markup.dart';

class TopBar extends StatefulWidget {
  final underlineButtonKey = GlobalKey();
  final brushButtonKey = GlobalKey();
  final shapeButtonKey = GlobalKey();

  TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final penButtonKey = GlobalKey();
  final markerButtonKey = GlobalKey();
  bool _isToolbarExpanded = false;

  Widget button(
    IconData icon,
    void Function()? onPressed, {
    bool enabled = false,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8.0),
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.blue : Colors.black87,
          size: 18,
        ),
      ),
    );
  }

  void _showMenu(GlobalKey key, BuildContext context, PopupMenuItem item) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: [item],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    var markerVm = context.watch<MarkerViewModel>();
    var drawingProvider = context.watch<DrawingViewModel>();
    var davm = context.watch<DashboardViewModel>();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 43,
        // margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          // borderRadius: BorderRadius.circular(8.0),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.black.withOpacity(0.5),
          //     blurRadius: 4,
    
          //   ),
          // ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // CupertinoButton(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(4.0),
                //     decoration: BoxDecoration(
                //       color: Colors.grey.withOpacity(0.05),
                //       borderRadius: BorderRadius.circular(6),
                //     ),
                //     child: const Icon(
                //       PhosphorIconsRegular.house,
                //       color: Colors.black87,
                //       size: 18,
                //     ),
                //   ),
                //   onPressed: () async {
                //     // 保存标注
                //     await markerVm.saveArchive(appState.currentBook);

                //     // 更新当前书籍信息
                //     davm.updateCurrentBook(
                //         lastReadPage: appState.currentPageNumber!,
                //         lastReadTime: DateTime.now(),
                //         totalPages: appState.totalPages,
                //         readProgress: appState.totalPages > 0
                //             ? appState.currentPageNumber! / appState.totalPages
                //             : 0.0,
                //         currentPdfPath: appState.currentPdfPath);

                //     if (context.mounted) {
                //       Navigator.pop(context);
                //     }
                //   },
                // ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    PhosphorIconsRegular.hand,
                    color: drawingProvider.isHandMode
                        ? Colors.blue
                        : Colors.black87,
                    size: 18,
                  ),
                  onPressed: () {
                    drawingProvider.setHandMode(!drawingProvider.isHandMode);
                    drawingProvider.setDrawingMode(false);
                    drawingProvider.setEraserMode(false);
                  },
                ),
                //
                const MarkupButton(markerType: MarkerType.highlight),
                // underline
                const MarkupButton(markerType: MarkerType.underline),
                // strikethrough
                const MarkupButton(markerType: MarkerType.strikethrough),

                // 绘制
                DrawingButton(
                  strokeType: ToolType.pen,
                ),
                // 荧光笔
                DrawingButton(
                  strokeType: ToolType.marker,
                ),

                // 形状
                DrawingButton(
                  strokeType: ToolType.shape,
                ),
                CupertinoButton(
                  key: penButtonKey,
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.strokeType == ToolType.eraser
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.eraser,
                      color: drawingProvider.strokeType == ToolType.eraser
                          ? Colors.blue
                          : Colors.grey,
                      size: 18,
                    ),
                  ),
                  onPressed: () {
                    if (drawingProvider.strokeType == ToolType.eraser) {
                      // 已激活状态：显示设置菜单
                      _showMenu(penButtonKey, context, PopupMenuItem(
                        child: StatefulBuilder(builder:
                            (BuildContext context, StateSetter setState) {
                          return Container(
                            width: 200,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 粗细调节
                                Text(
                                    '橡皮大小: ${drawingProvider.eraserSize.toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 12)),
                                Slider(
                                  value: drawingProvider.eraserSize,
                                  min: 4,
                                  max: 40,
                                  divisions: 9,
                                  onChanged: (value) {
                                    setState(() {
                                      drawingProvider.setEraserSize(value);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ));
                    } else {
                      // 未激活状态：激活笔工具
                      drawingProvider.setStrokeType(ToolType.eraser);
                    }
                  },
                ),

                // 添加套索按钮
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == ToolType.lasso
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      PhosphorIconsRegular.selection,
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == ToolType.lasso
                          ? Colors.blue
                          : Colors.grey,
                      size: 18,
                    ),
                  ),
                  onPressed: () {
                    drawingProvider.setStrokeType(ToolType.lasso);
                    drawingProvider.setDrawingMode(true);
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    PhosphorIconsRegular.arrowUUpLeft,
                    color: markerVm.canUndo
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                    size: 18,
                  ),
                  onPressed: () {
                    markerVm.undo();
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    PhosphorIconsRegular.arrowUUpRight,
                    color: markerVm.canRedo
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                    size: 18,
                  ),
                  onPressed: () {
                    markerVm.redo();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      // child: Column(
      //   mainAxisSize: MainAxisSize.min,
      //   children: [
      //     // 添加标签页栏

      //     // 浮动工具栏
      //     AnimatedContainer(
      //       duration: const Duration(milliseconds: 200),
      //       height: _isToolbarExpanded ? 43 : 0,
      //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
      //       child: SingleChildScrollView(
      //         physics: const NeverScrollableScrollPhysics(),
      //         child:
      //       ),
      //     ),

      //     // 工具栏切换按钮
      //     // Container(
      //     //   height: 24,
      //     //   decoration: BoxDecoration(
      //     //     color: const Color(0xfff7f7f7), // 与阅读器背景颜色一致
      //     //   ),
      //     //   child: Center(
      //     //     child: GestureDetector(
      //     //       onTap: () {
      //     //         setState(() {
      //     //           _isToolbarExpanded = !_isToolbarExpanded;
      //     //         });
      //     //       },
      //     //       child: Container(
      //     //         width: 80,
      //     //         height: 16,
      //     //         decoration: BoxDecoration(
      //     //           color: Colors.white,
      //     //           borderRadius: BorderRadius.circular(8),
      //     //           border: Border.all(
      //     //             color: Colors.grey.withOpacity(0.5),
      //     //             width: 0.5,
      //     //           ),
      //     //           boxShadow: [
      //     //             BoxShadow(
      //     //               color: Colors.black.withOpacity(0.05),
      //     //               blurRadius: 2,
      //     //               spreadRadius: 0,
      //     //               offset: const Offset(0, 1),
      //     //             ),
      //     //           ],
      //     //         ),
      //     //         child: Center(
      //     //           child: Icon(
      //     //             _isToolbarExpanded
      //     //                 ? PhosphorIconsRegular.caretUp
      //     //                 : PhosphorIconsRegular.caretDown,
      //     //             size: 12,
      //     //             color: Colors.grey,
      //     //           ),
      //     //         ),
      //     //       ),
      //     //     ),
      //     //   ),
      //     // ),
      //   ],
      // ),
    );
  }
}
