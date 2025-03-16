import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = '常规';
  final List<NavItem> _navItems = [
    NavItem(title: '常规', icon: PhosphorIconsRegular.gear),
    NavItem(title: '阅读', icon: PhosphorIconsRegular.book),
    NavItem(title: '批注', icon: PhosphorIconsRegular.pencilSimple),
    NavItem(title: '性能', icon: PhosphorIconsRegular.lightning),
    NavItem(title: '快捷键', icon: PhosphorIconsRegular.keyboard),
  ];

  // 设置选项状态
  String _selectedLanguage = '中文';
  String _selectedTheme = '浅色';
  String _startupOption = '打开主页';
  bool _autoCheckUpdates = true;
  bool _collectAnonymousData = false;
  String _readingMode = '单页';
  double _zoomLevel = 100;
  String _pageTransition = '滑动';
  int _preloadPages = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 页面标题
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '设置',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '自定义您的PDF阅读器以获得最佳体验',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 主体内容
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 左侧导航
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = _selectedSection == item.title;
                        return NavItemWidget(
                          title: item.title,
                          icon: item.icon,
                          isSelected: isSelected,
                          colorScheme: colorScheme,
                          onTap: () {
                            setState(() {
                              _selectedSection = item.title;
                            });
                          },
                        );
                      },
                    ),
                  ),

                  // 右侧内容
                  Expanded(
                    child: _buildSettingsContent(colorScheme),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent(ColorScheme colorScheme) {
    // 根据选中的部分显示不同的设置内容
    switch (_selectedSection) {
      case '常规':
        return _buildGeneralSettings(colorScheme);
      case '阅读':
        return _buildReadingSettings(colorScheme);
      case '批注':
        return _buildAnnotationSettings(colorScheme);
      case '性能':
        return _buildPerformanceSettings(colorScheme);
      case '快捷键':
        return _buildShortcutSettings(colorScheme);
      default:
        return _buildGeneralSettings(colorScheme);
    }
  }

  Widget _buildGeneralSettings(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '常规设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // 语言设置
          SettingSection(
            title: '语言',
            subtitle: '选择应用界面语言',
            colorScheme: colorScheme,
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: '中文',
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value!;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                    const Text('中文'),
                    const SizedBox(width: 24),
                    Radio<String>(
                      value: 'English',
                      groupValue: _selectedLanguage,
                      onChanged: (value) {
                        setState(() {
                          _selectedLanguage = value!;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                    const Text('English'),
                  ],
                ),
              ],
            ),
          ),

          // 主题设置
          SettingSection(
            title: '主题',
            subtitle: '选择应用界面主题',
            colorScheme: colorScheme,
            child: Row(
              children: [
                // 浅色主题
                ThemeOption(
                  title: '浅色',
                  isSelected: _selectedTheme == '浅色',
                  colorScheme: colorScheme,
                  onTap: () {
                    setState(() {
                      _selectedTheme = '浅色';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 24,
                          color: colorScheme.primary,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  height: 8,
                                  color: colorScheme.outlineVariant.withOpacity(0.5),
                                  margin: const EdgeInsets.only(bottom: 4),
                                ),
                                Container(
                                  height: 8,
                                  width: 60,
                                  color: colorScheme.outlineVariant.withOpacity(0.5),
                                  margin: const EdgeInsets.only(bottom: 4),
                                ),
                                Container(
                                  height: 8,
                                  width: 40,
                                  color: colorScheme.outlineVariant.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 深色主题
                ThemeOption(
                  title: '深色',
                  isSelected: _selectedTheme == '深色',
                  colorScheme: colorScheme,
                  onTap: () {
                    setState(() {
                      _selectedTheme = '深色';
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 24,
                          color: colorScheme.primary,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  height: 8,
                                  color: Colors.white.withOpacity(0.2),
                                  margin: const EdgeInsets.only(bottom: 4),
                                ),
                                Container(
                                  height: 8,
                                  width: 60,
                                  color: Colors.white.withOpacity(0.2),
                                  margin: const EdgeInsets.only(bottom: 4),
                                ),
                                Container(
                                  height: 8,
                                  width: 40,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 启动设置
          SettingSection(
            title: '启动设置',
            subtitle: '设置应用启动时的行为',
            colorScheme: colorScheme,
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('打开主页'),
                  value: '打开主页',
                  groupValue: _startupOption,
                  onChanged: (value) {
                    setState(() {
                      _startupOption = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('打开最后阅读的文档'),
                  value: '打开最后阅读的文档',
                  groupValue: _startupOption,
                  onChanged: (value) {
                    setState(() {
                      _startupOption = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('显示打开文件对话框'),
                  value: '显示打开文件对话框',
                  groupValue: _startupOption,
                  onChanged: (value) {
                    setState(() {
                      _startupOption = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],
            ),
          ),

          // 自动检查更新
          SettingSection(
            title: '自动检查更新',
            subtitle: '应用启动时自动检查新版本',
            colorScheme: colorScheme,
            child: Switch(
              value: _autoCheckUpdates,
              onChanged: (value) {
                setState(() {
                  _autoCheckUpdates = value;
                });
              },
              activeColor: colorScheme.primary,
            ),
          ),

          // 匿名使用数据收集
          SettingSection(
            title: '匿名使用数据收集',
            subtitle: '帮助我们改进产品（不包含个人信息）',
            colorScheme: colorScheme,
            child: Switch(
              value: _collectAnonymousData,
              onChanged: (value) {
                setState(() {
                  _collectAnonymousData = value;
                });
              },
              activeColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingSettings(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '阅读设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // 默认阅读模式
          SettingSection(
            title: '默认阅读模式',
            subtitle: '设置打开文档时的默认显示方式',
            colorScheme: colorScheme,
            child: Row(
              children: [
                // 单页模式
                ReadingModeOption(
                  title: '单页',
                  isSelected: _readingMode == '单页',
                  colorScheme: colorScheme,
                  onTap: () {
                    setState(() {
                      _readingMode = '单页';
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 双页模式
                ReadingModeOption(
                  title: '双页',
                  isSelected: _readingMode == '双页',
                  colorScheme: colorScheme,
                  onTap: () {
                    setState(() {
                      _readingMode = '双页';
                    });
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // 连续模式
                ReadingModeOption(
                  title: '连续',
                  isSelected: _readingMode == '连续',
                  colorScheme: colorScheme,
                  onTap: () {
                    setState(() {
                      _readingMode = '连续';
                    });
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 默认缩放比例
          SettingSection(
            title: '默认缩放比例',
            subtitle: '设置文档的默认显示大小',
            colorScheme: colorScheme,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '缩放级别',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_zoomLevel.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _zoomLevel,
                  min: 50,
                  max: 200,
                  divisions: 15,
                  onChanged: (value) {
                    setState(() {
                      _zoomLevel = value;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50%',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '200%',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 翻页动画
          SettingSection(
            title: '翻页动画',
            subtitle: '设置翻页时的过渡效果',
            colorScheme: colorScheme,
            child: Row(
              children: [
                Radio<String>(
                  value: '滑动',
                  groupValue: _pageTransition,
                  onChanged: (value) {
                    setState(() {
                      _pageTransition = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('滑动'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: '淡入淡出',
                  groupValue: _pageTransition,
                  onChanged: (value) {
                    setState(() {
                      _pageTransition = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('淡入淡出'),
                const SizedBox(width: 16),
                Radio<String>(
                  value: '无动画',
                  groupValue: _pageTransition,
                  onChanged: (value) {
                    setState(() {
                      _pageTransition = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('无动画'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationSettings(ColorScheme colorScheme) {
    // 批注颜色选项
    final List<Color> annotationColors = [
      const Color(0xFFFFA726), // 橙色
      const Color(0xFFFFD54F), // 浅黄色
      const Color(0xFFEF5350), // 红色
      const Color(0xFF42A5F5), // 浅蓝色
      const Color(0xFF5C6BC0), // 靛蓝色
      const Color(0xFF66BB6A), // 绿色
      const Color(0xFF78909C), // 蓝灰色
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '批注设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // 默认批注颜色
          SettingSection(
            title: '默认批注颜色',
            subtitle: '设置批注工具的默认颜色',
            colorScheme: colorScheme,
            child: Row(
              children: annotationColors.map((color) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ColorOption(
                    color: color,
                    isSelected: color == annotationColors[0],
                    onTap: () {
                      // 选择颜色的逻辑
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSettings(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性能设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // 预加载页数
          SettingSection(
            title: '预加载页数',
            subtitle: '设置当前页面前后预加载的页数',
            colorScheme: colorScheme,
            child: Row(
              children: [
                Radio<int>(
                  value: 1,
                  groupValue: _preloadPages,
                  onChanged: (value) {
                    setState(() {
                      _preloadPages = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('1页'),
                const SizedBox(width: 16),
                Radio<int>(
                  value: 3,
                  groupValue: _preloadPages,
                  onChanged: (value) {
                    setState(() {
                      _preloadPages = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('3页'),
                const SizedBox(width: 16),
                Radio<int>(
                  value: 5,
                  groupValue: _preloadPages,
                  onChanged: (value) {
                    setState(() {
                      _preloadPages = value!;
                    });
                  },
                  activeColor: colorScheme.primary,
                ),
                const Text('5页'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutSettings(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷键设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '自定义常用操作的快捷键',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // 快捷键列表
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // 文件操作
                _buildShortcutCategory('文件操作', colorScheme),
                _buildShortcutItem('打开文件', 'Ctrl + O', colorScheme),

                // 导航操作
                _buildShortcutCategory('导航操作', colorScheme),
                _buildShortcutItem('上一页', '←', colorScheme),

                // 视图操作
                _buildShortcutCategory('视图操作', colorScheme),
                _buildShortcutItem('全屏模式', 'F11', colorScheme),

                // 批注操作
                _buildShortcutCategory('批注操作', colorScheme),
                _buildShortcutItem('高亮文本', 'Ctrl + H', colorScheme),
              ],
            ),
          ),

          // 添加自定义快捷键按钮
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton.icon(
              onPressed: () {
                // 添加自定义快捷键的逻辑
              },
              icon: Icon(
                PhosphorIconsRegular.plus,
                color: colorScheme.primary,
              ),
              label: Text(
                '添加自定义快捷键',
                style: TextStyle(
                  color: colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
            ),
          ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [             
                     OutlinedButton(
                       onPressed: () {
                         // 恢复默认设置的逻辑
                       },
                       style: OutlinedButton.styleFrom(
                         side: BorderSide(color: colorScheme.outlineVariant),
                       ),
                       child: const Text('恢复默认设置'),
                     ),
                     const SizedBox(width: 12),
                     ElevatedButton(
                       onPressed: () {
                         // 保存设置的逻辑
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: colorScheme.primary,
                         foregroundColor: colorScheme.onPrimary,
                       ),
                       child: const Text('保存设置'),
                     ),
                    ],
                  ),
                ),
              ],
            ),
          );
          }
    //     ],
    //   ),
    // );
  // }
 
   Widget _buildShortcutCategory(String title, ColorScheme colorScheme) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
       color: colorScheme.surfaceContainerLow,
       child: Row(
         children: [
           Text(
             title,
             style: TextStyle(
               fontWeight: FontWeight.w500,
               color: colorScheme.onSurface,
             ),
           ),
         ],
       ),
     );
   }
 
   Widget _buildShortcutItem(String action, String shortcut, ColorScheme colorScheme) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
       decoration: BoxDecoration(
         border: Border(
           bottom: BorderSide(
             color: colorScheme.outlineVariant,
             width: 1,
           ),
         ),
       ),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(
             action,
             style: TextStyle(
               color: colorScheme.onSurface,
             ),
           ),
           Row(
             children: [
               _buildShortcutKey(shortcut, colorScheme),
               IconButton(
                 icon: Icon(
                   PhosphorIconsRegular.pencilSimple,
                   size: 16,
                   color: colorScheme.primary,
                 ),
                 onPressed: () {
                   // 编辑快捷键的逻辑
                 },
                 splashRadius: 20,
               ),
             ],
           ),
         ],
       ),
     );
   }
 
   Widget _buildShortcutKey(String shortcut, ColorScheme colorScheme) {
     final keys = shortcut.split(' + ');
     return Row(
       children: keys.asMap().entries.map((entry) {
         final index = entry.key;
         final key = entry.value;
         return Row(
           children: [
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: colorScheme.surfaceContainerHigh,
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Text(
                 key,
                 style: TextStyle(
                   fontFamily: 'monospace',
                   fontSize: 14,
                   color: colorScheme.onSurface,
                 ),
               ),
             ),
             if (index < keys.length - 1)
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 4),
                 child: Text(
                   '+',
                   style: TextStyle(
                     color: colorScheme.onSurfaceVariant,
                   ),
                 ),
               ),
           ],
         );
       }).toList(),
     );
   }
 }
 
 class NavItem {
   final String title;
   final IconData icon;
 
   NavItem({required this.title, required this.icon});
 }
 
 class NavItemWidget extends StatelessWidget {
   final String title;
   final IconData icon;
   final bool isSelected;
   final VoidCallback onTap;
   final ColorScheme colorScheme;
 
   const NavItemWidget({
     Key? key,
     required this.title,
     required this.icon,
     required this.isSelected,
     required this.onTap,
     required this.colorScheme,
   }) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(8),
       child: Container(
         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
         margin: const EdgeInsets.only(bottom: 8),
         decoration: BoxDecoration(
           color: isSelected
               ? colorScheme.primary.withOpacity(0.1)
               : Colors.transparent,
           borderRadius: BorderRadius.circular(8),
         ),
         child: Row(
           children: [
             Icon(
               icon,
               size: 20,
               color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
             ),
             const SizedBox(width: 12),
             Text(
               title,
               style: TextStyle(
                 color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                 fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
               ),
             ),
           ],
         ),
       ),
     );
   }
 }
 
 class SettingSection extends StatelessWidget {
   final String title;
   final String subtitle;
   final Widget child;
   final ColorScheme colorScheme;
 
   const SettingSection({
     Key? key,
     required this.title,
     required this.subtitle,
     required this.child,
     required this.colorScheme,
   }) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return Container(
       margin: const EdgeInsets.only(bottom: 24),
       padding: const EdgeInsets.only(bottom: 24),
       decoration: BoxDecoration(
         border: Border(
           bottom: BorderSide(
             color: colorScheme.outlineVariant,
             width: 1,
           ),
         ),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             title,
             style: TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.w500,
               color: colorScheme.onSurface,
             ),
           ),
           const SizedBox(height: 4),
           Text(
             subtitle,
             style: TextStyle(
               fontSize: 14,
               color: colorScheme.onSurfaceVariant,
             ),
           ),
           const SizedBox(height: 16),
           child,
         ],
       ),
     );
   }
 }
 
 class ThemeOption extends StatelessWidget {
   final String title;
   final bool isSelected;
   final VoidCallback onTap;
   final Widget child;
   final ColorScheme colorScheme;
 
   const ThemeOption({
     Key? key,
     required this.title,
     required this.isSelected,
     required this.onTap,
     required this.child,
     required this.colorScheme,
   }) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return Column(
       children: [
         InkWell(
           onTap: onTap,
           borderRadius: BorderRadius.circular(8),
           child: Container(
             width: 120,
             height: 90,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: isSelected ? colorScheme.primary : Colors.transparent,
                 width: 2,
               ),
             ),
             child: child,
           ),
         ),
         const SizedBox(height: 8),
         Text(
           title,
           style: TextStyle(
             fontSize: 14,
             color: colorScheme.onSurface,
             fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
           ),
         ),
       ],
     );
   }
 }
 
 class ReadingModeOption extends StatelessWidget {
   final String title;
   final bool isSelected;
   final VoidCallback onTap;
   final Widget child;
   final ColorScheme colorScheme;
 
   const ReadingModeOption({
     Key? key,
     required this.title,
     required this.isSelected,
     required this.onTap,
     required this.child,
     required this.colorScheme,
   }) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return Column(
       children: [
         InkWell(
           onTap: onTap,
           borderRadius: BorderRadius.circular(8),
           child: Container(
             width: 90,
             height: 120,
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                 color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                 width: isSelected ? 2 : 1,
               ),
             ),
             child: child,
           ),
         ),
         const SizedBox(height: 8),
         Text(
           title,
           style: TextStyle(
             fontSize: 14,
             color: colorScheme.onSurface,
             fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
           ),
         ),
       ],
     );
   }
 }
 
 class ColorOption extends StatelessWidget {
   final Color color;
   final bool isSelected;
   final VoidCallback onTap;
 
   const ColorOption({
     Key? key,
     required this.color,
     required this.isSelected,
     required this.onTap,
   }) : super(key: key);
 
   @override
   Widget build(BuildContext context) {
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(16),
       child: Container(
         width: 32,
         height: 32,
         decoration: BoxDecoration(
           color: color,
           shape: BoxShape.circle,
           border: isSelected
               ? Border.all(
                   color: Colors.white,
                   width: 2,
                 )
               : null,
           boxShadow: isSelected
               ? [
                   BoxShadow(
                     color: color.withOpacity(0.5),
                     blurRadius: 8,
                     spreadRadius: 2,
                   ),
                 ]
               : null,
         ),
       ),
     );
   }
 }


          // 底部按钮
//           Padding(
//             padding: const EdgeInsets.only(top: 32),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
               
//         ],
//       ),
//     );
//   }
// }
