import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key, required this.onTap});

  final ValueChanged<Color> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Colors.yellow,
        Colors.orange,
        Colors.red,
        Colors.pink,
        Colors.green,
        Colors.blue,
        Colors.purple,
        Colors.brown,
        Colors.grey,
        Colors.black,
      ]
          .map((color) => GestureDetector(
                onTap: () {
                  onTap(color);
                  // setState(() {});
                  // Navigator.pop(context);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}