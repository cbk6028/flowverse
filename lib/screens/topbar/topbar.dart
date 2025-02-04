import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/provider/drawing_provider.dart';
import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flowverse/widgets/color_picker.dart';
import 'package:flowverse/widgets/stroke_width_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:typed_data';
// import 'package:flowverse/widgets/select_image.dart';
// import 'package:simple_painter/simple_painter.dart';

import '../../view_models/reader_vm.dart';
import 'package:image_picker/image_picker.dart';

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
    var drawingProvider = context.watch<DrawingProvider>();

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

                // // 绘制
                // DrawingButton(
                //   strokeType: StrokeType.pen,
                // ),
                // // 荧光笔
                // DrawingButton(
                //   strokeType: StrokeType.marker,
                // ),

                // // 形状
                // DrawingButton(
                //   strokeType: StrokeType.shape,
                // ),

                // // 擦除按钮
                // CupertinoButton(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.isEraserMode
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       PhosphorIconsLight.eraser,
                //       color: drawingProvider.isEraserMode
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     drawingProvider.toggleEraserMode();
                //   },
                // ),
                // 在 topbar.dart 中添加橡皮尺寸控制UI
                // PopupMenuButton<double>(
                //   itemBuilder: (context) => [
                //     PopupMenuItem(
                //       child: Column(
                //         children: [
                //           Text(
                //               '橡皮尺寸: ${drawingProvider.strokeWidth.toInt()}px'),
                //           Row(
                //             children: [
                //               IconButton(
                //                 icon: Icon(Icons.remove),
                //                 onPressed: drawingProvider.decreaseEraserSize,
                //               ),
                //               Expanded(
                //                 child: Slider(
                //                   value: drawingProvider.strokeWidth,
                //                   min: 4,
                //                   max: 40,
                //                   onChanged: (v) =>
                //                       drawingProvider.setStrokeWidth(v),
                //                 ),
                //               ),
                //               IconButton(
                //                 icon: Icon(Icons.add),
                //                 onPressed: drawingProvider.increaseEraserSize,
                //               ),
                //             ],
                //           )
                //         ],
                //       ),
                //     )
                //   ],
                // ),

                // // 添加套索按钮
                // CupertinoButton(
                //   padding: const EdgeInsets.all(12.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(8.0),
                //     decoration: BoxDecoration(
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.lasso
                //           ? Colors.blue.withOpacity(0.1)
                //           : Colors.grey.withOpacity(0.1),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Icon(
                //       PhosphorIconsLight.selection,
                //       color: drawingProvider.isDrawingMode &&
                //               drawingProvider.strokeType == StrokeType.lasso
                //           ? Colors.blue
                //           : Colors.grey,
                //       size: 20,
                //     ),
                //   ),
                //   onPressed: () {
                //     drawingProvider.setStrokeType(StrokeType.lasso);
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

  Widget _buildUnderlineStyleButton(
    MarkerViewModel markerVm,
    UnderlineStyle style,
    String tooltip,
    String symbol,
    VoidCallback onUpdate,
  ) {
    final isSelected = markerVm.underlineStyle == style;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          markerVm.setUnderlineStyle(style);
          onUpdate();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? markerVm.underlineColor.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(4),
            border:
                isSelected ? Border.all(color: markerVm.underlineColor) : null,
          ),
          child: Text(
            symbol,
            style: TextStyle(
              color: isSelected ? markerVm.underlineColor : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
