import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/ui/overlay_canvas/vm/handler.dart';
import 'package:flov/ui/overlay_canvas/widgets/text_input_overlay.dart';
import 'package:flov/ui/overlay_canvas/widgets/image_input_overlay.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flov/ui/overlay_canvas/widgets/canvas.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flov/ui/overlay_canvas/vm/drawing_vm.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flov/utils/logger.dart';

part 'lasso.dart';

class DrawingOverlay extends StatefulWidget {
  final Rect pageRect;
  final PdfPage page;
  final List<Stroke> strokes;

  const DrawingOverlay(
      {Key? key,
      required this.pageRect,
      required this.page,
      required this.strokes})
      : super(key: key);

  @override
  State<DrawingOverlay> createState() => _DrawingOverlayState();
}

class _DrawingOverlayState extends State<DrawingOverlay> {
  
  // 使用PDF原始尺寸的比例计算缩放
  double get scale => widget.pageRect.width / widget.page.width;

  @override
  void initState() {
    initToolManager();
    super.initState();
    logger.d('DrawingOverlay: Initializing - Page: ${widget.page.pageNumber}');
  }

  void _initOrUpdateToolManager() {
    final drawingVm = context.read<DrawingViewModel>();
    final toolContext = ToolContext(
      markerVm: context.read<MarkerViewModel>(),
      drawingVm: drawingVm,
    );

    logger.d(
        'DrawingOverlay: Initializing/updating tool manager - Page: ${widget.page.pageNumber}');
    drawingVm.initToolManager(toolContext);
  }

  // Future<void> printText() async {
  //   final PdfPageText pageText = await widget.page.loadText();
  //   for (PdfPageTextFragment i in pageText.fragments) {
  //     logger.v(i.text);
  //   }
  // }

  Future<void> initToolManager() async {
    final drawingVm = context.read<DrawingViewModel>();
    final toolContext = ToolContext(
      // context: context,
      markerVm: context.read<MarkerViewModel>(),
      drawingVm: drawingVm,
    );

    logger.d(
        'DrawingOverlay: Initializing tool manager - Page: ${widget.page.pageNumber}');
    drawingVm.initToolManager(toolContext);
  }

  @override
  void dispose() {
    final drawingVm = context.read<DrawingViewModel>();
    drawingVm.toolManager?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DrawingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果页面发生变化，更新 ToolContext
    if (oldWidget.page.pageNumber != widget.page.pageNumber) {
      logger.i(
          'DrawingOverlay: Page changed from ${oldWidget.page.pageNumber} to ${widget.page.pageNumber}');
      _initOrUpdateToolManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MarkerViewModel>(builder: (context, markerVm, child) {
      // 获取当前页面的笔画
      final pageStrokes =
          markerVm.archive.strokes[widget.page.pageNumber] ?? [];
      logger.t(
          'DrawingOverlay: Building - Page: ${widget.page.pageNumber}, Strokes: ${pageStrokes.length}');

      return Consumer<DrawingViewModel>(
          builder: (context, drawingProvider, child) {
        // print(
        //     'DrawingOverlay: build - drawingMode = ${drawingProvider.isDrawingMode}');
        // print(
        //     'drawingProvider.isDrawingMode  ${drawingProvider.isDrawingMode}');

        // Clear eraser position when not in eraser mode
        // if (!drawingProvider.isEraserMode && _currentEraserPosition != null) {
        //   _currentEraserPosition = null;
        // }

        // 获取当前工具处理器
        final toolHandler = drawingProvider.toolManager?.currentHandler;

        final isTextHandler = toolHandler is TextHandler;
        final textHandler = isTextHandler ? toolHandler : null;
        final isImageHandler = toolHandler is ImageHandler;
        final imageHandler =
            isImageHandler ? toolHandler : null;
        drawingProvider.toolManager?.currentHandler.scale = scale;
        drawingProvider.toolManager?.currentHandler.pageNumber = widget.page.pageNumber;
        
        return Stack(
          children: [
            IgnorePointer(
              ignoring: !drawingProvider.isDrawingMode,
              child: Listener(
                onPointerMove: (event) {
                  // print('onPointerMove');
                  

                  // logger.i('DrawingOverlay: onPointerMove - Scale: $scale');

                  drawingProvider.toolManager?.handlePointerMove(event);
                  setState(() {});
                },
                onPointerHover: (event) {

                  drawingProvider.toolManager?.handlePointerHover(event);
                },
                onPointerDown: (event) {
                  drawingProvider.toolManager?.handlePointerDown(event);
                },
                child: GestureDetector(
                  onPanStart: (details) {
                    drawingProvider.toolManager?.handlePanStart(
                        details, widget.page.pageNumber, scale);
                    setState(() {});
                  },
                  onPanUpdate: (details) {
                    drawingProvider.toolManager?.handlePanUpdate(details);
                    setState(() {});
                  },
                  onPanEnd: (details) {
                    drawingProvider.toolManager?.handlePanEnd(details);
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: CanvasPainter(
                      handler: drawingProvider.toolManager?.currentHandler,
                      strokes: pageStrokes,
                      pageSize: widget.page.size,
                      screenSize: widget.pageRect.size,
                      scale: scale,
                    ),
                    size: widget.pageRect.size,
                  ),
                ),
              ),
            ),
            // 文本输入框
            if (isTextHandler && textHandler != null)
              TextInputOverlay(
                textHandler: textHandler,
                scale: scale,
                onStateChanged: () => setState(() {}),
              ),
            if (isImageHandler && imageHandler != null)
              ImageInputOverlay(
                imageHandler: imageHandler,
                scale: scale,
                onStateChanged: () => setState(() {}),
              ),
          ],
        );
      });
    });
  }
}
