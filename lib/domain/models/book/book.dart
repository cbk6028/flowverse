class Book {
  String md5;
  String name;
  String path;
  String image;
  int lastReadPage;         // 上次阅读的页码
  DateTime lastReadTime;    // 最后阅读时间
  DateTime addedTime;       // 添加到书架的时间
  String author;           // 作者
  String description;      // 书籍描述
  int totalPages;         // 总页数
  double readProgress;    // 阅读进度（0-1）
  List<String> tags;      // 标签（用于分类）
  String fileSize;        // 文件大小
  String fileFormat;      // 文件格式（PDF/EPUB等）

  Book(
    this.md5,
    this.name,
    this.path,
    this.image, {
    this.lastReadPage = 0,
    DateTime? lastReadTime,
    DateTime? addedTime,
    this.author = '',
    this.description = '',
    this.totalPages = 0,
    this.readProgress = 0.0,
    this.tags = const [],
    this.fileSize = '',
    this.fileFormat = '',
  })  : lastReadTime = lastReadTime ?? DateTime.now(),
        addedTime = addedTime ?? DateTime.now();

  Book copyWith({
    String? md5,
    String? name,
    String? path,
    String? image,
    int? lastReadPage,
    DateTime? lastReadTime,
    DateTime? addedTime,
    String? author,
    String? description,
    int? totalPages,
    double? readProgress,
    List<String>? tags,
    String? fileSize,
    String? fileFormat,
  }) {
    return Book(
      md5 ?? this.md5,
      name ?? this.name,
      path ?? this.path,
      image ?? this.image,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      lastReadTime: lastReadTime ?? this.lastReadTime,
      addedTime: addedTime ?? this.addedTime,
      author: author ?? this.author,
      description: description ?? this.description,
      totalPages: totalPages ?? this.totalPages,
      readProgress: readProgress ?? this.readProgress,
      tags: tags ?? this.tags,
      fileSize: fileSize ?? this.fileSize,
      fileFormat: fileFormat ?? this.fileFormat,
    );
  }

  Map<String, dynamic> toJson() => {
        'md5': md5,
        'name': name,
        'path': path,
        'image': image,
        'lastReadPage': lastReadPage,
        'lastReadTime': lastReadTime.toIso8601String(),
        'addedTime': addedTime.toIso8601String(),
        'author': author,
        'description': description,
        'totalPages': totalPages,
        'readProgress': readProgress,
        'tags': tags,
        'fileSize': fileSize,
        'fileFormat': fileFormat,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        json['md5'],
        json['name'],
        json['path'],
        json['image'],
        lastReadPage: json['lastReadPage'] ?? 0,
        lastReadTime: json['lastReadTime'] != null
            ? DateTime.parse(json['lastReadTime'])
            : null,
        addedTime: json['addedTime'] != null
            ? DateTime.parse(json['addedTime'])
            : null,
        author: json['author'] ?? '',
        description: json['description'] ?? '',
        totalPages: json['totalPages'] ?? 0,
        readProgress: json['readProgress'] ?? 0.0,
        tags: List<String>.from(json['tags'] ?? []),
        fileSize: json['fileSize'] ?? '',
        fileFormat: json['fileFormat'] ?? '',
      );
}
