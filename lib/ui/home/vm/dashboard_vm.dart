import 'dart:io';
import 'package:flov/data/repositories/book/book_repository.dart';
import 'package:flov/domain/models/book/book.dart';
import 'package:flov/domain/models/sort/sort.dart';
import 'package:flov/utils/logger.dart';
// import 'package:flov/domain/models/sort_option.dart';
import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required BookRepository bookRepository})
      : _bookRepository = bookRepository;

  final BookRepository _bookRepository;

  List<Book> _books = [];
  // List<Book> get books => _books;
  // UnmodifiableListView<Book> get books => UnmodifiableListView(_books);
  List<Book> get books => _books;

  // Sort _sort;

  SortOption _currentSortOption = SortOption.fileName;
  SortOption get currentSortOption => _currentSortOption;

  SortDirection _sortDirection = SortDirection.ascending;
  SortDirection get sortDirection => _sortDirection;

  final Map<String, int> _openCounts = {};
  final Map<String, DateTime> _lastReadTimes = {};

  void setOpenCount(String filePath, int count) {
    _openCounts[filePath] = count;
    notifyListeners();
  }

  void updateLastReadTime(String filePath) {
    _lastReadTimes[filePath] = DateTime.now();
    notifyListeners();
  }

  void incrementOpenCount(String filePath) {
    _openCounts[filePath] = (_openCounts[filePath] ?? 0) + 1;
    updateLastReadTime(filePath);
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    if (_currentSortOption == option) {
      // 如果选择相同的排序选项，则切换排序方向
      _sortDirection = _sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
    } else {
      _currentSortOption = option;
      _sortDirection = SortDirection.ascending;
    }
    _sortBooks();
    notifyListeners();
  }

  void _sortBooks() {
    _books.sort((a, b) {
      int comparison = 0;
      switch (_currentSortOption) {
        case SortOption.fileName:
          String firstCharA = a.name.isNotEmpty ? a.name[0] : '';
          String firstCharB = b.name.isNotEmpty ? b.name[0] : '';

          // 检查第一个字符是否是数字
          bool isDigitA =
              firstCharA.isNotEmpty && int.tryParse(firstCharA) != null;
          bool isDigitB =
              firstCharB.isNotEmpty && int.tryParse(firstCharB) != null;

          if (isDigitA && isDigitB) {
            // 如果两个文件名的第一个字符都是数字，直接比较
            comparison = a.name.compareTo(b.name);
          } else if (isDigitA) {
            // 如果第一个文件名的第一个字符是数字，第二个不是，数字排在前面
            comparison = -1;
          } else if (isDigitB) {
            // 如果第一个文件名的第一个字符不是数字，第二个是，数字排在前面
            comparison = 1;
          } else {
            // 如果两个文件名的第一个字符都是字母
            comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            if (comparison == 0) {
              // 如果忽略大小写后相等，再按原始大小写比较
              comparison = a.name.compareTo(b.name);
            }
          }
        // case SortOption.modifiedTime:
        //   comparison = File(a.path).lastModifiedSync().compareTo(File(b.path).lastModifiedSync());
        case SortOption.fileSize:
          comparison =
              File(a.path).lengthSync().compareTo(File(b.path).lengthSync());
        // case SortOption.lastRead:
        //   final timeA =
        //       _lastReadTimes[a.path] ?? DateTime.fromMillisecondsSinceEpoch(0);
        //   final timeB =
        //       _lastReadTimes[b.path] ?? DateTime.fromMillisecondsSinceEpoch(0);
        //   comparison = timeA.compareTo(timeB);
        // case SortOption.openCount:
        //   comparison =
        //       (_openCounts[a.path] ?? 0).compareTo(_openCounts[b.path] ?? 0);
      }
      return _sortDirection == SortDirection.ascending
          ? comparison
          : -comparison;
    });
    // print(_books.map((book) => book.name));
  }

  // Book
  Future<void> loadBooks() async {
    await _bookRepository.loadBooks();
    _books = _bookRepository.books;

    _sortBooks();
    notifyListeners();
  }

  bool isBookExists(String bookPath) {
    return _books.any((book) => book.path == bookPath);
  }

  Future<bool> addBook(Book book) async {
    if (!isBookExists(book.path)) {
      _books.add(book);
      _sortBooks();
      notifyListeners();
      await _bookRepository.saveBooks();
      return true;
    }
    return false;
  }

  Future<bool> removeBook(Book book) async {
    if (isBookExists(book.path)) {
      _books.remove(book);
      _sortBooks();
      notifyListeners();
      await _bookRepository.saveBooks();
      return true;
    }
    return false;
  }

  Future<void> updateCurrentBook({
    int? lastReadPage,
    DateTime? lastReadTime,
    int? totalPages,
    double? readProgress,
    required String currentPdfPath,
  }) async {
    // 获取当前书籍
    // final bookRepository = BookRepository();
    // // await bookRepository.init();
    // await bookRepository.loadBooks();

    // 查找并更新当前书籍
    final currentBook = _books.firstWhere(
      (book) => book.path == currentPdfPath,
      orElse: () => throw Exception('Book not found'),
    );

    // 更新信息
    if (lastReadPage != null) currentBook.lastReadPage = lastReadPage;
    if (lastReadTime != null) currentBook.lastReadTime = lastReadTime;
    if (totalPages != null) currentBook.totalPages = totalPages;
    if (readProgress != null) currentBook.readProgress = readProgress;


      final currentB = _books.firstWhere(
      (book) => book.path == currentPdfPath,
      orElse: () => throw Exception('Book not found'),
    );

    logger.i(currentB.lastReadPage);

    // 保存更新后的书架信息
    await _bookRepository.saveBooks();

    logger.i(currentBook.lastReadPage);
  }
}
