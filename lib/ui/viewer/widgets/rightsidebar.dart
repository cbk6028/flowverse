import 'package:flov/ui/viewer/vm/reader_vm.dart';
import 'package:flov/ui/viewer/widgets/ai_chat_view.dart';
import 'package:flutter/material.dart' hide Card;
// import 'package:lex/pages/translation_page.dart';
import 'package:provider/provider.dart';
// import '../../../view_models/reader_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:synchronized/extension.dart';
// import 'package:webf/webf.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:translator/translator.dart';
import 'dart:ui';

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

class RightSidebar extends StatefulWidget {
  const RightSidebar({super.key});

  @override
  State<RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<RightSidebar> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<ReaderViewModel>();
    var theme = Theme.of(context);

    return Stack(
      children: [
        // 实际的侧边栏
        MouseRegion(
          onExit: (_) => setState(() => _isVisible = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: _isVisible ? 37 : 8,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow, // 与阅读器背景颜色一致
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isVisible ? 1.0 : 0.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildButton(
                          icon: PhosphorIconsRegular.translate,
                          tooltip: '翻译',
                          onPressed: () => appState.toggleROutline(0),
                        ),
                        _buildButton(
                          icon: PhosphorIconsRegular.robot,
                          tooltip: 'AI',
                          onPressed: () => appState.toggleROutline(1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // 透明的检测区域
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 20, // 更宽的检测区域
          child: MouseRegion(
            onEnter: (_) => setState(() => _isVisible = true),
            child: Container(
              color: Colors.transparent, // 透明区域
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    var theme = Theme.of(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Icon(
          icon,
          color: theme.colorScheme.onSurface,
          size: 16,
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
    var index = viewModel.rindex;
    var theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow, // 与阅读器背景颜色一致
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(-1, 0),
              ),
            ],
          ),
          child: switch (index) {
            0 => SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height,
              child: const Material(
                color: Colors.transparent,
                child: Center(),
              ),
            ),
            1 => const AIChatView(),
            _ => Container(),
          },
        ),
      ),
    );
  }
}
