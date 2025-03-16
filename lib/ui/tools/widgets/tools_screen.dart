import 'package:flov/ui/tabs/vm/tabs_vm.dart';
import 'package:flov/ui/tabs/widgets/tabs.dart';
import 'package:flov/ui/tools/widgets/extract.dart';
import 'package:flov/ui/tools/widgets/merge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PDFToolsScreen extends StatefulWidget {
  const PDFToolsScreen({Key? key}) : super(key: key);

  @override
  State<PDFToolsScreen> createState() => _PDFToolsScreenState();
}

class _PDFToolsScreenState extends State<PDFToolsScreen> {
  String _selectedCategory = '所有工具';
  final List<String> _categories = ['所有工具', '转换工具', '编辑工具', '安全工具'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 页面标题
            _buildHeader(colorScheme),
            const SizedBox(height: 24),

            // 工具分类
            _buildCategoryTabs(colorScheme),
            const SizedBox(height: 32),

            // 常用工具
            _buildToolSection(
              title: '常用工具',
              colorScheme: colorScheme,
              tools: [
                ToolItem(
                  title: 'PDF 转换',
                  description: '将 PDF 文件转换为其他格式，或将其他格式转换为 PDF',
                  icon: PhosphorIconsRegular.arrowsLeftRight,
                  tag: '支持多种格式',
                  onTap: () {
                    // TODO: 实现 PDF 转换功能
                  },
                ),
                ToolItem(
                  title: 'PDF 合并',
                  description: '将多个 PDF 文件合并为一个文档，可调整顺序',
                  icon: PhosphorIconsRegular.chatCenteredText,
                  tag: '支持拖放排序',
                  onTap: () {
                    // 新标签页
                    // TabController
                    AppTabController().addTab(TabItem(
                      id: 'pdf_merge',
                      title: 'PDF 合并',
                      icon: PhosphorIconsRegular.chatCenteredText,
                      content: PDFMergeScreen(),
                    ));
                  },
                ),
                ToolItem(
                  title: 'PDF 分割',
                  description: '将 PDF 文件分割为多个独立文档，可按页码或范围',
                  icon: PhosphorIconsRegular.scissors,
                  tag: '支持多种分割方式',
                  onTap: () {
                    // 新标签页
                    // TabController
                    AppTabController().addTab(TabItem(
                      id: 'pdf_split',
                      title: 'PDF 分割',
                      icon: PhosphorIconsRegular.scissors,
                      content: PDFExtractScreen(),
                    ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 转换工具
            _buildToolSection(
              title: '转换工具',
              colorScheme: colorScheme,
              tools: [
                ToolItem(
                  title: 'PDF 转 Word',
                  description: '将 PDF 文件转换为可编辑的 Word 文档',
                  icon: PhosphorIconsRegular.fileDoc,
                  tag: '保留原始格式',
                  onTap: () {
                    // TODO: 实现 PDF 转 Word 功能
                  },
                ),
                ToolItem(
                  title: 'PDF 转 Excel',
                  description: '将 PDF 表格转换为可编辑的 Excel 电子表格',
                  icon: PhosphorIconsRegular.table,
                  tag: '自动识别表格',
                  onTap: () {
                    // TODO: 实现 PDF 转 Excel 功能
                  },
                ),
                ToolItem(
                  title: 'PDF 转 PPT',
                  description: '将 PDF 文件转换为可编辑的 PowerPoint 演示文稿',
                  icon: PhosphorIconsRegular.presentation,
                  tag: '保留幻灯片布局',
                  onTap: () {
                    // TODO: 实现 PDF 转 PPT 功能
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 编辑工具
            _buildToolSection(
              title: '编辑工具',
              colorScheme: colorScheme,
              tools: [
                ToolItem(
                  title: 'PDF 压缩',
                  description: '减小 PDF 文件大小，保持适当的质量',
                  icon: PhosphorIconsRegular.arrowDown,
                  tag: '多级压缩选项',
                  onTap: () {
                    // TODO: 实现 PDF 压缩功能
                  },
                ),
                ToolItem(
                  title: '页面编辑',
                  description: '旋转、删除或重新排序 PDF 文件中的页面',
                  icon: PhosphorIconsRegular.pencilSimple,
                  tag: '批量处理页面',
                  onTap: () {
                    // TODO: 实现页面编辑功能
                  },
                ),
                ToolItem(
                  title: 'PDF OCR',
                  description: '识别扫描文档中的文本，使其可搜索和编辑',
                  icon: PhosphorIconsRegular.textT,
                  tag: '支持多种语言',
                  onTap: () {
                    // TODO: 实现 PDF OCR 功能
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 安全工具
            _buildToolSection(
              title: '安全工具',
              colorScheme: colorScheme,
              tools: [
                ToolItem(
                  title: 'PDF 加密',
                  description: '使用密码保护 PDF 文件，限制查看或编辑',
                  icon: PhosphorIconsRegular.lock,
                  tag: '高级加密选项',
                  onTap: () {
                    // TODO: 实现 PDF 加密功能
                  },
                ),
                ToolItem(
                  title: 'PDF 解密',
                  description: '移除 PDF 文件的密码保护和使用限制',
                  icon: PhosphorIconsRegular.lockOpen,
                  tag: '需要授权密码',
                  onTap: () {
                    // TODO: 实现 PDF 解密功能
                  },
                ),
                ToolItem(
                  title: 'PDF 水印',
                  description: '为 PDF 文件添加文本或图像水印，保护文档版权',
                  icon: PhosphorIconsRegular.cloud,
                  tag: '自定义水印样式',
                  onTap: () {
                    // TODO: 实现 PDF 水印功能
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF 工具',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '管理您的 PDF 文件，轻松高效',
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border(
                        bottom: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      )
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolSection({
    required String title,
    required ColorScheme colorScheme,
    required List<ToolItem> tools,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return ToolCard(
              title: tool.title,
              description: tool.description,
              icon: tool.icon,
              tag: tool.tag,
              onTap: tool.onTap,
              colorScheme: colorScheme,
            );
          },
        ),
      ],
    );
  }
}

class ToolItem {
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;

  ToolItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
    required this.onTap,
  });
}

class ToolCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String tag;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const ToolCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.tag,
    required this.onTap,
    required this.colorScheme,
  }) : super(key: key);

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering
                  ? widget.colorScheme.primary
                  : widget.colorScheme.outlineVariant,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.colorScheme.shadow.withOpacity(_isHovering ? 0.08 : 0.05),
                blurRadius: _isHovering ? 8 : 4,
                offset: Offset(0, _isHovering ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标和标题
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? widget.colorScheme.primary
                          : widget.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _isHovering
                          ? widget.colorScheme.onPrimary
                          : widget.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 描述
              Expanded(
                child: Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 标签和箭头
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.tag,
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    PhosphorIconsRegular.caretRight,
                    color: widget.colorScheme.primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
