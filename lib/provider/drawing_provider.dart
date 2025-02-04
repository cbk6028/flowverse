import 'package:flutter/material.dart';
import 'package:flowverse/models/stroke.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DrawingProvider extends ChangeNotifier {
  bool _isDrawingMode = false;
  bool _isEraserMode = false;
  bool _isPenMode = false;
  double _strokeWidth = 2.0;
  double eraserSize = 10.0;
  ShapeType currentShape = ShapeType.rectangle;
  StrokeType _strokeType = StrokeType.pen;
  Color _markerColor = Colors.yellow;
  double _markerOpacity = 0.3;
  String? _imagePath;
  Size? _imageSize;

  // Tool tool = PenTool();

  // var shapeType = ShapeType.rectangle;

  // 笔的属性
  Color _penColor = Colors.blue;
  double _penWidth = 2.0;

  // 马克笔的属性
  double _markerWidth = 4.0;

  // 形状的属性
  Color _shapeColor = Colors.blue;
  double _shapeWidth = 2.0;
  Color _shapeFillColor = Colors.blue;
  double _shapeFillOpacity = 0.3;
  bool _isHandMode = true;

  bool get isDrawingMode => _isDrawingMode;
  bool get isEraserMode => _isEraserMode;
  bool get isPenMode => _isPenMode;
  double get strokeWidth => _strokeWidth;
  StrokeType get strokeType => _strokeType;
  Color get markerColor => _markerColor;
  double get markerOpacity => _markerOpacity;
  String? get imagePath => _imagePath;
  Size? get imageSize => _imageSize;

  // getter
  Color get penColor => _penColor;
  double get penWidth => _penWidth;
  double get markerWidth => _markerWidth;
  Color get shapeColor => _shapeColor;
  double get shapeWidth => _shapeWidth;
  Color get shapeFillColor => _shapeFillColor;
  double get shapeFillOpacity => _shapeFillOpacity;

  bool get isHandMode => _isHandMode;
  // ShapeType get currentShape => _currentShape;

  void setStrokeType(StrokeType type) {
    if (_strokeType != type) {
      _strokeType = type;
      notifyListeners();
    }
  }

  void setDrawingMode(bool mode) {
    if (_isDrawingMode != mode) {
      _isDrawingMode = mode;
      if (_isDrawingMode) {
        // _isPenMode = false;
        _isEraserMode = false;
        _isHandMode = false;
      }

      notifyListeners();
    }
  }

  void setEraserMode(bool mode) {
    _isEraserMode = mode;
    if (_isEraserMode) {
      _isDrawingMode = false;
      _isPenMode = false;
      _isHandMode = false;
    }
    notifyListeners();
  }

  void toggleDrawingMode() {
    _isDrawingMode = !_isDrawingMode;
    if (_isDrawingMode) {
      _isEraserMode = false;
      _isPenMode = false;
      _isHandMode = false;
    }
    notifyListeners();
  }

  void toggleEraserMode() {
    _isEraserMode = !_isEraserMode;
    if (_isEraserMode) {
      _isDrawingMode = false;
      _isPenMode = false;
      _isHandMode = false;
    }
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  void increaseEraserSize() {
    _strokeWidth = (_strokeWidth + 2).clamp(4, 40);
    notifyListeners();
  }

  void decreaseEraserSize() {
    _strokeWidth = (_strokeWidth - 2).clamp(4, 40);
    notifyListeners();
  }

  void setMarkerColor(Color color) {
    _markerColor = color;
    notifyListeners();
  }

  void setMarkerOpacity(double opacity) {
    _markerOpacity = opacity;
    notifyListeners();
  }

  void setImagePath(String path) async {
    _imagePath = path;
    // 获取图片尺寸
    final image = await decodeImageFromList(File(path).readAsBytesSync());
    _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    notifyListeners();
  }

  void clearImage() {
    _imagePath = null;
    _imageSize = null;
    notifyListeners();
  }

  // setter
  void setPenColor(Color color) {
    _penColor = color;
    notifyListeners();
  }

  void setPenWidth(double width) {
    _penWidth = width;
    notifyListeners();
  }

  void setMarkerWidth(double width) {
    _markerWidth = width;
    notifyListeners();
  }

  void setShapeColor(Color color) {
    _shapeColor = color;
    notifyListeners();
  }

  void setShapeWidth(double width) {
    _shapeWidth = width;
    notifyListeners();
  }

  void setShapeType(ShapeType type) {
    currentShape = type;
    notifyListeners();
  }

  void setShapeFillColor(Color color) {
    _shapeFillColor = color;
    notifyListeners();
  }

  void setShapeFillOpacity(double opacity) {
    _shapeFillOpacity = opacity;
    notifyListeners();
  }

  void setHandMode(bool bool) {
    _isHandMode = bool;
    if (_isHandMode) {
      _isDrawingMode = false;
      _isEraserMode = false;
    }
    notifyListeners();
  }

  getDrawingColor(StrokeType strokeType) {
    switch (strokeType) {
      case StrokeType.pen:
        return _penColor;
      case StrokeType.marker:
        return _markerColor;
      case StrokeType.shape:
        return _shapeColor;
      default:
        return Colors.black;
    }
  }

  IconData _getShapeIcon(ShapeType shapeType) {
    switch (shapeType) {
      case ShapeType.line:
        return PhosphorIconsLight.lineSegment;
      case ShapeType.rectangle:
        return PhosphorIconsLight.rectangle;
      case ShapeType.circle:
        return PhosphorIconsLight.circle;
      case ShapeType.arrow:
        return PhosphorIconsLight.arrowRight; // 在 _getShapeIcon 中添加图标映射
      case ShapeType.triangle:
        return PhosphorIconsLight.triangle;
      case ShapeType.star:
        return PhosphorIconsLight.star;
      default:
        return PhosphorIconsLight.rectangle;
    }
  }

  IconData? getIcon(StrokeType strokeType) {
    switch (strokeType) {
      case StrokeType.pen:
        return PhosphorIconsLight.pen;
      case StrokeType.marker:
        return PhosphorIconsLight.highlighter;
      case StrokeType.shape:
        return _getShapeIcon(currentShape);
      default:
        return PhosphorIconsLight.pen;
    }
  }
}
