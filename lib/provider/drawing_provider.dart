import 'package:flutter/material.dart';
import 'package:flowverse/models/stroke.dart';

class DrawingProvider extends ChangeNotifier {
  bool _isDrawingMode = false;
  bool _isEraserMode = false;
  bool _isPenMode = false;
  double _strokeWidth = 2.0;
  double eraserSize = 10.0;
  ShapeType currentShape = ShapeType.rectangle;
  StrokeType _strokeType = StrokeType.pen;

  // Tool tool = PenTool();

  // var shapeType = ShapeType.rectangle;

  bool get isDrawingMode => _isDrawingMode;
  bool get isEraserMode => _isEraserMode;
  bool get isPenMode => _isPenMode;
  double get strokeWidth => _strokeWidth;
  // ShapeType get currentShape => _currentShape;
  StrokeType get strokeType => _strokeType;

  void setStrokeType(StrokeType type) {
    if (_strokeType != type) {
      _strokeType = type;
      notifyListeners();
    }
  }

  void setDrawingMode(bool mode) {
    if (_isDrawingMode != mode) {
      _isDrawingMode = mode;
      if (!_isDrawingMode) {
        _isPenMode = false;
      }
      if (_isDrawingMode) {
        _isEraserMode = false;
      }
      notifyListeners();
    }
  }

  void setEraserMode(bool mode) {
    _isEraserMode = mode;
    if (_isEraserMode) {
      _isDrawingMode = false;
      _isPenMode = false;
    }
    notifyListeners();
  }

  void toggleDrawingMode() {
    _isDrawingMode = !_isDrawingMode;
    if (_isDrawingMode) {
      _isEraserMode = false;
      _isPenMode = false;
    }
    notifyListeners();
  }

  void toggleEraserMode() {
    _isEraserMode = !_isEraserMode;
    if (_isEraserMode) {
      _isDrawingMode = false;
      _isPenMode = false;
    }
    notifyListeners();
  }

  // void setPenMode(bool mode) {
  //   if (_isPenMode != mode) {
  //     _isPenMode = mode;
  //     if (_isPenMode) {
  //       _currentShape = ;
  //     }
  //     notifyListeners();
  //   }
  // }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  // void setShape(ShapeType shape) {
  //   tool = ShapeTool(shape);
  //   notifyListeners();
  //   // final shapeTool = tool as ShapeTool;
  //   // if (shapeTool.shapeType != shape) {
  //   //   shapeTool.shapeType = shape;
  //   //   if (shape != null) {
  //   //     _isPenMode = false;
  //   //   }
  //   //   notifyListeners();
  //   // }
  // }

  // void setTool(Tool tool) {
  //   this.tool = tool;
  //   notifyListeners();
  // }

  void increaseEraserSize() {
    _strokeWidth = (_strokeWidth + 2).clamp(4, 40);
    notifyListeners();
  }

  void decreaseEraserSize() {
    _strokeWidth = (_strokeWidth - 2).clamp(4, 40);
    notifyListeners();
  }
}
