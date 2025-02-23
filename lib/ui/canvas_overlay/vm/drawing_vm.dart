import 'package:flowverse/domain/models/tool/shape.dart';
import 'package:flowverse/domain/models/tool/tool.dart';
import 'package:flowverse/ui/canvas_overlay/vm/handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DrawingViewModel extends ChangeNotifier {
  // StrokeType _strokeType = StrokeType.pen;

  // DrawingViewModel();
  ToolManager? _toolManager;  // 改为可空类型

  bool _isDrawingMode = false;
  double _strokeWidth = 2.0;
  double eraserSize = 10.0;
  ShapeType currentShape = ShapeType.rectangle;
  ToolType _strokeType = ToolType.pen;
  Color _markerColor = Colors.yellow;
  double _markerOpacity = 0.3;
  String? _imagePath;
  Size? _imageSize;

  // 笔的属性
  Color _penColor = Colors.blue;
  double _penWidth = 2.0;

  ToolConfig currentToolConfig = PenConfig(color: Colors.blue, width: 1, opacity: 1.0);
  // 马克笔的属性
  double _markerWidth = 4.0;

  // 形状的属性
  Color _shapeColor = Colors.blue;
  double _shapeWidth = 2.0;
  Color _shapeFillColor = Colors.blue;
  double _shapeFillOpacity = 0.3;
  bool _isHandMode = true;

  
  // 获取当前工具管理器
  ToolManager? get toolManager => _toolManager;  // 改为可空返回
  
  // 检查工具管理器是否已初始化
  bool get isToolManagerInitialized => _toolManager != null;
  
  // 初始化工具管理器
  void initToolManager(ToolContext context) {
    // print('DrawingViewModel: 初始化工具管理器 - 页码: ${context.page.pageNumber}');
    // 如果已经存在工具管理器，且页码不同，则更新
    // if (_toolManager != null) {
      // if (_toolManager!.context.page.pageNumber != context.page.pageNumber) {
        // updateToolManager(context);
      // }
      // return;
    // }
    
    // 创建新的工具管理器
    _toolManager = ToolManager(context);
    // 初始化时设置当前工具
    _toolManager!.switchTool(_strokeType);
    // print('DrawingViewModel: 工具管理器初始化完成 - 页码: ${context.page.pageNumber}');
    notifyListeners();
  }

  // 切换工具
  void switchTool(ToolType type) {
    _strokeType = type;
    _isDrawingMode = type != ToolType.lasso;
    
    // 只有在工具管理器初始化后才调用switchTool
    if (isToolManagerInitialized) {
      _toolManager!.switchTool(type);
    }
    
    notifyListeners();
  }

  bool get isDrawingMode => _isDrawingMode;
  bool get isEraserMode => _strokeType == ToolType.eraser;
  ToolType get strokeType => _strokeType;
  Color get penColor => _penColor;
  double get penWidth => _penWidth;
  double get markerWidth => _markerWidth;
  Color get markerColor => _markerColor;
  double get markerOpacity => _markerOpacity;
  String? get imagePath => _imagePath;
  Size? get imageSize => _imageSize;
  double get strokeWidth => _strokeWidth;
  // getter
  Color get shapeColor => _shapeColor;
  double get shapeWidth => _shapeWidth;
  Color get shapeFillColor => _shapeFillColor;
  double get shapeFillOpacity => _shapeFillOpacity;

  bool get isHandMode => _isHandMode;

  void setDrawingMode(bool value) {
    _isDrawingMode = value;
    notifyListeners();
  }

  void setEraserMode(bool value) {
    if (value) {
      _strokeType = ToolType.eraser;
    } else {
      _strokeType = ToolType.pen;
    }
    _isDrawingMode = value;
    notifyListeners();
  }

  void setStrokeType(ToolType type) {
    switchTool(type); // 使用新的 switchTool 方法
  }

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

  void setMarkerColor(Color color) {
    _markerColor = color;
    notifyListeners();
  }

  void setMarkerOpacity(double opacity) {
    _markerOpacity = opacity;
    notifyListeners();
  }

  void setImagePath(String? path) {
    _imagePath = path;
    notifyListeners();
  }

  void setImageSize(Size? size) {
    _imageSize = size;
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
    // Clear eraser mode when switching to shape tool
    _strokeType = ToolType.shape;
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
    }
    notifyListeners();
  }

  getDrawingColor(ToolType strokeType) {
    switch (strokeType) {
      case ToolType.pen:
        return _penColor;
      case ToolType.marker:
        return _markerColor;
      case ToolType.shape:
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
    }
  }

  IconData? getIcon(ToolType strokeType) {
    switch (strokeType) {
      case ToolType.pen:
        return PhosphorIconsLight.pen;
      case ToolType.marker:
        return PhosphorIconsLight.highlighter;
      case ToolType.shape:
        return _getShapeIcon(currentShape);
      default:
        return PhosphorIconsLight.pen;
    }
  }

  void setEraserSize(double value) {
    eraserSize = value;
    notifyListeners();
  }

  // 更新工具管理器的上下文
  // void updateToolManager(ToolContext context) {
  //   // print('DrawingViewModel: 更新工具管理器上下文 - 页码: ${context.page.pageNumber}');
    
  //   // 保存当前状态
  //   final currentType = _strokeType;
  //   final currentStroke = _toolManager?.currentHandler.currentStroke;
    
  //   // 如果有未完成的笔画，先保存到原来的页面
  //   if (currentStroke != null) {
  //     print('DrawingViewModel: 发现未完成的笔画，准备保存到页面 ${currentStroke.pageNumber}');
  //     context.markerVm.addStroke(currentStroke, currentStroke.pageNumber);
  //     print('DrawingViewModel: 未完成的笔画已保存');
  //   }
    
  //   // 销毁旧的工具管理器
  //   _toolManager?.dispose();
    
  //   // 创建新的工具管理器
  //   _toolManager = ToolManager(context);
  //   _toolManager!.switchTool(currentType);
    
  //   print('DrawingViewModel: 工具管理器已更新 - 当前页码: ${context.page.pageNumber}');
  //   notifyListeners();
  // }

  @override
  void dispose() {
    _toolManager?.dispose();
    // _toolManager = null;
    super.dispose();
  }
}
