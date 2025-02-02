import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/provider/drawing_provider.dart';
import 'package:flowverse/view_models/marker_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'dart:typed_data';
// import 'package:flowverse/widgets/select_image.dart';
// import 'package:simple_painter/simple_painter.dart';

import '../view_models/reader_vm.dart';

class TopBar extends StatefulWidget {
  final underlineButtonKey = GlobalKey();
  final brushButtonKey = GlobalKey();
  final shapeButtonKey = GlobalKey();

  TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
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
    var markerVm = context.watch<MarkerVewModel>();
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
                  child: const Icon(
                    PhosphorIconsLight.hand,
                    color: Colors.black87,
                    size: 20,
                  ),
                  onPressed: () {
                    drawingProvider.setDrawingMode(false);
                    // drawingProvider.setShape(ShapeType.);
                    drawingProvider.setEraserMode(false);
                  },
                ),
                CupertinoButton(
                  key: widget.brushButtonKey,
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: markerVm.highlightColor.withOpacity(0.1),
                      // ? Colors.blue.withOpacity(0.1)
                      // : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.highlighter,
                      color: markerVm.highlightColor,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    if (false) {
                      // appState.topbarVm.resetToolStates();
                      // appState.topbarVm.isBrushSelected = true;
                      // appState.markerVm.currentMarkerType = MarkerType.highlight;
                    } else {
                      // appState.topbarVm.resetToolStates();
                      // appState.topbarVm.isBrushSelected = true;

                      final RenderBox? button = widget
                          .brushButtonKey.currentContext
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
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                    const SizedBox(height: 12),
                                    ColorPicker(markerVm: markerVm)
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
                // underline
                CupertinoButton(
                  key: widget.underlineButtonKey,
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: markerVm.underlineColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.textUnderline,
                      color: markerVm.underlineColor,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    if (false) {
                      // appState.topbarVm.resetToolStates();
                      // appState.topbarVm.isUnderlineSelected = true;
                      // appState.markerVm.currentMarkerType = MarkerType.underline;
                    } else {
                      // appState.topbarVm.resetToolStates();
                      // appState.topbarVm.isUnderlineSelected = true;

                      final RenderBox? button = widget
                          .underlineButtonKey.currentContext
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
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ColorPicker(markerVm: markerVm),
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
                //
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: markerVm.strikethroughColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.textStrikethrough,
                      color: markerVm.strikethroughColor,
                      size: 20,
                    ),
                  ),
                  onPressed: () async {
                    final RenderBox? button = widget
                        .underlineButtonKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    final RenderBox? overlay = Overlay.of(context)
                        .context
                        .findRenderObject() as RenderBox?;

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
                            buttonPosition.dy + buttonSize.height + 200),
                        items: [
                          PopupMenuItem(
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: 200,
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ColorPicker(markerVm: markerVm),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
                // PopupMenuButton<ShapeType>(
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   color: Colors.white,
                //   elevation: 8,
                //   offset: Offset(0, 10),
                //   itemBuilder: (context) => [
                //     PopupMenuItem(
                //       value: ShapeType.line,
                //       child: Container(
                //         padding: EdgeInsets.symmetric(vertical: 8),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Icon(PhosphorIconsLight.lineSegment, color: Colors.black87),
                //             SizedBox(width: 12),
                //             Text('直线', style: TextStyle(color: Colors.black87)),
                //           ],
                //         ),
                //       ),
                //     ),
                //     PopupMenuItem(
                //       value: ShapeType.rectangle,
                //       child: Container(
                //         padding: EdgeInsets.symmetric(vertical: 8),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Icon(PhosphorIconsLight.rectangle, color: Colors.black87),
                //             SizedBox(width: 12),
                //             Text('矩形', style: TextStyle(color: Colors.black87)),
                //           ],
                //         ),
                //       ),
                //     ),
                //     PopupMenuItem(
                //       value: ShapeType.circle,
                //       child: Container(
                //         padding: EdgeInsets.symmetric(vertical: 8),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Icon(PhosphorIconsLight.circle, color: Colors.black87),
                //             SizedBox(width: 12),
                //             Text('圆形', style: TextStyle(color: Colors.black87)),
                //           ],
                //         ),
                //       ),
                //     ),
                //     PopupMenuItem(
                //       value: ShapeType.arrow,
                //       child: Container(
                //         padding: EdgeInsets.symmetric(vertical: 8),
                //         child: Row(
                //           mainAxisSize: MainAxisSize.min,
                //           children: [
                //             Icon(PhosphorIconsLight.arrowRight, color: Colors.black87),
                //             SizedBox(width: 12),
                //             Text('箭头', style: TextStyle(color: Colors.black87)),
                //           ],
                //         ),
                //       ),
                //     ),
                //   ],
                //   onSelected: (shape) {
                //     drawingProvider.setShape(shape);
                //     drawingProvider.setDrawingMode(true);
                //     // setState(() {});
                //   },
                //   child:
                // 形状
                CupertinoButton(
                  key: widget.shapeButtonKey,
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == StrokeType.shape
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getShapeIcon(drawingProvider.currentShape),
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == StrokeType.shape
                          ? Colors.blue
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    if (drawingProvider.isDrawingMode &&
                        drawingProvider.strokeType == StrokeType.shape) {
                      // 激活状态：弹出菜单
                      final RenderBox? button = widget
                          .shapeButtonKey.currentContext
                          ?.findRenderObject() as RenderBox?;
                      final RenderBox? overlay = Overlay.of(context)
                          .context
                          .findRenderObject() as RenderBox?;

                      if (button != null && overlay != null) {
                        final buttonSize = button.size;
                        final buttonPosition =
                            button.localToGlobal(Offset.zero);

                        showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            buttonPosition.dx,
                            buttonPosition.dy + buttonSize.height,
                            buttonPosition.dx + buttonSize.width,
                            buttonPosition.dy + buttonSize.height + 10,
                          ),
                          color: Colors.black87,
                          items: [
                            const PopupMenuItem(
                              value: ShapeType.line,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.lineSegment,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('直线',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ShapeType.rectangle,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.rectangle,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('矩形',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ShapeType.circle,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.circle,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('圆形',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ShapeType.arrow,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.arrowRight,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('箭头',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ShapeType.triangle,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.triangle,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('三角形',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: ShapeType.star,
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsLight.star,
                                      color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('五角星',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ).then((selectedShape) {
                          if (selectedShape != null) {
                            drawingProvider.currentShape = selectedShape;
                            // drawingProvider.setTool(
                            //     ShapeTool(drawingProvider.currentShape));
                            drawingProvider.setDrawingMode(true);
                            setState(() {});
                          }
                        });
                      }
                    } else {
                      // 未激活状态：设置当前图形并激活按钮
                      // drawingProvider.setShape(ShapeType.rectangle);
                      drawingProvider.setStrokeType(StrokeType.shape);
                      drawingProvider.setDrawingMode(true);
                      // setState(() {});
                    }
                  },
                ),
                // ),
                // 自由绘制按钮
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == StrokeType.pen
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.pen,
                      color: drawingProvider.isDrawingMode &&
                              drawingProvider.strokeType == StrokeType.pen
                          ? Colors.blue
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    drawingProvider.setStrokeType(StrokeType.pen);
                    drawingProvider.setDrawingMode(true);
                  },
                ),
                // 擦除按钮
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.isEraserMode
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.eraser,
                      color: drawingProvider.isEraserMode
                          ? Colors.blue
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    drawingProvider.toggleEraserMode();
                  },
                ),
                // 在 topbar.dart 中添加橡皮尺寸控制UI
                PopupMenuButton<double>(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Column(
                        children: [
                          Text(
                              '橡皮尺寸: ${drawingProvider.strokeWidth.toInt()}px'),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: drawingProvider.decreaseEraserSize,
                              ),
                              Expanded(
                                child: Slider(
                                  value: drawingProvider.strokeWidth,
                                  min: 4,
                                  max: 40,
                                  onChanged: (v) =>
                                      drawingProvider.setStrokeWidth(v),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: drawingProvider.increaseEraserSize,
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
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
                // 添加套索按钮
                CupertinoButton(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: drawingProvider.isDrawingMode && 
                             drawingProvider.strokeType == StrokeType.lasso
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      PhosphorIconsLight.selection,
                      color: drawingProvider.isDrawingMode && 
                             drawingProvider.strokeType == StrokeType.lasso
                          ? Colors.blue
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    drawingProvider.setStrokeType(StrokeType.lasso);
                    drawingProvider.setDrawingMode(true);
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

  IconData _getShapeIcon(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.line:
        return PhosphorIconsLight.lineSegment;
      case ShapeType.rectangle:
        return PhosphorIconsLight.rectangle;
      case ShapeType.circle:
        return PhosphorIconsLight.circle;
      case ShapeType.arrow:
        return PhosphorIconsLight.arrowRight; // 在 _getShapeIcon 中添加图标映射
      case ShapeType.triangle:
        return PhosphorIconsLight.triangle;
      case ShapeType.star:
        return PhosphorIconsLight.star;
      default:
        return PhosphorIconsLight.rectangle;
    }
  }
}

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.markerVm});

  final MarkerVewModel markerVm;

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
                  markerVm.strikethroughColor = color as MaterialColor;
                  // setState(() {});
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
