import 'package:flowverse/models/stroke.dart';

enum DrawActionType {
  addStroke,    // 添加笔画
  removeStroke, // 删除笔画
  addMarker,    // 添加标记
  removeMarker, // 删除标记
}

class DrawAction {
  final DrawActionType actionType;
  final int pageNumber;
  final Stroke? stroke;
  final Marker? marker;

  DrawAction({
    required this.actionType,
    required this.pageNumber,
    this.stroke,
    this.marker,
  });
}
