// import 'package:flov/view_models/marker_vm.dart';
import 'package:flov/domain/models/tool/tool.dart';
import 'package:flutter/material.dart';
import 'package:flov/domain/models/tool/stroke.dart';

class TextTool extends Tool {
  @override
  final ToolType type = ToolType.text;
  String text;
  double fontSize;
  Color color;

  TextTool({
    this.text = '',
    this.fontSize = 14.0,
    this.color = Colors.black,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'text': text,
        'fontSize': fontSize,
        'color': color.value,
      };

  static TextTool fromJson(Map<String, dynamic> json) => TextTool(
        text: json['text'],
        fontSize: json['fontSize'],
        color: Color(json['color']),
      );

  @override
  void draw(Canvas canvas, Paint paint, Stroke stroke) {
    final textTool = stroke.tool as TextTool;
    final textSpan = TextSpan(
      text: textTool.text,
      style: TextStyle(
        color: textTool.color,
        fontSize: textTool.fontSize,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final position = Offset(
      stroke.points[0].x.toDouble(),
      stroke.points[0].y.toDouble(),
    );
    textPainter.paint(canvas, position);
  }
}

// class Typer extends StatefulWidget {
//   const Typer({super.key});

//   @override
//   State<Typer> createState() => _TyperState();
// }

// class _TyperState extends State<Typer> {
//   TextEditingController? _textController;
//   FocusNode? _focusNode;
//   Offset? _textPosition;
//   bool _isEditing = false;
//   @override
//   Widget build(BuildContext context) {
//     return const Placeholder();
//   }

//   void _createNewTextInput(
//       Offset position, BuildContext context, MarkerViewModel markerVm) {
//     // 如果已经存在输入框，先保存之前的文本
//     if (_isEditing && _textController != null && _textPosition != null) {
//       _saveText(markerVm);
//     }

//     // 先创建新的控制器和焦点节点
//     final newController = TextEditingController();
//     final newFocusNode = FocusNode();

//     setState(() {
//       // 释放旧的资源
//       _textController?.dispose();
//       _focusNode?.dispose();

//       _textPosition = position;
//       _textController = newController;
//       _focusNode = newFocusNode;
//       _isEditing = true;
//     });

//     // 确保在下一帧请求焦点
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_focusNode?.hasListeners ?? false) {
//         _focusNode?.requestFocus();
//       }
//     });
//   }

//   void _saveText(MarkerViewModel markerVm) {
//     final text = _textController?.text ?? '';
//     if (text.isNotEmpty && _textPosition != null) {
//       final stroke = Stroke(
//         paint: Paint()
//           ..color = Colors.black
//           ..strokeWidth = 1,
//         pageNumber: widget.page.pageNumber,
//         tool: TextTool(
//           text: text,
//           fontSize: 14.0,
//           color: Colors.black,
//         ),
//         initialPoints: [Point(_textPosition!.dx, _textPosition!.dy)],
//       );
//       markerVm.addStroke(stroke, widget.page.pageNumber);
//     }

//     setState(() {
//       _textController?.clear();
//       _textPosition = null;
//       _isEditing = false;
//       _focusNode?.unfocus(); // 确保取消焦点
//     });
//   }
// }

