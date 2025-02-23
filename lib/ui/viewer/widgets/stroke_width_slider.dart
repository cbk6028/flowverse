// 添加构建粗细调节滑块的方法
import 'package:flutter/material.dart';

class StrokeWidthSlider extends StatelessWidget {
  double strokeWidth;
  double minWidth;
  double maxWidth;
  int divisions;
  Function(double) onChanged;

  StrokeWidthSlider(
      {super.key,
      required this.strokeWidth,
      required this.minWidth,
      required this.maxWidth,
      required this.divisions,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '线条粗细: ${strokeWidth.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12),
        ),
        Slider(
          value: strokeWidth,
          min: minWidth,
          max: maxWidth,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
