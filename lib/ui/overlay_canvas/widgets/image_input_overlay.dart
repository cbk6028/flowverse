import 'package:flov/ui/overlay_canvas/vm/handler.dart';
import 'package:flutter/material.dart';

class ImageInputOverlay extends StatelessWidget {
  final ImageHandler imageHandler;
  final double scale;
  final VoidCallback onStateChanged;

  const ImageInputOverlay({
    super.key,
    required this.imageHandler,
    required this.scale,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!imageHandler.isSelected || imageHandler.imagePosition == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: imageHandler.imagePosition!.dx * scale,
      top: imageHandler.imagePosition!.dy * scale,
      child: _buildImageControls(),
    );
  }

  Widget _buildImageControls() {
    return Container(
      width: imageHandler.imageSize!.width * scale,
      height: imageHandler.imageSize!.height * scale,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 1),
      ),
      child: Stack(
        children: [
          // 调整大小的手柄
          Positioned(
            right: -10,
            bottom: -10,
            child: GestureDetector(
              onPanUpdate: _handleResizeUpdate,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.open_with, size: 12, color: Colors.white),
              ),
            ),
          ),
          // 删除按钮
          Positioned(
            right: -10,
            top: -10,
            child: GestureDetector(
              onTap: () {
                imageHandler.clearImage();
                onStateChanged();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
          // 保存按钮
          Positioned(
            left: -10,
            top: -10,
            child: GestureDetector(
              onTap: () {
                imageHandler.saveImage();
                onStateChanged();
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleResizeUpdate(DragUpdateDetails details) {
    if (imageHandler.imageSize == null) return;

    final newWidth = imageHandler.imageSize!.width + details.delta.dx / scale;
    final newHeight = imageHandler.imageSize!.height + details.delta.dy / scale;
    
    // 保持最小尺寸
    if (newWidth < 20 || newHeight < 20) return;

    final aspectRatio = imageHandler.imageSize!.width / imageHandler.imageSize!.height;
    
    // 保持宽高比
    imageHandler.updateImageSize(Size(newWidth, newWidth / aspectRatio));
    onStateChanged();
  }
}
