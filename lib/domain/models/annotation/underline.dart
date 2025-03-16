import 'package:flov/domain/models/annotation/annotation.dart';
import 'package:flutter/material.dart';

// 在文件顶部添加枚举定义
enum UnderlineStyle {
  solid, // 实线
  dashed, // 虚线
  dotted, // 点线
  wavy // 波浪线
}

class Underline extends Annotation {
  UnderlineStyle style;

  Underline(
      {super.color = Colors.blue,
      super.width = 0.8,
      this.style = UnderlineStyle.solid});

  set setStyle(UnderlineStyle style) => this.style = style;
}
