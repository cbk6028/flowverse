import 'package:flowverse/domain/models/annotation/underline.dart';
import 'package:flowverse/domain/models/tool/shape.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';
import 'package:flowverse/ui/canvas_overlay/vm/drawing_vm.dart';
import 'package:flowverse/ui/maker_overlay/vm/marker_vm.dart';
import 'package:flowverse/ui/viewer/widgets/color_picker.dart';
import 'package:flowverse/ui/viewer/widgets/stroke_width_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:flowverse/widgets/select_image.dart';
// import 'package:simple_painter/simple_painter.dart';

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

  Widget button(
    IconData icon,
    void Function()? onPressed, {
    bool enabled = false,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.blue : Colors.black87,
          size: 20,
        ),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<ReaderViewModel>();
    var markerVm = context.watch<MarkerViewModel>();
    var drawingProvider = context.watch<DrawingViewModel>();

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      PhosphorIconsLight.house,
                      color: Colors.black87,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    await markerVm.saveArchive(appState.currentPdfPath);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    PhosphorIconsLight.hand,
                    color: drawingProvider.isHandMode
                        ? Colors.blue
                        : Colors.black87,
                    size: 20,
                  ),
                  onPressed: () {
                    drawingProvider.setHandMode(!drawingProvider.isHandMode);
                    drawingProvider.setDrawingMode(false);
                    // drawingProvider.setShape(ShapeType.);
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
                // DrawingButton(
                //   strokeType: ToolType.marker,
                // ),

                // 形状
                // DrawingButton(
                //   strokeType: ToolType.shape,
                // ),
                // CupertinoButton(
                //   key: penButtonKey,
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.strokeType == ToolType.eraser
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       PhosphorIconsLight.eraser,
                //       color: drawingProvider.strokeType == ToolType.eraser
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     if (drawingProvider.strokeType == ToolType.eraser) {
                //       // 已激活状态：显示设置菜单
                //       _showMenu(penButtonKey, context, PopupMenuItem(
                //         child: StatefulBuilder(builder:
                //             (BuildContext context, StateSetter setState) {
                //           return Container(
                //             width: 200,
                //             padding: const EdgeInsets.all(8),
                //             child: Column(
                //               mainAxisSize: MainAxisSize.min,
                //               children: [
                //                 // 粗细调节
                //                 Text(
                //                     '橡皮大小: ${drawingProvider.eraserSize.toStringAsFixed(1)}',
                //                     style: const TextStyle(fontSize: 12)),
                //                 Slider(
                //                   value: drawingProvider.eraserSize,
                //                   min: 4,
                //                   max: 40,
                //                   divisions: 9,
                //                   onChanged: (value) {
                //                     setState(() {
                //                       drawingProvider.setEraserSize(value);
                //                     });
                //                   },
                //                 ),
                //                 // const SizedBox(height: 12),
                //                 // 颜色选择器
                //                 // const ColorPicker(),
                //               ],
                //             ),
                //           );
                //         }),
                //       ));
                //     } else {
                //       // 未激活状态：激活笔工具
                //       // drawingProvider.toggleEraserMode();
                //       drawingProvider.setStrokeType(ToolType.eraser);
                //     }
                //   },
                // ),

                // // 添加套索按钮
                // CupertinoButton(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == ToolType.lasso
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       PhosphorIconsLight.selection,
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == ToolType.lasso
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     drawingProvider.setStrokeType(ToolType.lasso);
                //     drawingProvider.setDrawingMode(true);
                //   },
                // ),
                // 在工具栏按钮组中添加打字机按钮
                // CupertinoButton(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.text
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       PhosphorIconsLight.textT,
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.text
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     drawingProvider.setStrokeType(StrokeType.text);
                //     drawingProvider.setDrawingMode(true);
                //   },
                // ),

                // // 在工具栏按钮组中添加插入图片按钮
                // CupertinoButton(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.image
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       Icons.image,
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.image
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () async {
                //     // 使用 image_picker 选择图片
                //     final ImagePicker picker = ImagePicker();
                //     final XFile? image =
                //         await picker.pickImage(source: ImageSource.gallery);

                //     if (image != null) {
                //       drawingProvider.setImagePath(image.path);
                //       drawingProvider.setStrokeType(StrokeType.image);
                //       drawingProvider.setDrawingMode(true);
                //     }
                //   },
                // ),
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    PhosphorIconsLight.arrowUUpLeft,
                    color: markerVm.canUndo
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    markerVm.undo();
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Icon(
                    PhosphorIconsLight.arrowUUpRight,
                    color: markerVm.canRedo
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey,
                    size: 20,
                  ),
                  onPressed: () {
                    markerVm.redo();
                  },
                ),
              ],
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => appState.toggleDarkMode(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        appState.darkMode
                            ? PhosphorIconsLight.moon
                            : PhosphorIconsLight.sun,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
