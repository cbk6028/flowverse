import 'package:flowverse/ui/viewer/vm/reader_vm.dart';
import 'package:flutter/material.dart' hide Card;
// import 'package:lex/pages/translation_page.dart';
import 'package:provider/provider.dart';
// import '../../../view_models/reader_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:synchronized/extension.dart';
// import 'package:webf/webf.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:reflect_ui/reflect_ui.dart' hide IconButton, TextField;
// import 'package:translator/translator.dart';

// 侧边栏
// 有大纲，搜索等功能

class _PdfPageTextRefCount {
  _PdfPageTextRefCount(this.pageText);
  final PdfPageText pageText;
  int refCount = 0;
}

class PdfPageTextCache {
  final PdfTextSearcher textSearcher;
  PdfPageTextCache({
    required this.textSearcher,
  });

  final _pageTextRefs = <int, _PdfPageTextRefCount>{};

  /// load the text of the given page number.
  Future<PdfPageText> loadText(int pageNumber) async {
    final ref = _pageTextRefs[pageNumber];
    if (ref != null) {
      ref.refCount++;
      return ref.pageText;
    }
    return await synchronized(() async {
      var ref = _pageTextRefs[pageNumber];
      if (ref == null) {
        final pageText = await textSearcher.loadText(pageNumber: pageNumber);
        ref = _pageTextRefs[pageNumber] = _PdfPageTextRefCount(pageText!);
      }
      ref.refCount++;
      return ref.pageText;
    });
  }

  /// Release the text of the given page number.
  void releaseText(int pageNumber) {
    final ref = _pageTextRefs[pageNumber]!;
    ref.refCount--;
    if (ref.refCount == 0) {
      _pageTextRefs.remove(pageNumber);
    }
  }
}

class RightSidebar extends StatelessWidget {
  const RightSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();

    return Material(
      child: Container(
        width: 45,
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  PhosphorIconsLight.translate,
                  color: Colors.black87,
                  size: 20,
                ),
                color: Colors.transparent,
                iconSize: 20,
                tooltip: '翻译',
                onPressed: () {
                  appState.toggleROutline(0);
                },
              ),
              IconButton(
                icon: Icon(
                  PhosphorIconsLight.arrowSquareOut,
                  color: Colors.black87,
                  size: 20,
                ),
                color: Colors.transparent,
                iconSize: 20,
                tooltip: '导出',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RSideBar extends StatelessWidget {
  const RSideBar({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ReaderViewModel>();
    var _index = viewModel.rindex;

    return Material(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                switch (_index) {
                  0 => Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.height,
                        child: const Material(
                          color: Colors.white,
                          child: Center(),
                          // TranslatorApp(),
                        ),
                      ),
                  1 => const Expanded(child: Center(child: Text('批注'))),
                  _ => Container(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// class TranslationPanel extends StatefulWidget {
//   const TranslationPanel({super.key});

//   @override
//   State<TranslationPanel> createState() => _TranslationPanelState();
// }

// class _TranslationPanelState extends State<TranslationPanel> {
//   final TextEditingController _controller = TextEditingController();
//   final FocusNode _focusNode = FocusNode();
//   String _selectedSourceLanguage = 'auto';
//   String _selectedTargetLanguage = 'zh';
//   bool _isTranslating = false;

//   @override
//   Widget build(BuildContext context) {
//     return ConstrainedBox(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.8,
//       ),
//       child: Column(
//         children: [
//           // 语言选择栏
//           Card(
//             margin: const EdgeInsets.only(bottom: 8),
//             child: Row(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: LanguageLabel(
//                     _selectedSourceLanguage,
//                     flagSize: 18,
//                   ),
//                 ),
//                 SizedBox(
//                   width: 20,
//                   height: 38,
//                   child: Container(
//                     margin: EdgeInsets.zero,
//                     child: Icon(
//                       FluentIcons.arrow_right_20_regular,
//                       size: 16,
//                       color: Theme.of(context).iconTheme.color,
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: LanguageLabel(
//                     _selectedTargetLanguage,
//                     flagSize: 18,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // 输入框
//           Card(
//             margin: const EdgeInsets.only(bottom: 8),
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: _controller,
//                     focusNode: _focusNode,
//                     maxLines: 5,
//                     minLines: 3,
//                     decoration: const InputDecoration(
//                       border: InputBorder.none,
//                       hintText: '输入要翻译的文本',
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.end,
//                     children: [
//                       TextButton(
//                         onPressed: () {
//                           _controller.clear();
//                         },
//                         child: const Text('清空'),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: () {
//                           // 处理翻译
//                         },
//                         child: const Text('翻译'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // 翻译结果区域
//           Flexible(
//             child: Card(
//               child: _isTranslating
//                   ? const Center(child: CircularProgressIndicator())
//                   : Container(
//                       padding: const EdgeInsets.all(12),
//                       width: double.infinity,
//                       child: const SelectableText(
//                         '翻译结果将显示在这里',
//                         style: TextStyle(color: Colors.black54),
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class LanguageLabel extends StatelessWidget {
//   const LanguageLabel(this.code, {super.key, this.flagSize = 18});

//   final String code;
//   final double flagSize;

//   String getLanguageName(String code) {
//     switch (code) {
//       case 'auto':
//         return '自动检测';
//       case 'zh':
//         return '中文';
//       case 'en':
//         return '英语';
//       default:
//         return code;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: flagSize,
//           height: flagSize,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(4),
//             border: Border.all(
//               color: Colors.black.withOpacity(0.1),
//               width: 0.5,
//             ),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(4),
//             child: Image.asset(
//               'resources/images/flag_icons/$code.png',
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(
//           getLanguageName(code),
//           style: const TextStyle(fontSize: 13),
//         ),
//       ],
//     );
//   }
// }
