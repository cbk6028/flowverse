import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flov/domain/models/book/book.dart';
import 'package:flov/domain/models/tab/pdf_tab.dart';
import 'package:flov/utils/logger.dart';

/// 管理PDF阅读器的多标签页功能
class TabsViewModel extends ChangeNotifier {
  static TabsViewModel? _instance;
  static TabsViewModel get instance {
    assert(_instance != null, 'TabsViewModel not initialized');
    return _instance!;
  }

  TabsViewModel() {
    _instance = this;
  }

  /// 所有打开的标签页
  final List<PdfTab> _tabs = [];
  
  /// 当前活动标签页的索引
  int _activeTabIndex = -1;
  
  /// UUID生成器
  final _uuid = const Uuid();

  /// 获取所有标签页
  List<PdfTab> get tabs => List.unmodifiable(_tabs);
  
  /// 获取当前活动标签页
  PdfTab? get activeTab => _activeTabIndex >= 0 && _activeTabIndex < _tabs.length 
      ? _tabs[_activeTabIndex] 
      : null;
  
  /// 获取当前活动标签页索引
  int get activeTabIndex => _activeTabIndex;

  /// 添加新标签页
  void addTab(String filePath, Book book) {
    // 从文件路径中提取文件名作为标签标题
    final fileName = filePath.split(Platform.pathSeparator).last;
    
    // 创建新标签页
    final newTab = PdfTab(
      id: _uuid.v4(),
      title: fileName,
      filePath: filePath,
      book: book,
      isActive: true,
    );
    
    // 将所有标签页设置为非活动状态
    for (var i = 0; i < _tabs.length; i++) {
      _tabs[i] = _tabs[i].copyWith(isActive: false);
    }
    
    // 添加新标签页
    _tabs.add(newTab);
    _activeTabIndex = _tabs.length - 1;
    
    logger.i('添加新标签页: $fileName, 当前标签页数: ${_tabs.length}');
    notifyListeners();
  }

  /// 切换到指定标签页
  void switchToTab(int index) {
    if (index >= 0 && index < _tabs.length && index != _activeTabIndex) {
      // 将所有标签页设置为非活动状态
      for (var i = 0; i < _tabs.length; i++) {
        _tabs[i] = _tabs[i].copyWith(isActive: false);
      }
      
      // 设置选中的标签页为活动状态
      _tabs[index] = _tabs[index].copyWith(isActive: true);
      _activeTabIndex = index;
      
      logger.i('切换到标签页: ${_tabs[index].title}');
      notifyListeners();
    }
  }

  /// 关闭指定标签页
  void closeTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      final closedTab = _tabs[index];
      _tabs.removeAt(index);
      
      // 如果关闭的是当前活动标签页，则需要更新活动标签页
      if (index == _activeTabIndex) {
        // 如果还有标签页，则选择最近的一个
        if (_tabs.isNotEmpty) {
          _activeTabIndex = index < _tabs.length ? index : _tabs.length - 1;
          _tabs[_activeTabIndex] = _tabs[_activeTabIndex].copyWith(isActive: true);
        } else {
          // 没有标签页了，清理阅读器状态
          _activeTabIndex = -1;
          // 通知监听器清理PDF阅读器状态
          _onLastTabClosed?.call();
        }
      } else if (index < _activeTabIndex) {
        // 如果关闭的标签页在当前活动标签页之前，需要调整活动标签页索引
        _activeTabIndex--;
      }
      
      logger.i('关闭标签页: ${closedTab.title}, 当前标签页数: ${_tabs.length}');
      notifyListeners();
    }
  }

  /// 更新标签页信息
  void updateTab(int index, {String? title, Book? book, int? currentPage}) {
    if (index >= 0 && index < _tabs.length) {
      if (book != null) {
        _tabs[index] = _tabs[index].copyWith(book: book);
      }
      
      if (title != null) {
        _tabs[index] = _tabs[index].copyWith(title: title);
      }
      
      notifyListeners();
    }
  }

  /// 检查是否已经打开了指定文件
  int findTabByFilePath(String filePath) {
    for (var i = 0; i < _tabs.length; i++) {
      if (_tabs[i].filePath == filePath) {
        return i;
      }
    }
    return -1;
  }

  /// 最后一个标签页关闭时的回调函数
  Function? _onLastTabClosed;

  /// 设置最后一个标签页关闭时的回调函数
  set onLastTabClosed(Function callback) {
    _onLastTabClosed = callback;
  }
} 