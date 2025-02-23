import 'package:flowverse/domain/models/action/draw_action.dart';
import 'package:flowverse/domain/models/archive/archive.dart';

class Action {
  List<DrawAction> undoStack;
  List<DrawAction> redoStack;

  Action({
    List<DrawAction>? undoStack,
    List<DrawAction>? redoStack,
  })  : undoStack = undoStack ?? [],
        redoStack = redoStack ?? [];

  void undo(Archive archive) {
    if (undoStack.isEmpty) return;

    final action = undoStack.removeLast();
    redoStack.add(action);

    switch (action.actionType) {
      case DrawActionType.addStroke:
        // 撤销添加操作，需要删除笔画
        if (action.stroke != null) {
          archive.strokes[action.pageNumber]?.remove(action.stroke);
          if (archive.strokes[action.pageNumber]?.isEmpty ?? false) {
            archive.strokes.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.removeStroke:
        // 撤销删除操作，需要添加笔画
        if (action.stroke != null) {
          if (!archive.strokes.containsKey(action.pageNumber)) {
            archive.strokes[action.pageNumber] = [];
          }
          archive.strokes[action.pageNumber]!.add(action.stroke!);
        }
        break;
      case DrawActionType.addMarker:
        // 撤销添加标记操作，需要删除标记
        if (action.marker != null) {
          archive.markers[action.pageNumber]?.remove(action.marker);
          if (archive.markers[action.pageNumber]?.isEmpty ?? false) {
            archive.markers.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.removeMarker:
        // 撤销删除标记操作，需要添加标记
        if (action.marker != null) {
          if (!archive.markers.containsKey(action.pageNumber)) {
            archive.markers[action.pageNumber] = [];
          }
          archive.markers[action.pageNumber]!.add(action.marker!);
        }
        break;
    }
  }


   void redo(Archive archive) {
    if (redoStack.isEmpty) return;

    final action = redoStack.removeLast();
    undoStack.add(action);

    switch (action.actionType) {
      case DrawActionType.addStroke:
        // 重做添加操作，需要添加笔画
        if (action.stroke != null) {
          if (!archive.strokes.containsKey(action.pageNumber)) {
            archive.strokes[action.pageNumber] = [];
          }
          archive.strokes[action.pageNumber]!.add(action.stroke!);
        }
        break;
      case DrawActionType.removeStroke:
        // 重做删除操作，需要删除笔画
        if (action.stroke != null) {
          archive.strokes[action.pageNumber]?.remove(action.stroke);
          if (archive.strokes[action.pageNumber]?.isEmpty ?? false) {
            archive.strokes.remove(action.pageNumber);
          }
        }
        break;
      case DrawActionType.addMarker:
        // 重做添加标记操作，需要添加标记
        if (action.marker != null) {
          if (!archive.markers.containsKey(action.pageNumber)) {
            archive.markers[action.pageNumber] = [];
          }
          archive.markers[action.pageNumber]!.add(action.marker!);
        }
        break;
      case DrawActionType.removeMarker:
        // 重做删除标记操作，需要删除标记
        if (action.marker != null) {
          archive.markers[action.pageNumber]?.remove(action.marker);
          if (archive.markers[action.pageNumber]?.isEmpty ?? false) {
            archive.markers.remove(action.pageNumber);
          }
        }
        break;
    }
  }

}
