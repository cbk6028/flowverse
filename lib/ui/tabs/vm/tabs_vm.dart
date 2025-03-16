// 全局TabController，用于跨组件通信
import 'package:flov/ui/tabs/widgets/tabs.dart';
import 'package:flutter/material.dart';

class AppTabController extends ChangeNotifier {
  static final AppTabController _instance = AppTabController._internal();

  factory AppTabController() {
    return _instance;
  }

  AppTabController._internal();

  // 添加标签页的回调函数
  Function(TabItem)? addTabCallback;

  // 添加标签页
  void addTab(TabItem tabItem) {
    if (addTabCallback != null) {
      addTabCallback!(tabItem);
    }
  }
}
