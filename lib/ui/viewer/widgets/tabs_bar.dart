import 'package:flov/domain/models/tab/pdf_tab.dart';
import 'package:flov/ui/viewer/vm/tabs_vm.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

/// PDF阅读器的标签页栏组件
class TabsBar extends StatelessWidget {
  const TabsBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tabsVm = Provider.of<TabsViewModel>(context);
    final tabs = tabsVm.tabs;
    var theme = Theme.of(context);
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow, // 与阅读器背景颜色一致
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标签页列表
          Expanded(
            child: tabs.isEmpty
                ? const Center(
                    child: Text(
                      '没有打开的文档',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: tabs.length,
                    itemBuilder: (context, index) {
                      final tab = tabs[index];
                      final isActive = index == tabsVm.activeTabIndex;
                      
                      return _buildTabItem(context, tab, index, isActive);
                    },
                  ),
          ),
          
          // 添加新标签页按钮
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey.withOpacity(0.15),
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: Colors.black54,
                size: 16,
              ),
              onPressed: () async {
                // 直接在这里处理打开新文件的逻辑
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                
                if (result != null && result.files.single.path != null) {
                  // 通知 ReaderScreen 打开新文件
                  if (context.mounted) {
                    // 使用通知机制通知 ReaderScreen 打开新文件
                    TabsNotification(filePath: result.files.single.path!).dispatch(context);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单个标签页项
  Widget _buildTabItem(BuildContext context, PdfTab tab, int index, bool isActive) {
    final tabsVm = Provider.of<TabsViewModel>(context, listen: false);
    
    return GestureDetector(
      onTap: () => tabsVm.switchToTab(index),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 200),
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.6) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          border: isActive
              ? Border(
                  left: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  top: BorderSide(color: Colors.grey.withOpacity(0.5)),
                  right: BorderSide(color: Colors.grey.withOpacity(0.5)),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 文档图标
            Icon(
              PhosphorIconsRegular.filePdf,
              size: 14,
              color: isActive ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 4),
            
            // 标签标题
            Flexible(
              child: Text(
                tab.title,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.black87 : Colors.grey,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 关闭按钮
            CupertinoButton(
              padding: const EdgeInsets.all(4),
              child: Icon(
                PhosphorIconsRegular.x,
                size: 14,
                color: isActive ? Colors.black54 : Colors.grey,
              ),
              onPressed: () => tabsVm.closeTab(index),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用于通知 ReaderScreen 打开新文件的通知
class TabsNotification extends Notification {
  final String filePath;
  
  TabsNotification({required this.filePath});
} 