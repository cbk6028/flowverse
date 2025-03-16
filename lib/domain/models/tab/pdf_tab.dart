import 'package:flov/domain/models/book/book.dart';
import 'package:flutter/material.dart';

/// PDF标签页模型，用于多标签页功能
class PdfTab {
  /// 唯一标识符
  final String id;
  
  /// 标签页标题（通常是文件名）
  final String title;
  
  /// PDF文件路径
  final String filePath;
  
  /// 关联的书籍信息
  final Book book;
  
  /// 标签页是否处于活动状态
  bool isActive;

  /// 创建一个新的PDF标签页
  PdfTab({
    required this.id,
    required this.title,
    required this.filePath,
    required this.book,
    this.isActive = false,
  });

  /// 从另一个标签页复制并修改部分属性
  PdfTab copyWith({
    String? id,
    String? title,
    String? filePath,
    Book? book,
    bool? isActive,
  }) {
    return PdfTab(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      book: book ?? this.book,
      isActive: isActive ?? this.isActive,
    );
  }
} 