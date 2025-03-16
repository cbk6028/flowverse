import 'package:flov/theme/app_theme.dart';
import 'package:flov/ui/home/vm/dashboard_vm.dart';
import 'package:flov/ui/home/widgets/dashboard_screen.dart';
import 'package:flov/ui/overlay_marker/vm/marker_vm.dart';
import 'package:flov/ui/tabs/vm/tabs_vm.dart';
import 'package:flov/ui/viewer/vm/reader_vm.dart';
import 'package:flov/ui/viewer/widgets/reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

// 定义标签页数据结构
class TabItem {
  final String id;
  final String title;
  final IconData icon;
  final Widget content;
  final bool closable;

  TabItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.content,
    this.closable = true,
  });
}

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> with WindowListener {
  // 所有可用的标签页
  final Map<String, TabItem> _allTabs = {
    'home': TabItem(
      id: 'home',
      title: '主页',
      icon: Icons.home,
      content: const DashboardScreen(),
      closable: false, // 主页标签不可关闭
    ),
  };

  // 当前打开的标签页
  final List<String> _openTabs = ['home'];

  // 当前激活的标签页
  String _activeTabId = 'home';

  // 窗口是否最大化
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    // 注册全局TabController的回调
    // 为了用户可以自定义
    AppTabController().addTabCallback = _addTab;

    // 注册窗口监听器
    windowManager.addListener(this);
    _initWindowState();
  }

  // 初始化窗口状态
  Future<void> _initWindowState() async {
    _isMaximized = await windowManager.isMaximized();
    setState(() {});
  }

  @override
  void dispose() {
    // 清除回调
    AppTabController().addTabCallback = null;
    // 移除窗口监听器
    windowManager.removeListener(this);
    super.dispose();
  }

  // 窗口最大化状态变化回调
  @override
  void onWindowMaximize() {
    setState(() {
      _isMaximized = true;
    });
  }

  // 窗口恢复状态变化回调
  @override
  void onWindowUnmaximize() {
    setState(() {
      _isMaximized = false;
    });
  }

  // 添加新标签页
  void _addTab(TabItem tabItem) {
    setState(() {
      _allTabs[tabItem.id] = tabItem;
      // 如果标签页不存在，则添加到打开的标签页列表中
      if (!_openTabs.contains(tabItem.id)) {
        _openTabs.add(tabItem.id);
        _activeTabId = tabItem.id;
        // 如果标签页存在，则激活它
      } else {
        _activeTabId = tabItem.id;
      }
    });
  }

  // 关闭标签页
  void _closeTab(String tabId) async {
    if (tabId == 'home') return; // 主页标签不可关闭

    final int index = _openTabs.indexOf(tabId);
    if (index != -1) {
      // 获取当前标签页的内容
      // final tab = _allTabs[tabId]!;
      // if (tab.content is ReaderScreen) {
      //   final readerScreen = tab.content as ReaderScreen;
      //   final appState = context.read<ReaderViewModel>();
      //   final markerVm = context.read<MarkerViewModel>();
      //   final davm = context.read<DashboardViewModel>();

      //   // 保存标注
      //   await markerVm.saveArchive(readerScreen.book);

      //   // 更新当前书籍信息
      //   davm.updateCurrentBook(
      //     lastReadPage: appState.currentPageNumber!,
      //     lastReadTime: DateTime.now(),
      //     totalPages: appState.totalPages,
      //     readProgress: appState.totalPages > 0
      //         ? appState.currentPageNumber! / appState.totalPages
      //         : 0.0,
      //     currentPdfPath: appState.currentPdfPath,
      //   );
      // }

      setState(() {
        _openTabs.removeAt(index);
        // 如果关闭的是当前激活的标签页，则激活前一个标签页
        if (_activeTabId == tabId) {
          _activeTabId = _openTabs[index > 0 ? index - 1 : 0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 自定义标题栏
          DragToMoveArea(
            child: Container(
              height: 36,
              color: AppTheme.auxiliaryColor2Light,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Image.asset('assets/logo/logo-dark-96.png', width: 24, height: 24),
                  // 标签页列表
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _openTabs.length,
                      itemBuilder: (context, index) {
                        final tabId = _openTabs[index];
                        final tab = _allTabs[tabId]!;
                        final isActive = _activeTabId == tabId;

                        return _buildTabItem(tab, isActive);
                      },
                    ),
                  ),
                
                  // 窗口控制按钮
                  Row(
                    children: [
                      // 最小化按钮
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          windowManager.minimize();
                        },
                        color: AppTheme.auxiliaryColor1,
                      ),
                      // 最大化/恢复按钮
                      IconButton(
                        icon: Icon(
                          _isMaximized ? Icons.filter_none : Icons.crop_square,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (_isMaximized) {
                            windowManager.unmaximize();
                          } else {
                            windowManager.maximize();
                          }
                        },
                        color: AppTheme.auxiliaryColor1,
                      ),
                      // 关闭按钮
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          windowManager.close();
                        },
                        color: AppTheme.auxiliaryColor1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 标签页的下方
          Expanded(
            child: IndexedStack(
              index: _openTabs.indexOf(_activeTabId),
              children:
                  _openTabs.map((tabId) => _allTabs[tabId]!.content).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 构建标签页项
  Widget _buildTabItem(TabItem tab, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabId = tab.id;
        });
      },
      child: Container(
        height: 36,
        margin: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.mainColor : AppTheme.auxiliaryColor2Light,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? AppTheme.auxiliaryColor1Dark
                    : AppTheme.auxiliaryColor1,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (tab.closable) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _closeTab(tab.id);
                },
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: AppTheme.auxiliaryColor1.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
