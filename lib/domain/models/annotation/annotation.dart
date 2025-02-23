import 'dart:ui';

abstract class Annotation{
  Color color;
  double width;

  Annotation({required this.color, required this.width});

  set setColor(Color color) => this.color = color;
  set setWidth(double width) => this.width = width;
}