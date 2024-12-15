import 'package:flowverse/models/bookshelf.dart';
import 'package:flutter/foundation.dart';


class DashboardViewModel extends ChangeNotifier {
  final BookModel model = BookModel();

  List<Book> books = [];

  Future<void> loadBooks() async {
    await model.loadBooks();
    books = model.books;
    notifyListeners();
  }

  // 添加删除书籍的方法
  Future<void> deleteBook(int id) async {
    books.removeWhere((book) => book.id == id);
    notifyListeners();
    await model.saveBooks();
  }

  bool isBookExists(String bookPath) {
    return books.any((book) => book.path == bookPath);
  }

  Future<bool> addBook(Book book) async {
    if (!isBookExists(book.path)) {
      books.add(book);
      notifyListeners();
      await model.saveBooks();
      return true;
    }
    return false;
  }

  Future<bool> removeBook(Book book) async {
    if (isBookExists(book.name)) {
      books.remove(book);
      notifyListeners();
      await model.saveBooks();
      return true;
    }
    return false;
  }
}
