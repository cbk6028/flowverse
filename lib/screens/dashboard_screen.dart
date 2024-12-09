import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 导入 shared_preferences
import 'package:pdfrx/pdfrx.dart';

import 'reader_screen.dart'; // 导入阅读器页面

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 存储书籍列表的数组，保存文件路径
  List<String> books = [];

  // SharedPreferences 键名
  final String keyBooks = 'bookshelf';

  @override
  void initState() {
    super.initState();
    _loadBooks(); // 加载书架信息
  }

  // 加载书架信息
  Future<void> _loadBooks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonData = prefs.getString(keyBooks);
      if (jsonData != null) {
        List<dynamic> decodedData = json.decode(jsonData);
        setState(() {
          books = List<String>.from(decodedData);
        });
      }
    } catch (e) {
      // 如果遇到错误，暂时不处理
      print('读取书架信息失败: $e');
    }
  }

  // 保存书架信息
  Future<void> _saveBooks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String jsonData = json.encode(books);
      await prefs.setString(keyBooks, jsonData);
    } catch (e) {
      // 如果遇到错误，暂时不处理
      print('保存书架信息失败: $e');
    }
  }

  // 显示提示对话框
  Future<void> _showAlreadyExistsDialog(String fileName) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('添加失败'),
          content: Text('《$fileName》已经存在于书架中。'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 添加删除书籍的方法
  void _deleteBook(String filePath) {
    setState(() {
      books.remove(filePath);
    });
    _saveBooks();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
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
                    leading: Icon(CupertinoIcons.home),
                    title: Text('主页'),
                    onTap: () {
                      // 处理主页点击事件
                    },
                  ),
                  CupertinoListTile(
                    leading: Icon(CupertinoIcons.book),
                    title: Text('书架'),
                    onTap: () {
                      // 处理书架点击事件
                    },
                  ),
                  CupertinoListTile(
                    leading: Icon(CupertinoIcons.settings),
                    title: Text('设置'),
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
                  child: BookshelfWidget(
                    books: books,
                    onDelete: _deleteBook, // 传递删除回调
                  ),
                ),
                // 浮动的“添加”按钮
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: CupertinoButton(
                    padding: EdgeInsets.all(16),
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(30),
                    child: Icon(
                      CupertinoIcons.add,
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
                      if (result != null && result.files.single.path != null) {
                        String filePath = result.files.single.path!;
                        String fileName = result.files.single.name;

                        debugPrint(books.toString());
                        print(filePath);
                        // 检查文件是否已经存在
                        if (books.contains(filePath)) {
                          // 显示提示对话框
                          await _showAlreadyExistsDialog(fileName);
                        } else {
                          setState(() {
                            debugPrint('添加成功');
                            books.add(filePath); // 存储文件路径
                          });

                          // 保存更新后的书架信息
                          _saveBooks();
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
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            leading,
            SizedBox(width: 16),
            title,
          ],
        ),
      ),
    );
  }
}

class PdfThumbnail extends StatefulWidget {
  final String filePath;

  const PdfThumbnail({Key? key, required this.filePath}) : super(key: key);

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  PdfDocument? _document;
  PdfPage? _page;
  bool _isLoading = true;
  String? _error;
  ui.Image? _thumbnail;
  

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    try {
      _document = await PdfDocument.openFile(widget.filePath);
      _page = await _document!.pages[0];
      
      // 使用固定的缩略图尺寸
      final targetWidth = 200.0;
      final targetHeight = (targetWidth / _page!.width * _page!.height);
      
      final pdfImage = await _page!.render(

         fullWidth: targetWidth,
        fullHeight: targetHeight,
      );

      // if (pdfImage != null) {
      //   final bytes = pdfImage.pixels;
      //   final codec = await ui.instantiateImageCodec(bytes);
      //   final frameInfo = await codec.getNextFrame();
      //   _thumbnail = frameInfo.image;
      //   pdfImage.dispose();
      // }

      _thumbnail = await pdfImage?.createImage();


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
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_error != null || _thumbnail == null) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Center(
          child: Icon(CupertinoIcons.doc_text_fill,
              size: 48, color: CupertinoColors.systemGrey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        child: RawImage(
          image: _thumbnail,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class BookshelfWidget extends StatelessWidget {
  final List<String> books;
  final Function(String) onDelete;

  BookshelfWidget({required this.books, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return books.isEmpty
        ? Center(
            child: Text(
              '书架为空，点击右下角添加书籍',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          )
        : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              String filePath = books[index];
              String fileName = filePath.split('/').last;

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
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: PdfThumbnail(filePath: filePath),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              fileName,
                              style: TextStyle(
                                color: CupertinoColors.black,
                                fontSize: 12,
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
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          onDelete(filePath);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: CupertinoColors.destructiveRed,
                            size: 24,
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
