import 'dart:io';
import 'dart:ui' as ui;
import 'package:flov/domain/models/book/book.dart';
import 'package:flov/domain/models/sort/sort.dart';
import 'package:flov/theme/app_theme.dart';
import 'package:flov/ui/tools/widgets/tools_screen.dart';
import 'package:flov/ui/settings/settings_screen.dart';
import 'package:flov/ui/tabs/vm/tabs_vm.dart';
import 'package:flov/ui/tabs/widgets/tabs.dart';
import 'package:flov/ui/viewer/widgets/reader_screen.dart';
// import 'package:flov/domain/models/bookshelf.dart';
// import 'package:flov/domain/models/sort_option.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../../utils/file_utils.dart';

import '../vm/dashboard_vm.dart';

part 'book_card.dart';
part 'shelf.dart';

// 定义导航项数据结构
class NavItem {
  final String id;
  final String title;
  final IconData icon;

  NavItem({
    required this.id,
    required this.title,
    required this.icon,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  // 定义导航项
  final List<NavItem> _navItems = [
    NavItem(
      id: 'tools',
      title: 'PDF工具',
      icon: PhosphorIconsRegular.filePdf,
    ),
    NavItem(
      id: 'settings',
      title: '设置',
      icon: PhosphorIconsRegular.gear,
    ),
  ];

  // 添加一个状态变量，用于控制导航栏的显示
  bool _isNavBarVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).loadBooks();
    });
  }

  // 打开新标签页
  void _openNewTab(String tabId) {
    TabItem? tabItem;
    if (tabId == 'tools') {
      tabItem = TabItem(
        id: 'tools',
        title: 'PDF工具',
        icon: PhosphorIconsRegular.filePdf,
        content: const PDFToolsScreen(),
      );
    } else if (tabId == 'settings') {
      tabItem = TabItem(
        id: 'settings',
        title: '设置',
        icon: PhosphorIconsRegular.gear,
        content: const SettingsScreen(),
      );
    }
    // 使用全局AppTabController打开新标签页
    if (tabItem != null) {
      AppTabController().addTab(tabItem);
    }
  }

  // 构建导航项
  Widget _buildNavItem(NavItem item) {
    return GestureDetector(
      onTap: () => _openNewTab(item.id),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.transparent,
        ),
        child: Tooltip(
          message: item.title,
          child: Icon(
            item.icon,
            color: AppTheme.auxiliaryColor1.withOpacity(0.7),
            size: 20,
          ),
        ),
      ),
    );
  }

  // 显示提示对话框
  Future<void> _showAlreadyExistsDialog(String fileName) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('添加失败'),
          content: Text('《$fileName》已经存在于书架中。'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.watch<DashboardViewModel>();
    final theme = Theme.of(context);

    return Consumer<DashboardViewModel>(builder: (context, dashboardVm, child) {
      return Container(
          color: theme.colorScheme.surfaceContainerLowest,
          child: Row(
            children: [
              // 左侧导航栏区域
              Stack(
                children: [
                  // 实际的导航栏
                  MouseRegion(
                    onExit: (_) => setState(() => _isNavBarVisible = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: _isNavBarVisible ? 48 : 8,
                      color: AppTheme.auxiliaryColor2Light,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isNavBarVisible ? 1.0 : 0.0,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            ..._navItems
                                .map((item) => _buildNavItem(item))
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 透明的检测区域，比实际导航栏宽，更容易触发
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 20, // 更宽的检测区域
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isNavBarVisible = true),
                      child: Container(
                        color: Colors.transparent, // 透明区域
                      ),
                    ),
                  ),
                ],
              ),
              // 右侧内容区域
              Expanded(
                child: 
                
                Column(
                  children: [
                    // 自定义顶栏，与左侧栏风格一致
                    Container(
                      height: 40,
                      margin: const EdgeInsets.only(top: 32, left: 24, right: 24),
                      // padding:
                      //     const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('我的文件',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          Row(children: [
                            // 同步按钮

                            PopupMenuButton<SortOption>(
                              icon: Icon(
                                PhosphorIconsRegular.sortAscending,
                                color: theme.colorScheme.onSurface,
                              ),
                              tooltip: '排序方式',
                              offset: const Offset(0, 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.grey.withOpacity(0.1),
                                ),
                              ),
                              elevation: 4,
                              color: Theme.of(context).colorScheme.surface,
                              itemBuilder: (context) =>
                                  SortOption.values.map((option) {
                                return PopupMenuItem<SortOption>(
                                  value: option,
                                  height: 40, // 调整菜单项高度
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              onSelected: (option) =>
                                  dashboardVm.setSortOption(option),
                            ),

                            // 添加文件按钮
                            FilledButton(
                              child: const Text('添加'),
                              // style: FilledButton.styleFrom(
                              //   shape: RoundedRectangleBorder(
                              //     borderRadius:
                              //         BorderRadius.circular(3.0), // 修改这里的值来调整圆角大小
                              //   ),
                              // ),
                              onPressed: () async {
                                // 打开文件选择器
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf'], // 根据需要添加允许的文件类型
                                );
                                if (result != null &&
                                    result.files.single.path != null) {
                                  String filePath = result.files.single.path!;
                                  String fileName =
                                      result.files.single.name.split('.').first;
                                  print(filePath);
                                  // 检查文件是否已经存在
                                  if (dashboardState.isBookExists(filePath)) {
                                    // 显示提示对话框
                                    await _showAlreadyExistsDialog(fileName);
                                  } else {
                                    debugPrint('添加成功');
                                    final int id = dashboardState.books.length;
                                    String md5 =
                                        await FileUtils.calculateFileHash(
                                            filePath);
                                    dashboardState.addBook(Book(
                                        md5, fileName, filePath, '')); // 存储文件路径
                                  }
                                }
                              },
                            ),
                          ])
                        ],
                      ),
                    ),

                    Expanded(

                      child: 
                      Container(
                        margin: const EdgeInsets.only(top: 24, left: 24, right: 24),
                        child:

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const SizedBox(height: 10),
                          // const SizedBox(height: 20),
                          Expanded(
                            child: BookshelfWidget(),
                          ),
                        ],
                      )),
                    ),
                  ],
                ),
              )
            ],
          ));
    });
  }
}

class CupertinoListTile extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final VoidCallback onTap;

  CupertinoListTile({
    required this.leading,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 16),
            title,
          ],
        ),
      ),
    );
  }
}

String _formatFileSize(int size) {
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  var i = 0;
  double s = size.toDouble();
  while (s >= 1024 && i < suffixes.length - 1) {
    s /= 1024;
    i++;
  }
  return '${s.toStringAsFixed(2)} ${suffixes[i]}';
}
