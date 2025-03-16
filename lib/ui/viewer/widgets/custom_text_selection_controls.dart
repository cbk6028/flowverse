import 'package:flov/domain/models/tool/stroke.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CustomTextSelectionControls extends DesktopTextSelectionControls {
  static const double _kToolbarContentDistance = 8.0;
  static const double _kToolbarContentDistanceBelow = 20.0;

  final MarkerViewModel markerVm;
  final TextEditingController? translationController;

  CustomTextSelectionControls(this.markerVm, {this.translationController});

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        endpoints.length > 1 ? endpoints[1] : endpoints[0];

    // 计算工具栏位置
    final Offset anchorAbove = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top +
          startTextSelectionPoint.point.dy -
          textLineHeight -
          _kToolbarContentDistance,
    );
    final Offset anchorBelow = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      globalEditableRegion.top +
          endTextSelectionPoint.point.dy +
          _kToolbarContentDistanceBelow,
    );

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      toolbarBuilder: (BuildContext context, Widget child) {
        return Card(
          elevation: 2.0,
          child: child,
        );
      },
      children: <Widget>[
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          onPressed: () {
            markerVm.applyMark(MarkerType.highlight);
            delegate.hideToolbar();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.highlighter, size: 18),
              SizedBox(width: 4),
              Text('高亮'),
            ],
          ),
        ),
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          onPressed: () {
            markerVm.applyMark(MarkerType.underline);
            delegate.hideToolbar();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.textUnderline, size: 18),
              SizedBox(width: 4),
              Text('下划线'),
            ],
          ),
        ),
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          onPressed: () {
            markerVm.applyMark(MarkerType.strikethrough);
            delegate.hideToolbar();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.textStrikethrough, size: 18),
              SizedBox(width: 4),
              Text('删除线'),
            ],
          ),
        ),
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          onPressed: () {
            delegate.copySelection(SelectionChangedCause.toolbar);
            delegate.hideToolbar();
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.copy, size: 18),
              SizedBox(width: 4),
              Text('复制'),
            ],
          ),
        ),
        // if (translationController != null)
        // var selectedText = markerVm.selectedRanges[0].text;
        //     print(selectedText);
        //     ReaderViewModel.instance.showTranslationPanel(selectedText);
        //     delegate.hideToolbar();
        TextSelectionToolbarTextButton(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          onPressed: () {
            
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.translate, size: 18),
              SizedBox(width: 4),
              Text('翻译'),
            ],
          ),
        ),
      ],
    );
  }
}
