import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flowverse/models/bookshelf.dart';
import '../models/sort_option.dart';

class DashboardViewModel extends ChangeNotifier {
  final BookModel model = BookModel();

  List<Book> _books = [];
  List<Book> get books => _books;

  SortOption _currentSortOption = SortOption.fileName;
  SortOption get currentSortOption => _currentSortOption;

  SortDirection _sortDirection = SortDirection.ascending;
  SortDirection get sortDirection => _sortDirection;

  Map<String, int> _openCounts = {};
  Map<String, DateTime> _lastReadTimes = {};

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
          comparison = a.path.compareTo(b.path);
        case SortOption.modifiedTime:
          comparison = File(a.path).lastModifiedSync().compareTo(File(b.path).lastModifiedSync());
        case SortOption.fileSize:
          comparison = File(a.path).lengthSync().compareTo(File(b.path).lengthSync());
        case SortOption.lastRead:
          final timeA = _lastReadTimes[a.path] ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = _lastReadTimes[b.path] ?? DateTime.fromMillisecondsSinceEpoch(0);
          comparison = timeA.compareTo(timeB);
        case SortOption.openCount:
          comparison = (_openCounts[a.path] ?? 0).compareTo(_openCounts[b.path] ?? 0);
      }
      return _sortDirection == SortDirection.ascending ? comparison : -comparison;
    });
  }

  Future<void> loadBooks() async {
    await model.loadBooks();
    _books = model.books;
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
      await model.saveBooks();
      return true;
    }
    return false;
  }

  Future<bool> removeBook(Book book) async {
    if (isBookExists(book.path)) {
      _books.remove(book);
      _sortBooks();
      notifyListeners();
      await model.saveBooks();
      return true;
    }
    return false;
  }
}
