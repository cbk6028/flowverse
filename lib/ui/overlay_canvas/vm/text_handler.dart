part of 'handler.dart';

class TextHandler extends ToolHandler {
  final ToolContext _context;
  TextEditingController? _textController;
  FocusNode? _focusNode;
  Offset? _textPosition;
  bool _isEditing = false;
  
  @override
  ToolContext get context => _context;
  
  @override
  PageNumber get pageNumber => _pageNumber;
  PageNumber _pageNumber = 0;
  
  @override
  double get scale => _scale;
  double _scale = 1.0;
  
  TextHandler(this._context) {
    print('TextHandler: 创建新实例 - 页码: $_pageNumber');
  }
  
  @override
  void onPanStart(DragStartDetails details, PageNumber pageNumber, double scale) {
    print('TextHandler: onPanStart 开始 - 页码: $pageNumber');
    _pageNumber = pageNumber;
    _scale = scale;
    
    // 文本工具不使用拖动手势，而是使用点击
  }
  
  @override
  void onPanUpdate(DragUpdateDetails details) {
    // 文本工具不使用拖动手势
  }
  
  @override
  void onPanEnd(DragEndDetails details) {
    // 文本工具不使用拖动手势
  }
  
  @override
  void onPointerDown(PointerDownEvent event) {
    print('TextHandler: onPointerDown - 页码: $_pageNumber');
    final point = context.toPageCoordinate(event.localPosition, scale);
    createNewTextInput(point);
  }
  
  void createNewTextInput(Offset position) {
    print('TextHandler: 创建新文本输入框 - 位置: $position');
    
    // 如果已经存在输入框，先保存之前的文本
    if (_isEditing && _textController != null && _textPosition != null) {
      saveText();
    }
    
    // 创建新的控制器和焦点节点
    _textController?.dispose();
    _focusNode?.dispose();
    
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _textPosition = position;
    _isEditing = true;
    
    // 确保在下一帧请求焦点
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode?.hasListeners ?? false) {
        _focusNode?.requestFocus();
      }
    });
  }
  
  void saveText() {
    print('TextHandler: 保存文本');
    final text = _textController?.text ?? '';
    if (text.isNotEmpty && _textPosition != null) {
      _currentStroke = Stroke(
        paint: Paint()
          ..color = Colors.black
          ..strokeWidth = 1,
        pageNumber: _pageNumber,
        tool: TextTool(
          text: text,
          fontSize: 14.0,
          color: Colors.black,
        ),
        initialPoints: [Point(_textPosition!.dx, _textPosition!.dy)],
      );
      
      context.markerVm.addStroke(_currentStroke!, _pageNumber);
      _currentStroke = null;
    }
    
    _textController?.clear();
    _textPosition = null;
    _isEditing = false;
    _focusNode?.unfocus();
  }
  
  @override
  void onActivate() {
    print('TextHandler: 工具激活 - 页码: $_pageNumber');
  }
  
  @override
  void onDeactivate() {
    print('TextHandler: 工具停用 - 页码: $_pageNumber');
    // 如果有未保存的文本，保存它
    if (_isEditing && _textController != null && _textPosition != null) {
      saveText();
    }
    super.onDeactivate();
  }
  
  @override
  void draw(Canvas canvas, Size size) {
    // 文本工具不需要在 Canvas 上绘制任何内容
    // 文本输入框是通过 Widget 层实现的
  }
  
  @override
  void dispose() {
    print('TextHandler: 销毁 - 页码: $_pageNumber');
    _textController?.dispose();
    _focusNode?.dispose();
    _textController = null;
    _focusNode = null;
    _textPosition = null;
    _isEditing = false;
  }
  
  // 获取当前文本编辑状态
  bool get isEditing => _isEditing;
  TextEditingController? get textController => _textController;
  FocusNode? get focusNode => _focusNode;
  Offset? get textPosition => _textPosition;
  
  // 取消文本编辑
  void cancelEditing() {
    _textController?.clear();
    _textPosition = null;
    _isEditing = false;
    _focusNode?.unfocus();
  }
}