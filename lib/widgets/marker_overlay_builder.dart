import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../view_models/marker_vm.dart';

class MarkerOverlayBuilder extends StatelessWidget {
  final MarkerVewModel markerVm;
  final Size size;
  final PdfViewerController controller;

  const MarkerOverlayBuilder({
    super.key,
    required this.markerVm,
    required this.size,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('MarkerOverlayBuilder build called');
    debugPrint('Viewer size: $size');
    
    final pageNumber = controller.pageNumber!;
    debugPrint('Current page number: $pageNumber');
    
    final markers = markerVm.getMarkersForPage(pageNumber);
    debugPrint('Markers for page $pageNumber: ${markers?.length ?? 0}');
    
    if (markers == null || markers.isEmpty) {
      debugPrint('No markers found for page $pageNumber');
      return const SizedBox();
    }

    // 获取当前页面的信息
    final page = controller.pages[pageNumber - 1];
    final visibleRect = controller.visibleRect;
    debugPrint('Page rect: $visibleRect');
    debugPrint('Page size: ${visibleRect.size}');
    
    return Stack(
      children: markers.map((marker) {
        if (marker.points.isEmpty) {
          debugPrint('Marker has no points');
          return const SizedBox();
        }

        debugPrint('Processing marker: ${marker.type}, points: ${marker.points}');
        
        // 计算标注在页面中的相对位置
        final rect = Rect.fromLTRB(
          marker.points[0].x as double,
          marker.points[0].y as double,
          marker.points[1].x as double,
          marker.points[1].y as double,
        );
        
        // 使用 toRect 转换坐标
        final adjustedRect = rect;
        // final adjustedRect = rect.toRect(
        //   page: page,
        //   scaledPageSize: visibleRect.size,
        // ).translate(visibleRect.left, visibleRect.top);
        
        debugPrint('Original rect: $rect');
        debugPrint('Adjusted rect: $adjustedRect');

        // 根据标注类型调整点击区域
        Rect hitRect;
        switch (marker.type) {
          case MarkerType.highlight:
            hitRect = adjustedRect;
            break;
          case MarkerType.underline:
            hitRect = Rect.fromLTRB(
              adjustedRect.left,
              adjustedRect.bottom - 10,
              adjustedRect.right,
              adjustedRect.bottom + 10,
            );
            break;
          case MarkerType.strikethrough:
            final midY = (adjustedRect.top + adjustedRect.bottom) / 2;
            hitRect = Rect.fromLTRB(
              adjustedRect.left,
              midY - 10,
              adjustedRect.right,
              midY + 10,
            );
            break;
        }
        debugPrint('Hit rect: $hitRect');

        return Positioned.fromRect(
          rect: hitRect,
          child: GestureDetector(
            onTapDown: (details) {
              debugPrint('Marker tapped at ${details.globalPosition}');
              _showMarkerMenu(
                context,
                details.globalPosition,
                pageNumber,
                marker,
              );
            },
            child: Container(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.withOpacity(0.3)), // 添加边框以便于调试
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showMarkerMenu(BuildContext context, Offset position, int pageNumber, dynamic marker) {
    debugPrint('Showing menu for marker at page $pageNumber, position: $position');
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              debugPrint('Delete marker action pressed');
              Navigator.pop(context);
              markerVm.removeMarker(pageNumber, marker);
            },
            isDestructiveAction: true,
            child: const Text('删除标注'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ),
    );
  }
}
