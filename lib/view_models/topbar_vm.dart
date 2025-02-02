import 'package:flowverse/view_models/reader_vm.dart';
import 'package:flutter/material.dart';

class TopbarViewModel extends ChangeNotifier {
  // 组合 模式
  // final readerVm;

  TopbarViewModel(); // 构造函数

  bool isHandSelected = true;
  bool isBrushSelected = false;
  bool isUnderlineSelected = false;

  final GlobalKey brushButtonKey = GlobalKey();
  final GlobalKey underlineButtonKey = GlobalKey();


  void resetToolStates() {
    isHandSelected = false;
    isBrushSelected = false;
    isUnderlineSelected = false;
    // readerVm.notifyListeners();
  }

  set isHandSelectedState(bool value) {
    isHandSelected = value;
    // readerVm.notifyListeners();
  }

  set isBrushSelectedState(bool value) {
    isBrushSelected = value;
    // readerVm.notifyListeners();
  }

  set isUnderlineSelectedState(bool value) {
    isUnderlineSelected = value;
    // readerVm.notifyListeners();
  }
}
