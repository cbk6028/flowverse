// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:provider/provider.dart';
// import 'package:flov/ui/viewer/vm/reader_vm.dart';

// class BottomBar extends StatelessWidget {
//   const BottomBar({super.key});

//   @override
//   Widget build(BuildContext context) {
//     var appState = context.watch<ReaderViewModel>();

//     return Container(
//       height: 40,
//       decoration: BoxDecoration(
//         color: const Color(0xfff7f7f7), // 与阅读器背景颜色一致
//         border: Border(
//           top: BorderSide(
//             color: Colors.grey.withOpacity(0.4),
//             width: 0.5,
//           ),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // 左侧按钮组
//           Row(
//             children: [
//               // 上一页按钮
//               CupertinoButton(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: const Icon(
//                   PhosphorIconsRegular.caretLeft,
//                   color: Color(0xff18181B),
//                   size: 16,
//                 ),
//                 onPressed: () {
//                   appState.goToPreviousPage();
//                 },
//               ),
//               // 页码显示
//               PageNumberWidget(appState: appState),

//               // 下一页按钮
//               CupertinoButton(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: const Icon(
//                   PhosphorIconsRegular.caretRight,
//                   color: Color(0xff18181B),
//                   size: 16,
//                 ),
//                 onPressed: () {
//                   appState.goToNextPage();
//                 },
//               ),
//             ],
//           ),
//           // 右侧按钮组
//           Container(
//             decoration: BoxDecoration(
//               border: Border(
//                 left: BorderSide(
//                   color: Colors.grey.withOpacity(0.15),
//                   width: 0.5,
//                 ),
//               ),
//             ),
//             child: Row(
//               children: [
//                 // 缩小按钮
//                 CupertinoButton(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: const Icon(
//                     PhosphorIconsRegular.minus,
//                     color: Color(0xff18181B),
//                     size: 16,
//                   ),
//                   onPressed: () {
//                     appState.zoomDown();
//                   },
//                 ),
//                 Builder(builder: (context) {
//                   return Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Text(
//                       '${(appState.pdfViewerController.currentZoom * 100).toInt()} %',
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Color(0xff18181B),
//                       ),
//                     ),
//                   );
//                 }),
//                 // 放大按钮
//                 CupertinoButton(
//                   padding: const EdgeInsets.symmetric(horizontal: 8),
//                   child: const Icon(
//                     PhosphorIconsRegular.plus,
//                     color: Color(0xff18181B),
//                     size: 16,
//                   ),
//                   onPressed: () {
//                     appState.zoomUp();
//                   },
//                 ),
//                 // 双页模式切换
//                 Container(
//                   decoration: BoxDecoration(
//                     border: Border(
//                       left: BorderSide(
//                         color: Colors.grey.withOpacity(0.15),
//                         width: 0.5,
//                       ),
//                     ),
//                   ),
//                   child: CupertinoButton(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: Icon(
//                       appState.isDoublePageMode
//                           ? PhosphorIconsRegular.bookOpenText
//                           : PhosphorIconsRegular.book,
//                       color: Color(0xff18181B),
//                       size: 16,
//                     ),
//                     onPressed: () {
//                       appState.isDoublePageMode = !appState.isDoublePageMode;
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class PageNumberWidget extends StatefulWidget {
//   final ReaderViewModel appState;

//   const PageNumberWidget({Key? key, required this.appState}) : super(key: key);

//   @override
//   _PageNumberWidgetState createState() => _PageNumberWidgetState();
// }

// class _PageNumberWidgetState extends State<PageNumberWidget> {
//   bool _isEditing = false;
//   late TextEditingController _controller;
//   late FocusNode _focusNode;

//   @override
//   void initState() {
//     super.initState();
//     _controller = TextEditingController();
//     _focusNode = FocusNode();
//     _focusNode.addListener(_onFocusChange);
//   }

//   @override
//   void dispose() {
//     _focusNode.removeListener(_onFocusChange);
//     _focusNode.dispose();
//     _controller.dispose();
//     super.dispose();
//   }

//   void _onFocusChange() {
//     if (!_focusNode.hasFocus && _isEditing) {
//       _finishEditing();
//     }
//   }

//   void _startEditing() {
//     _controller.text = (widget.appState.currentPageNumber ?? 0).toString();
//     setState(() {
//       _isEditing = true;
//     });
//     // 确保在下一帧聚焦
//     Future.microtask(() => _focusNode.requestFocus());
//   }

//   void _finishEditing() {
//     setState(() {
//       _isEditing = false;
//     });
    
//     // 尝试解析输入的页码
//     try {
//       final pageNumber = int.parse(_controller.text);
//       if (pageNumber > 0 && pageNumber <= widget.appState.totalPages) {
//         // 使用 pdfViewerController 跳转到指定页面
//         widget.appState.pdfViewerController.goToPage(pageNumber: pageNumber);
//       }
//     } catch (e) {
//       // 解析失败，不做任何操作
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _isEditing ? null : _startEditing,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.6),
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: Colors.grey.withOpacity(0.15),
//             width: 0.5,
//           ),
//         ),
//         child: _isEditing
//             ? SizedBox(
//                 width: 60,
//                 height: 20,
//                 child: TextField(
//                   controller: _controller,
//                   focusNode: _focusNode,
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Color(0xff18181B),
//                   ),
//                   decoration: const InputDecoration(
//                     contentPadding: EdgeInsets.zero,
//                     border: InputBorder.none,
//                     isDense: true,
//                   ),
//                   onSubmitted: (_) => _finishEditing(),
//                   autofocus: true,
//                 ),
//               )
//             : Text(
//                 '${widget.appState.currentPageNumber ?? 0} / ${widget.appState.totalPages}',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   color: Color(0xff18181B),
//                 ),
//               ),
//       ),
//     );
//   }
// }
