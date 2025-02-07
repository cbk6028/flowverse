part of 'topbar.dart';

class DrawingButton extends StatelessWidget {
  final ToolType strokeType;
  final GlobalKey penButtonKey = GlobalKey();
  DrawingButton({super.key, required this.strokeType});

  @override
  Widget build(BuildContext context) {
    return Consumer<DrawingProvider>(
        builder: (context, drawingProvider, child) {
      return CupertinoButton(
        key: penButtonKey,
        padding: const EdgeInsets.all(12.0),
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: drawingProvider.isDrawingMode &&
                    drawingProvider.strokeType == strokeType
                ? drawingProvider.getDrawingColor(strokeType).withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            drawingProvider.getIcon(strokeType),
            color: drawingProvider.isDrawingMode &&
                    drawingProvider.strokeType == strokeType
                ? drawingProvider.getDrawingColor(strokeType)
                : Colors.grey,
            size: 20,
          ),
        ),
        onPressed: () {
          if (drawingProvider.isDrawingMode &&
              drawingProvider.strokeType == strokeType) {
            // 已激活状态：显示设置菜单
            _showMenu(penButtonKey, context,
                _getPopupMenuItem(strokeType, drawingProvider));
          } else {
            // 未激活状态：激活笔工具
            drawingProvider.setStrokeType(strokeType);
            drawingProvider.setDrawingMode(true);
          }
        },
      );
    });
  }
}

void _showMenu(GlobalKey buttonKey, BuildContext context, PopupMenuItem item) {
  final RenderBox? button =
      buttonKey.currentContext?.findRenderObject() as RenderBox?;
  final RenderBox? overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox?;

  if (button != null && overlay != null) {
    final buttonSize = button.size;
    final buttonPosition = button.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy + buttonSize.height,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy + buttonSize.height + 10,
      ),
      color: Colors.white,
      items: [item],
    );
  }
}

PopupMenuItem _getPopupMenuItem(
    ToolType strokeType, DrawingProvider drawingProvider) {
  switch (strokeType) {
    case ToolType.pen:
      return _getPenItem(drawingProvider);
    case ToolType.shape:
      return _getShapeItem(drawingProvider);
    case ToolType.marker:
      return _getMarkerItem(drawingProvider);

    default:
      return PopupMenuItem(
        child: Container(),
      );
  }
}

// 添加设置菜单方法
PopupMenuItem _getPenItem(DrawingProvider drawingProvider) {
  return PopupMenuItem(
    padding: EdgeInsets.zero,
    child: StatefulBuilder(
      builder: (context, setState) => Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 粗细调节
            Text('笔画粗细: ${drawingProvider.penWidth.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12)),
            Slider(
              value: drawingProvider.penWidth,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              onChanged: (value) {
                drawingProvider.setPenWidth(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // 颜色选择器
            ColorPicker(
              onTap: (color) {
                drawingProvider.setPenColor(color);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    ),
  );
}

PopupMenuItem _getMarkerItem(DrawingProvider drawingProvider) {
  return PopupMenuItem(
    padding: EdgeInsets.zero,
    child: StatefulBuilder(
      builder: (context, setState) => Container(
        width: 200,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 粗细调节
            Text('马克笔粗细: ${drawingProvider.markerWidth.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12)),
            Slider(
              value: drawingProvider.markerWidth,
              min: 1.0,
              max: 10.0,
              divisions: 18,
              onChanged: (value) {
                drawingProvider.setMarkerWidth(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // 透明度调节
            Text(
                '透明度: ${(drawingProvider.markerOpacity * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12)),
            Slider(
              value: drawingProvider.markerOpacity,
              min: 0.1,
              max: 0.5,
              divisions: 4,
              onChanged: (value) {
                drawingProvider.setMarkerOpacity(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            // 颜色选择器
            ColorPicker(
              onTap: (color) {
                drawingProvider.setMarkerColor(color);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    ),
  );
}

// 修改形状按钮构建方法
Widget _buildShapeButton(
  DrawingProvider drawingProvider,
  ShapeType shapeType,
  IconData icon,
  StateSetter setState,
) {
  return InkWell(
    onTap: () {
      drawingProvider.setShapeType(shapeType);
      setState(() {});
    },
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: drawingProvider.currentShape == shapeType
            ? drawingProvider.shapeFillColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: drawingProvider.currentShape == shapeType
              ? drawingProvider.shapeFillColor
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: drawingProvider.currentShape == shapeType
            ? drawingProvider.shapeColor
            : Colors.grey,
      ),
    ),
  );
}

PopupMenuItem _getShapeItem(DrawingProvider drawingProvider) {
  return PopupMenuItem(
    padding: EdgeInsets.zero,
    child: StatefulBuilder(
      builder: (context, setState) => Container(
        width: 280,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 添加形状选择
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.rectangle,
                  PhosphorIconsLight.rectangle,
                  setState,
                ),
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.circle,
                  PhosphorIconsLight.circle,
                  setState,
                ),
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.line,
                  PhosphorIconsLight.lineSegment,
                  setState,
                ),
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.arrow,
                  PhosphorIconsLight.arrowRight,
                  setState,
                ),
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.triangle,
                  PhosphorIconsLight.triangle,
                  setState,
                ),
                _buildShapeButton(
                  drawingProvider,
                  ShapeType.star,
                  PhosphorIconsLight.star,
                  setState,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 边框设置
            Text('边框粗细: ${drawingProvider.shapeWidth.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12)),
            Slider(
              value: drawingProvider.shapeWidth,
              min: 0.5,
              max: 10.0,
              divisions: 19,
              onChanged: (value) {
                drawingProvider.setShapeWidth(value);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // 填充透明度设置
            Text(
                '填充透明度: ${(drawingProvider.shapeFillOpacity * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12)),
            Slider(
              value: drawingProvider.shapeFillOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) {
                drawingProvider.setShapeFillOpacity(value);
                setState(() {});
              },
            ),

            const SizedBox(height: 12),

            // 边框颜色选择器
            const Text('边框颜色:', style: TextStyle(fontSize: 12)),
            ColorPicker(
              onTap: (color) {
                drawingProvider.setShapeColor(color);
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // 填充颜色选择器
            const Text('填充颜色:', style: TextStyle(fontSize: 12)),
            ColorPicker(
              onTap: (color) {
                drawingProvider.setShapeFillColor(color);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    ),
  );
}
