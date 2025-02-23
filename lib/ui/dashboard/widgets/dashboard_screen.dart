import 'dart:io';
import 'dart:ui' as ui;
import 'package:flowverse/data/repositories/book/book_repository.dart';
import 'package:flowverse/domain/models/book/book.dart';
import 'package:flowverse/domain/models/sort/sort.dart';
// import 'package:flowverse/domain/models/bookshelf.dart';
// import 'package:flowverse/domain/models/sort_option.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../utils/file_utils.dart';

import '../../viewer/widgets/reader_screen.dart'; // 导入阅读器页面
import '../vm/dashboard_vm.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(bookRepository: BookRepository()),
      child: const DashboardScreenInner(),
    );
  }
}

class DashboardScreenInner extends StatefulWidget {
  const DashboardScreenInner({super.key});

  @override
  DashboardScreenInnerState createState() => DashboardScreenInnerState();
}

class DashboardScreenInnerState extends State<DashboardScreenInner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardViewModel>(context, listen: false).loadBooks();
    });
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

    return Consumer<DashboardViewModel>(
      builder: (context, dashboardVm, child) {
        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: const Text('书架'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(PhosphorIconsLight.sortAscending),
              onPressed: () {
                showCupertinoModalPopup(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoActionSheet(
                      title: const Text('排序方式'),
                      message: Text(
                          '当前排序：${dashboardVm.currentSortOption.label} (${dashboardVm.sortDirection.label})'),
                      actions: SortOption.values.map((option) {
                        return CupertinoActionSheetAction(
                          child: Text(option.label),
                          onPressed: () {
                            dashboardVm.setSortOption(option);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                      cancelButton: CupertinoActionSheetAction(
                        isDestructiveAction: true,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('取消'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          child: Row(
            children: [
              // 左侧选项
              Container(
                width: 200,
                color: CupertinoColors.systemGrey5,
                child: CupertinoScrollbar(
                  child: ListView(
                    children: [
                      CupertinoListTile(
                        leading: const Icon(PhosphorIconsLight.house),
                        title: const Text('主页'),
                        onTap: () {
                          // 处理主页点击事件
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(PhosphorIconsLight.book),
                        title: const Text('PDF 工具集'),
                        onTap: () {
                          // 处理书架点击事件
                        },
                      ),
                      CupertinoListTile(
                        leading: const Icon(PhosphorIconsLight.gear),
                        title: const Text('设置'),
                        onTap: () {
                          // 处理设置点击事件
                        },
                      ),
                      // 可以添加更多选项
                    ],
                  ),
                ),
              ),
              // 右侧书架
              Expanded(
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: BookshelfWidget(),
                    ),
                    // 浮动的"添加"按钮
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(16),
                        color: CupertinoColors.activeBlue,
                        borderRadius: BorderRadius.circular(30),
                        child: const Icon(
                          PhosphorIconsLight.plus,
                          color: CupertinoColors.white,
                          size: 28,
                        ),
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
                              dashboardState.addBook(Book(
                                  id + 1, fileName, filePath, '')); // 存储文件路径
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
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

// ##################################################################
// 书籍封面

class Cover extends StatefulWidget {
  final String filePath;

  const Cover({Key? key, required this.filePath}) : super(key: key);

  @override
  State<Cover> createState() => _CoverState();
}

class _CoverState extends State<Cover> {
  PdfDocument? _document;
  PdfPage? _page;
  bool _isLoading = true;
  String? _error;
  ui.Image? _thumbnail;
  String? _fileHash;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      // 计算文件哈希
      _fileHash = await FileUtils.calculateFileHash(widget.filePath);

      // 检查缓存
      final cachedImage =
          await DefaultCacheManager().getFileFromCache(_fileHash!);

      if (cachedImage != null && cachedImage.file.existsSync()) {
        final bytes = await cachedImage.file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frameInfo = await codec.getNextFrame();
        _thumbnail = frameInfo.image;
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _document = await PdfDocument.openFile(widget.filePath);
      _page = await _document!.pages[0];

      // 使用固定的缩略图尺寸
      final targetWidth = 200.0;
      final targetHeight = (targetWidth / _page!.width * _page!.height);

      final pdfImage = await _page!.render(
        fullWidth: targetWidth,
        fullHeight: targetHeight,
      );

      _thumbnail = await pdfImage?.createImage();

      // 缓存缩略图
      if (_thumbnail != null) {
        final byteData =
            await _thumbnail!.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          await DefaultCacheManager().putFile(
            _fileHash!,
            byteData.buffer.asUint8List(),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _resetState() {
    // 清理旧资源
    _thumbnail?.dispose();
    _thumbnail = null;

    _document?.dispose();
    _document = null;

    _page = null;
    _fileHash = null;
    _error = null;
    _isLoading = true;
  }

  @override
  void didUpdateWidget(Cover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 filePath 发生变化，重新加载缩略图
    if (oldWidget.filePath != widget.filePath) {
      _resetState();
      _loadThumbnail();
    }
  }

  @override
  void dispose() {
    _thumbnail?.dispose();
    _document?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_error != null || _thumbnail == null) {
      return Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Center(
          child: Icon(PhosphorIconsLight.fileText,
              size: 48, color: CupertinoColors.systemGrey),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        child: _thumbnail != null
            ? RawImage(
                image: _thumbnail,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : const Center(
                child: Icon(PhosphorIconsLight.fileText,
                    size: 48, color: CupertinoColors.systemGrey),
              ),
      ),
    );
  }
}

class BookshelfWidget extends StatelessWidget {
  BookshelfWidget();

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.watch<DashboardViewModel>();
    var books = dashboardState.books;

    return books.isEmpty
        ? const Center(
            child: Text(
              '书架为空，点击右下角添加书籍',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          )
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              // liverGridDelegateWithFixedCrossAxisCount(
              // crossAxisCount: 5,
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              String filePath = books[index].path;
              String fileName = books[index].name;
              final GlobalKey _menuKey = GlobalKey();
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => ReaderScreen(filePath: filePath),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Cover(filePath: filePath),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                color: CupertinoColors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        key: _menuKey,
                        onTap: () async {
                          final RenderBox button = _menuKey.currentContext!
                              .findRenderObject() as RenderBox;
                          final RenderBox overlay = Navigator.of(context)
                              .overlay!
                              .context
                              .findRenderObject() as RenderBox;

                          // 获取按钮相对于 Overlay 的位置
                          final buttonPosition = button
                              .localToGlobal(Offset.zero, ancestor: overlay);

                          // 获取按钮的大小
                          final buttonSize = button.size;

                          // 计算菜单位置
                          final menuPosition = RelativeRect.fromRect(
                            Rect.fromPoints(
                              buttonPosition,
                              buttonPosition.translate(
                                  buttonSize.width, buttonSize.height),
                            ),
                            Offset.zero & overlay.size,
                          );

                          await showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                              buttonPosition.dx - 120, // 向左偏移以对齐菜单
                              menuPosition.top,
                              buttonPosition.dx,
                              menuPosition.top + buttonSize.height,
                            ),
                            items: <PopupMenuEntry>[
                              PopupMenuItem(
                                child: const Text('从书架上删除'),
                                onTap: () async {
                                  // 处理删除
                                  await dashboardState.removeBook(books[index]);
                                },
                              ),
                              // PopupMenuItem(
                              //   child: Text('编辑'),
                              //   onTap: () {
                              //     // 处理编辑
                              //   },
                              // ),
                              PopupMenuItem(
                                child: const Text('详细信息'),
                                onTap: () {
                                  final book = books[index];
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('文件详细信息'),
                                      content: FutureBuilder<FileStat>(
                                        future: File(book.path).stat(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return const CupertinoActivityIndicator();
                                          }

                                          final stat = snapshot.data!;
                                          final fileSize = stat.size;
                                          final modified =
                                              stat.modified.toLocal();

                                          return Column(
                                            children: [
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('文件名：',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Expanded(
                                                    child: Text(book.name,
                                                        style: const TextStyle(
                                                            color: CupertinoColors
                                                                .systemGrey)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('路径：',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Expanded(
                                                    child: Text(book.path,
                                                        style: const TextStyle(
                                                            color: CupertinoColors
                                                                .systemGrey)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('大小：',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                    _formatFileSize(fileSize),
                                                    style: const TextStyle(
                                                        color: CupertinoColors
                                                            .systemGrey),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Text('修改时间：',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  Text(
                                                    '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} ${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(
                                                        color: CupertinoColors
                                                            .systemGrey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('确定'),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // PopupMenuItem(
                              //   child: Text('更多操作'),
                              //   onTap: () {
                              //     // 处理更多操作
                              //   },
                              // ),
                            ],
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    CupertinoColors.systemGrey.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            PhosphorIconsLight.dotsThree,
                            color: CupertinoColors.black,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
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
