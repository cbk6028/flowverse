import 'package:flov/ui/overlay_canvas/vm/handler.dart';
import 'package:flutter/material.dart';
// import '../vm/text_handler.dart';

class TextInputOverlay extends StatelessWidget {
  final TextHandler textHandler;
  final double scale;
  final VoidCallback onStateChanged;

  const TextInputOverlay({
    super.key,
    required this.textHandler,
    required this.scale,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!textHandler.isEditing || textHandler.textPosition == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: textHandler.textPosition!.dx * scale,
      top: textHandler.textPosition!.dy * scale,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 200,
          constraints: const BoxConstraints(
            minHeight: 40,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue,
              width: 1,
            ),
            color: Colors.white.withOpacity(0.9),
          ),
          child: Stack(
            children: [
              TextField(
                controller: textHandler.textController,
                focusNode: textHandler.focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.fromLTRB(8, 8, 40, 8),
                  border: InputBorder.none,
                  hintText: '输入文字...',
                ),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.2,
                ),
                maxLines: null,
                onSubmitted: (text) {
                  if (text.isNotEmpty) {
                    textHandler.saveText();
                    onStateChanged();
                  }
                },
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, size: 16),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        textHandler.saveText();
                        onStateChanged();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        textHandler.cancelEditing();
                        onStateChanged();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
