import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PDFMergeScreen extends StatefulWidget {
  const PDFMergeScreen({Key? key}) : super(key: key);

  @override
  State<PDFMergeScreen> createState() => _PDFMergeScreenState();
}

class _PDFMergeScreenState extends State<PDFMergeScreen> {
  final TextEditingController _outputFileNameController =
      TextEditingController();
  String? _selectedSavePath;

  // 模拟文件数据
  final List<PDFFile> _files = [
    PDFFile(
      name: 'document1.pdf',
      size: 2.5,
      pages: 10,
    ),
    PDFFile(
      name: 'document2.pdf',
      size: 1.8,
      pages: 8,
    ),
  ];

  @override
  void dispose() {
    _outputFileNameController.dispose();
    super.dispose();
  }

  // 计算总文件数
  int get totalFiles => _files.length;

  // 计算总页数
  int get totalPages => _files.fold(0, (sum, file) => sum + file.pages);

  // 计算总大小
  double get totalSize => _files.fold(0.0, (sum, file) => sum + file.size);

  // 计算预计合并后大小（假设有5%的压缩）
  double get estimatedMergedSize => totalSize * 0.95;

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
            child: Row(
              children: [
                Icon(
                  PhosphorIconsRegular.arrowsLeftRight,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'PDF 文件合并',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
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
                  // 左侧文件列表
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题和添加按钮
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '文件列表',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // 添加文件的逻辑
                                  },
                                  icon: Icon(
                                    PhosphorIconsRegular.plus,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                  label: const Text('添加文件'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: colorScheme.outlineVariant),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 文件列表
                          Expanded(
                            child: ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                              itemCount: _files.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = _files.removeAt(oldIndex);
                                  _files.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                return FileItem(
                                  key: ValueKey(file.name),
                                  file: file,
                                  colorScheme: colorScheme,
                                  onDelete: () {
                                    setState(() {
                                      _files.removeAt(index);
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 右侧设置区域
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 合并设置
                          Text(
                            '合并设置',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 输出文件名
                          Text(
                            '输出文件名',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _outputFileNameController,
                            decoration: InputDecoration(
                              hintText: '请输入输出文件名',
                              hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 保存位置
                          Text(
                            '保存位置',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: colorScheme.outlineVariant),
                                  ),
                                  child: Text(
                                    _selectedSavePath ?? '选择保存位置',
                                    style: TextStyle(
                                      color: _selectedSavePath != null
                                          ? colorScheme.onSurface
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {
                                  // 选择保存位置的逻辑
                                  setState(() {
                                    _selectedSavePath = '/Documents/PDFs';
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: colorScheme.outlineVariant),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                child: const Text('浏览'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 文件信息
                          Text(
                            '文件信息',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        '总文件数',
                                        '$totalFiles 个文件',
                                        colorScheme,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        '总页数',
                                        '$totalPages 页',
                                        colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoItem(
                                        '总大小',
                                        '${totalSize.toStringAsFixed(1)} MB',
                                        colorScheme,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildInfoItem(
                                        '预计合并后大小',
                                        '${estimatedMergedSize.toStringAsFixed(1)} MB',
                                        colorScheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 操作按钮
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.outlineVariant,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    // 取消操作的逻辑
                                    Navigator.of(context).pop();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: colorScheme.outlineVariant),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _files.isEmpty
                                      ? null
                                      : () {
                                          // 开始合并的逻辑
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    disabledBackgroundColor:
                                        colorScheme.surfaceContainerHighest,
                                    disabledForegroundColor:
                                        colorScheme.onSurfaceVariant,
                                  ),
                                  child: const Text('开始合并'),
                                ),
                              ],
                            ),
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
    );
  }

  Widget _buildInfoItem(String title, String value, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class PDFFile {
  final String name;
  final double size; // MB
  final int pages;

  PDFFile({
    required this.name,
    required this.size,
    required this.pages,
  });
}

class FileItem extends StatelessWidget {
  final PDFFile file;
  final VoidCallback onDelete;
  final ColorScheme colorScheme;

  const FileItem({
    Key? key,
    required this.file,
    required this.onDelete,
    required this.colorScheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIconsRegular.arrowsVertical,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 12),
            Icon(
              PhosphorIconsRegular.filePdf,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
        title: Text(
          file.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          '${file.size} MB • ${file.pages} 页',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            PhosphorIconsRegular.trash,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onDelete,
          splashRadius: 20,
          hoverColor: colorScheme.error.withOpacity(0.1),
          tooltip: '删除',
        ),
      ),
    );
  }
}
