part of 'drawing_overlay.dart';

// // 控制点类型
enum ControlPoint { topLeft, topRight, bottomLeft, bottomRight, rotate }

/// 套索选择管理类
class LassoSelection {
  /// 选中的笔画列表
  List<Stroke> selectedStrokes = [];

  /// 选择框矩形
  Rect? selectionRect;

  /// 套索路径
  Path? lassoPath;

  /// 是否正在拖动选择框
  bool isDraggingSelection = false;

  /// 拖动起始点
  Offset? dragStartOffset;

  /// 存储选中笔画的原始位置
  List<Offset> originalPositions = [];

  /// 旋转角度
  double rotationAngle = 0.0;

  /// 旋转中心点
  Offset? rotationCenter;

  /// 最后一次变换的焦点
  Offset? lastFocalPoint;

  /// 当前活动的控制点
  ControlPoint? activeControlPoint;

  /// 处理变换操作
  void handleTransform(Offset currentPoint) {
    if (selectionRect == null || activeControlPoint == null) return;

    final center = selectionRect!.center;
    final originalRect = selectionRect!;

    switch (activeControlPoint) {
      case ControlPoint.rotate:
        final originalAngle = (center - lastFocalPoint!).direction;
        final newAngle = (center - currentPoint).direction;
        rotationAngle += (newAngle - originalAngle);
        lastFocalPoint = currentPoint;
        break;

      case ControlPoint.topLeft:
      case ControlPoint.topRight:
      case ControlPoint.bottomLeft:
      case ControlPoint.bottomRight:
        final dx = currentPoint.dx - lastFocalPoint!.dx;
        final dy = currentPoint.dy - lastFocalPoint!.dy;

        double newLeft = originalRect.left;
        double newTop = originalRect.top;
        double newWidth = originalRect.width;
        double newHeight = originalRect.height;

        switch (activeControlPoint) {
          case ControlPoint.topLeft:
            newLeft += dx;
            newTop += dy;
            newWidth -= dx;
            newHeight -= dy;
            break;
          case ControlPoint.topRight:
            newTop += dy;
            newWidth += dx;
            newHeight -= dy;
            break;
          case ControlPoint.bottomLeft:
            newLeft += dx;
            newWidth -= dx;
            newHeight += dy;
            break;
          case ControlPoint.bottomRight:
            newWidth += dx;
            newHeight += dy;
            break;
          default:
            break;
        }

        // 确保矩形不会太小
        if (newWidth > 20 && newHeight > 20) {
          selectionRect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
        }
        lastFocalPoint = currentPoint;
        break;
      default:
        break;
    }
  }

  /// 处理旋转操作
  void handleRotation(Offset currentPoint) {
    if (selectionRect == null || rotationCenter == null) {
      // 第一次点击时，设置旋转中心点
      rotationCenter = Offset(
        selectionRect!.left + selectionRect!.width / 2,
        selectionRect!.top + selectionRect!.height / 2,
      );
      return;
    }

    // 计算旋转角度
    final previousAngle = atan2(
      dragStartOffset!.dy - rotationCenter!.dy,
      dragStartOffset!.dx - rotationCenter!.dx,
    );
    final currentAngle = atan2(
      currentPoint.dy - rotationCenter!.dy,
      currentPoint.dx - rotationCenter!.dx,
    );
    final deltaAngle = currentAngle - previousAngle;

    rotationAngle += deltaAngle;

    // 旋转所有选中的笔画
    _rotateStrokes(deltaAngle);
  }

  // 旋转笔画
  void _rotateStrokes(double angle) {
    if (selectionRect == null ||
        selectedStrokes.isEmpty ||
        rotationCenter == null) return;

    final cosAngle = cos(angle);
    final sinAngle = sin(angle);

    for (var stroke in selectedStrokes) {
      for (var i = 0; i < stroke.points.length; i++) {
        final point = stroke.points[i];
        final dx = point.x - rotationCenter!.dx;
        final dy = point.y - rotationCenter!.dy;

        // 应用旋转变换
        final newX = dx * cosAngle - dy * sinAngle + rotationCenter!.dx;
        final newY = dx * sinAngle + dy * cosAngle + rotationCenter!.dy;

        stroke.points[i] = Point(newX, newY);
      }
    }

    // 更新选择框
    calculateSelectionRect();
  }

  /// 开始变换操作
  void startTransform(Offset point, ControlPoint pointType) {
    activeControlPoint = pointType;
    lastFocalPoint = point;
    dragStartOffset = point;
    originalPositions = selectedStrokes
        .expand((stroke) => stroke.points)
        .map((p) => Offset(p.x.toDouble(), p.y.toDouble()))
        .toList();
  }

  /// 结束变换操作
  void endTransform() {
    activeControlPoint = null;
    lastFocalPoint = null;
    dragStartOffset = null;
    originalPositions.clear();
  }

  /// 判断点击位置是否在控制点上
  ControlPoint? getControlPoint(Rect selectionRect, Offset position) {
    if (selectionRect == null) return null;

    final points = {
      ControlPoint.topLeft: selectionRect.topLeft,
      ControlPoint.topRight: selectionRect.topRight,
      ControlPoint.bottomLeft: selectionRect.bottomLeft,
      ControlPoint.bottomRight: selectionRect.bottomRight,
      ControlPoint.rotate: Offset(
        selectionRect.center.dx,
        selectionRect.top - 30,
      ),
    };

    for (var entry in points.entries) {
      if ((position - entry.value).distance < 20) {
        return entry.key;
      }
    }
    return null;
  }

  /// 判断笔画是否在套索路径内
  bool isStrokeInLassoPath(Stroke stroke, Path lassoPath) {
    for (final point in stroke.points) {
      final offset = Offset(point.x as double, point.y as double);
      if (lassoPath.contains(offset)) {
        return true;
      }
    }
    return false;
  }

  /// 检查点是否在选择框上
  bool isPointOnSelectionRect(Offset point) {
    if (selectionRect == null) return false;

    // 扩大点击区域到20像素，与控制点检测保持一致
    final expandedRect = Rect.fromLTRB(
      selectionRect!.left - 20,
      selectionRect!.top - 20,
      selectionRect!.right + 20,
      selectionRect!.bottom + 20,
    );

    // 首先检查是否在控制点上
    if (getControlPoint(selectionRect!, point) != null) {
      return false;
    }

    return expandedRect.contains(point);
  }

  /// 计算选中笔画的边界矩形
  void calculateSelectionRect() {
    if (selectedStrokes.isEmpty) {
      selectionRect = null;
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (var stroke in selectedStrokes) {
      for (var point in stroke.points) {
        minX = minX < point.x ? minX : point.x.toDouble();
        minY = minY < point.y ? minY : point.y.toDouble();
        maxX = maxX > point.x ? maxX : point.x.toDouble();
        maxY = maxY > point.y ? maxY : point.y.toDouble();
      }
    }

    selectionRect = Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// 移动选中的笔画
  void moveSelectedStrokes(Offset delta) {
    if (selectedStrokes.isEmpty) return;

    for (var stroke in selectedStrokes) {
      for (var i = 0; i < stroke.points.length; i++) {
        var point = stroke.points[i];
        stroke.points[i] = Point(
          point.x + delta.dx,
          point.y + delta.dy,
        );
      }
    }

    // 更新选择框位置
    if (selectionRect != null) {
      selectionRect = selectionRect!.translate(delta.dx, delta.dy);
    }
  }

  /// 清除选择
  void clearSelection() {
    selectedStrokes.clear();
    selectionRect = null;
    lassoPath = null;
    isDraggingSelection = false;
    dragStartOffset = null;
    originalPositions.clear();
  }

  /// 处理控制点拖动
  void handleControlPointDrag(ControlPoint controlPoint, Offset point) {
    if (selectionRect == null) return;

    final delta = point - dragStartOffset!;
    dragStartOffset = point;

    switch (controlPoint) {
      case ControlPoint.topLeft:
        selectionRect = Rect.fromLTRB(
          selectionRect!.left + delta.dx,
          selectionRect!.top + delta.dy,
          selectionRect!.right,
          selectionRect!.bottom,
        );
        break;
      case ControlPoint.topRight:
        selectionRect = Rect.fromLTRB(
          selectionRect!.left,
          selectionRect!.top + delta.dy,
          selectionRect!.right + delta.dx,
          selectionRect!.bottom,
        );
        break;
      case ControlPoint.bottomLeft:
        selectionRect = Rect.fromLTRB(
          selectionRect!.left + delta.dx,
          selectionRect!.top,
          selectionRect!.right,
          selectionRect!.bottom + delta.dy,
        );
        break;
      case ControlPoint.bottomRight:
        selectionRect = Rect.fromLTRB(
          selectionRect!.left,
          selectionRect!.top,
          selectionRect!.right + delta.dx,
          selectionRect!.bottom + delta.dy,
        );
        break;
      default:
        break;
    }
  }

  /// 处理套索结束
  void handleLassoEnd(List<Stroke> pageStrokes) {
    if (lassoPath == null) return;

    // 闭合套索路径
    lassoPath!.close();

    // 选择在套索区域内的笔画
    selectedStrokes.clear();

    for (final stroke in pageStrokes) {
      if (isStrokeInLassoPath(stroke, lassoPath!)) {
        selectedStrokes.add(stroke);
      }
    }

    if (selectedStrokes.isNotEmpty) {
      // 计算选中笔画的边界矩形
      calculateSelectionRect();
    }

    // 清理套索路径
    lassoPath = null;
  }

  /// 更新套索路径
  void updateLassoPath(Offset point) {
    if (lassoPath != null) {
      lassoPath!.lineTo(point.dx, point.dy);
    }
  }

  /// 根据选择框的变化调整笔画大小
  void resizeStrokes() {
    if (selectionRect == null ||
        selectedStrokes.isEmpty ||
        originalPositions.isEmpty) return;

    // 计算选择框的缩放比例
    final originalRect = Rect.fromPoints(
      originalPositions.reduce((a, b) => Offset(
            min(a.dx, b.dx),
            min(a.dy, b.dy),
          )),
      originalPositions.reduce((a, b) => Offset(
            max(a.dx, b.dx),
            max(a.dy, b.dy),
          )),
    );

    final scaleX = selectionRect!.width / originalRect.width;
    final scaleY = selectionRect!.height / originalRect.height;

    // 更新所有选中笔画的点
    int positionIndex = 0;
    for (var stroke in selectedStrokes) {
      for (var i = 0; i < stroke.points.length; i++) {
        if (positionIndex >= originalPositions.length) break;

        final originalPos = originalPositions[positionIndex];
        final relativeX = originalPos.dx - originalRect.left;
        final relativeY = originalPos.dy - originalRect.top;

        stroke.points[i] = Point(
          selectionRect!.left + relativeX * scaleX,
          selectionRect!.top + relativeY * scaleY,
        );

        positionIndex++;
      }
    }
  }
}
