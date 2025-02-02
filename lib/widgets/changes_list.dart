import 'package:flutter/material.dart';

import 'package:simple_painter/simple_painter.dart';

class ChangesList extends StatelessWidget {
  const ChangesList({required this.controller, super.key});
  final PainterController controller;
  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return Container(
      height: 100,
      width: 190,
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(7),
          bottomLeft: Radius.circular(7),
          topLeft: Radius.circular(7),
        ),
      ),
      child: ValueListenableBuilder(
        valueListenable: controller.changeActions,
        builder: (context, value, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (value.changeList.isNotEmpty &&
                value.index == value.changeList.length - 1) {
              scrollController
                  .jumpTo(scrollController.position.maxScrollExtent);
            }
          });
          return ListView.builder(
            controller: scrollController,
            itemCount: value.changeList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 5 : 0, bottom: 4),
                child: GestureDetector(
                  onTap: () =>
                      controller.updateActionWithChangeActionIndex(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: value.index == index ? Colors.grey.shade800 : null,
                      border: Border.all(color: Colors.grey.shade700),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      actionTypeToString(value.changeList[index].actionType),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String actionTypeToString(ActionType actionType) {
    switch (actionType) {
      case ActionType.addedTextItem:
        return 'Added text';
      case ActionType.addedImageItem:
        return 'Added image';
      case ActionType.positionItem:
        return 'Changed position';
      case ActionType.addedCustomWidgetItem:
        return 'Added custom widget';
      case ActionType.sizeItem:
        return 'Changed size';
      case ActionType.rotationItem:
        return 'Changed rotation';
      case ActionType.changedLayerIndex:
        return 'Changed layer index';
      case ActionType.removedItem:
        return 'Removed item';
      case ActionType.draw:
        return 'Draw';
      case ActionType.erase:
        return 'Erase';
      case ActionType.changeTextValue:
        return 'Change text options';
      case ActionType.changeImageValue:
        return 'Change image options';
      case ActionType.changeShapeValue:
        return 'Change shape options';
      case ActionType.addedShapeItem:
        return 'Added shape';
      case ActionType.changeCustomWidgetValue:
        return 'Change custom widget options';
      case ActionType.changeBackgroundImage:
        return 'Change background image';
    }
  }
}
