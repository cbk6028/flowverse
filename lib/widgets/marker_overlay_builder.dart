import 'package:flowverse/models/stroke.dart';
import 'package:flowverse/view_models/reader_vm.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../view_models/marker_vm.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MarkerOverlayBuilder extends StatelessWidget {
  final Rect pageRect;
  final PdfPage page;
  final List<Marker> markers;
  final MarkerVewModel markerVm;

  const MarkerOverlayBuilder({
    Key? key,
    required this.pageRect,
    required this.page,
    required this.markers,
    required this.markerVm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Building MarkerOverlayBuilder');
    print('Number of markers: ${markers.length}');
    print('Page rect: $pageRect');
    print('Page number: ${page.pageNumber}');

    if (markers.isEmpty) {
      print('No markers for this page');
      return const SizedBox.shrink(); // 返回空widget而不是尝试访问空列表
    }

    return Stack(
      children: markers.map((marker) {
        // 检查marker.points是否有效
        if (marker.points.length < 2) {
          print('Invalid marker points: ${marker.points}');
          return const SizedBox.shrink();
        }

        // 计算注释的位置和大小
        final rect = PdfRect(
          marker.points[0].x as double,
          marker.points[0].y as double,
          marker.points[1].x as double,
          marker.points[1].y as double,
        );

        print('Marker rect: $rect');
        print('Marker type: ${marker.type}');
        print('Marker paint color: ${marker.paint.color}');

        final scaledRect =
            rect.toRect(page: page, scaledPageSize: pageRect.size);
        print('Scaled rect: $scaledRect');

        return Positioned.fromRect(
          rect: scaledRect,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // 确保即使透明也能接收点击事件
            // onTapDown: (details) {
            //   print('左键点击位置: ${details.globalPosition}');
            //   _showMarkerOptions(context, marker);
            // },
            onSecondaryTapDown: (details) {
              print('右键点击位置: ${details.globalPosition}');
              _showMarkerOptions(context, marker);
            },
            // child: Container(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.red, width: 1), // DEBUG: 显示边框
            //     color: marker.paint.color.withOpacity(0.1), // 增加透明度方便调试
            //   ),
            //   child: Center(
            //     child: Text(
            //       '${marker.type}',
            //       style: TextStyle(color: Colors.red, fontSize: 15),
            //     ),
            //   ),
            // ),
          ),
        );
      }).toList(),
    );
  }

  void _showMarkerOptions(BuildContext context, Marker marker) {
    print('Calculating menu position');
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero, ancestor: overlay);
    print('Menu position: $position');

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - button.size.height - 10, // 将菜单位置上移，距离标记 10 像素
        position.dx + button.size.width,
        position.dy - 10,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(PhosphorIconsLight.trash, color: Colors.red),
              SizedBox(width: 8),
              Text('删除注释'),
            ],
          ),
          onTap: () {
            print('Delete marker tapped');
            markerVm.removeMarker(marker.pageNumber, marker);
            // 强制重建
            if (context.mounted) {
              Future.microtask(() {
                markerVm.notifyListeners();
              });
            }
          },
        ),
      ],
    );
  }
}
