part of 'topbar.dart';

class MarkupButton extends StatelessWidget {
  final MarkerType markerType;
  const MarkupButton({super.key, required this.markerType});

  @override
  Widget build(BuildContext context) {
    return Consumer<MarkerViewModel>(
      builder: (context, markerVm, child) => PopupMenuButton(
        itemBuilder: (BuildContext context) => [
          PopupMenuItem(
            padding: EdgeInsets.zero,
            child: StatefulBuilder(
              builder: (context, setState) => Container(
                width: 200,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    markerType == MarkerType.highlight
                        ? Container()
                        : StrokeWidthSlider(
                            strokeWidth: markerVm.getMarkupWidth(markerType),
                            minWidth: 0.5,
                            maxWidth: 5,
                            divisions: 9,
                            onChanged: (value) {
                              markerVm.setMarkupWidth(markerType, value);
                              setState(() {});
                            },
                          ),
                    const SizedBox(height: 12),
                    // 现有的颜色选择器
                    ColorPicker(
                      onTap: (color) =>
                          markerVm.setMarkupColor(markerType, color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        offset: const Offset(0, 60), // 调整弹出位置偏移量
        tooltip: '',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: Colors.white,
        child: Container(
          margin: const EdgeInsets.all(12.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: markerVm.getMarkupColor(markerType).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            markerVm.getMarkupIcon(markerType),
            color: markerVm.getMarkupColor(markerType),
            size: 20,
          ),
        ),
      ),
    );
  }
}
