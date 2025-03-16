part of 'handler.dart';

class ImageHandler extends ToolHandler {
  final ToolContext _context;
  Offset? _imagePosition;
  Size? _imageSize;
  bool _isSelected = false;
  String? _imagePath;
  ui.Image? _currentImage;
  double _scale = 1.0;
  PageNumber _pageNumber = 0;

  @override
  ToolContext get context => _context;

  @override
  PageNumber get pageNumber => _pageNumber;

  @override
  double get scale => _scale;

  ImageHandler(this._context) {
    print('ImageHandler: 创建新实例 - 页码: $_pageNumber');
  }

  @override
  void onPanStart(DragStartDetails details, PageNumber pageNumber, double scale) {
    print('ImageHandler: onPanStart 开始 - 页码: $pageNumber');
    _pageNumber = pageNumber;
    _scale = scale;
  }

  @override
  void onPanUpdate(DragUpdateDetails details) {
    // 图片工具不使用拖动手势
  }

  @override
  void onPanEnd(DragEndDetails details) {
    // 图片工具不使用拖动手势
  }

  @override
  void onPointerDown(PointerDownEvent event) {
    print('ImageHandler: onPointerDown - 页码: $_pageNumber');
    if (_imagePath != null) {
      final point = context.toPageCoordinate(event.localPosition, scale);
      createNewImage(point);
    }
  }

  Future<void> createNewImage(Offset position) async {
    print('ImageHandler: 创建新图片 - 位置: $position');
    if (_imagePath == null) return;

    final image = await _loadImage(_imagePath!);
    _currentImage = image;
    _imagePosition = position;
    _imageSize = _calculateFitSize(
      Size(image.width.toDouble(), image.height.toDouble()),
      const Size(200, 200), // 默认最大尺寸
    );
    _isSelected = true;
  }

  Future<ui.Image> _loadImage(String path) async {
    final data = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Size _calculateFitSize(Size imageSize, Size maxSize) {
    final double aspectRatio = imageSize.width / imageSize.height;
    if (imageSize.width > maxSize.width) {
      return Size(maxSize.width, maxSize.width / aspectRatio);
    }
    if (imageSize.height > maxSize.height) {
      return Size(maxSize.height * aspectRatio, maxSize.height);
    }
    return imageSize;
  }

  void saveImage() {
    print('ImageHandler: 保存图片');
    if (_currentImage != null && _imagePosition != null && _imageSize != null) {
      _currentStroke = Stroke(
        paint: Paint()
          ..color = Colors.black
          ..strokeWidth = 1,
        pageNumber: _pageNumber,
        tool: ImageTool(
          imagePath: _imagePath!,
          imageSize: _imageSize!,
        ),
        initialPoints: [Point(_imagePosition!.dx, _imagePosition!.dy)],
      );
      
      context.markerVm.addStroke(_currentStroke!, _pageNumber);
      _currentStroke = null;
    }
    
    clearImage();
  }

  void clearImage() {
    _currentImage = null;
    _imagePosition = null;
    _imageSize = null;
    _isSelected = false;
  }

  @override
  void onActivate() {
    print('ImageHandler: 工具激活 - 页码: $_pageNumber');
  }

  @override
  void onDeactivate() {
    print('ImageHandler: 工具停用 - 页码: $_pageNumber');
    if (_isSelected && _currentImage != null && _imagePosition != null) {
      saveImage();
    }
    super.onDeactivate();
  }

  @override
  void draw(Canvas canvas, Size size) {
    // 图片工具不需要在 Canvas 上绘制任何内容
    // 图片显示是通过 Widget 层实现的
  }

  @override
  void dispose() {
    print('ImageHandler: 销毁 - 页码: $_pageNumber');
    clearImage();
  }

  // 获取当前图片状态
  bool get isSelected => _isSelected;
  ui.Image? get currentImage => _currentImage;
  Offset? get imagePosition => _imagePosition;
  Size? get imageSize => _imageSize;
  String? get imagePath => _imagePath;
  set imagePath(String? value) {
    _imagePath = value;
  }

  // 更新图片大小
  void updateImageSize(Size newSize) {
    _imageSize = newSize;
  }

  // 更新图片位置
  void updateImagePosition(Offset newPosition) {
    _imagePosition = newPosition;
  }
}