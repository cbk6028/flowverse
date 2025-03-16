part of 'dashboard_screen.dart';

class BookshelfWidget extends StatefulWidget {
  BookshelfWidget();

  @override
  State<BookshelfWidget> createState() => _BookshelfWidgetState();
}

class _BookshelfWidgetState extends State<BookshelfWidget> {
  int? _hoveredIndex;
  bool _isDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final dashboardState = context.watch<DashboardViewModel>();
    var books = dashboardState.books;

    // 使用 DropRegion 包装整个书架，以支持拖放 PDF 文件
    return DropRegion(
      formats: [Formats.fileUri],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropEnter: (event) {
        setState(() {
          _isDraggingOver = true;
        });
      },
      onDropLeave: (event) {
        setState(() {
          _isDraggingOver = false;
        });
      },
      onDropOver: (event) {
        // 检查是否有文件被拖入
        final item = event.session.items.first;
        if (item.canProvide(Formats.fileUri)) {
          return DropOperation.copy;
        }
        return DropOperation.none;
      },
      onPerformDrop: (event) async {
        setState(() {
          _isDraggingOver = false;
        });

        // 处理拖放的文件
        final item = event.session.items.first;
        final reader = item.dataReader!;

        if (reader.canProvide(Formats.fileUri)) {
          reader.getValue<Uri>(Formats.fileUri, (value) async {
            if (value != null) {
              // 处理文件 URI
              final filePath = value.toFilePath();

              // 检查是否是 PDF 文件
              if (filePath.toLowerCase().endsWith('.pdf')) {
                // 获取文件名
                final fileName = filePath.split(Platform.pathSeparator).last;

                // 检查书籍是否已存在
                if (dashboardState.isBookExists(filePath)) {
                  // 显示已存在提示
                  _showAlreadyExistsDialog(context, fileName);
                } else {
                  // 创建新书籍并添加到书架
                  final book = Book(
                    '', // md5 可以后续计算
                    fileName,
                    filePath,
                    '', // 封面图片可以后续生成
                    fileFormat: 'PDF',
                  );

                  await dashboardState.addBook(book);
                }
              } else {
                // 显示不支持的文件格式提示
                _showUnsupportedFormatDialog(context);
              }
            }
          }, onError: (error) {
            print('Error reading file: $error');
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: _isDraggingOver
              ? Border.all(color: CupertinoColors.activeBlue, width: 2)
              : null,
        ),
        child: books.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '书架为空，点击右下角添加书籍',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                    if (_isDraggingOver)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text(
                          '或将 PDF 文件拖放到这里',
                          style: TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                padding: const EdgeInsets.all(16),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];

                  return BookCard(
                    book: book,
                    onTap: () {
                      // 使用AppTabController打开新标签页
                      AppTabController().addTab(TabItem(
                        id: book.path,
                        title: book.name,
                        icon: PhosphorIconsRegular.filePdf,
                        content: ReaderScreen(
                          filePath: book.path, 
                          book: book
                        ),
                      ));
                    },
                    onMoreOptions: () {
                      _showBookOptions(context, book, dashboardState);
                    },
                  );
                },
              ),
      ),
    );
  }

  // 显示书籍选项菜单
  void _showBookOptions(
      BuildContext context, Book book, DashboardViewModel dashboardState) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                // 打开书籍
                AppTabController().addTab(TabItem(
                  id: book.path,
                  title: book.name,
                  icon: PhosphorIconsRegular.filePdf,
                  content: ReaderScreen(filePath: book.path, book: book),
                ));
              },
              child: const Text('打开'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 实现收藏功能
              },
              child: const Text('收藏'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(context).pop();
                dashboardState.removeBook(book);
              },
              child: const Text('移出书架'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
        );
      },
    );
  }

  // 显示已存在提示对话框
  void _showAlreadyExistsDialog(BuildContext context, String fileName) {
    showCupertinoDialog<void>(
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

  // 显示不支持的文件格式提示对话框
  void _showUnsupportedFormatDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('不支持的文件格式'),
          content: const Text('只支持 PDF 文件格式。'),
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
}
