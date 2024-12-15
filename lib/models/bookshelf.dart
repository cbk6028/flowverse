import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Book {
  int id;
  String name;
  String path;
  String image;

  Book(this.id, this.name, this.path, this.image);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'image': image,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    json['id'],
    json['name'],
    json['path'],
    json['image'],
  );
}

class BookModel {
  List<Book> books = [];
  final String keyBooks = 'bookshelf';

  Future<void> loadBooks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jsonData = prefs.getString(keyBooks);
      // await prefs.setString(keyBooks, '');
      
      if (jsonData != null) {
        List<dynamic> decodedData = json.decode(jsonData);
        books = decodedData.map((data) => Book.fromJson(data)).toList();
      }
    } catch (e) {
      // 如果遇到错误，暂时不处理
      if (kDebugMode) {
        debugPrint('读取书架信息失败: $e');
      }
    }
  }

    // 点击添加按钮
    Future<void> saveBooks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String jsonData = json.encode(books.map((book) => book.toJson()).toList());
      await prefs.setString(keyBooks, jsonData);
    } catch (e) {
      // 如果遇到错误，暂时不处理
      if (kDebugMode) {
        debugPrint('保存书架信息失败: $e');
      }
    }
  }

}
