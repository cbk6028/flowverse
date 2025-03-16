import 'dart:convert';
import 'dart:io';

import 'package:flov/domain/models/archive/archive.dart';
import 'package:flov/domain/models/book/book.dart';
import 'package:flov/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ArchiveRepository {
  // 保存归档到文件
  Future<void> saveArchive(Book book, Archive archive) async {
    final appDir = await getApplicationDocumentsDirectory();
    final archiveDir = path.join(appDir.path, 'FloV', 'notes');

    // 确保目录存在
    await Directory(archiveDir).create(recursive: true);

    final savePath = path.join(archiveDir, '${book.md5}.json');
    logger.d('saveArchive: $savePath');

    final archiveJson = jsonEncode(archive.toJson());
    await File(savePath).writeAsString(archiveJson);
  }

  Future<Archive> loadArchive(Book book) async {
    final appDir = await getApplicationDocumentsDirectory();
    final savePath =
        path.join(appDir.path, 'FloV', 'notes', '${book.md5}.json');
    logger.d('loadArchive: $savePath');

    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      // 检查文件内容是否为空
      if (content.isEmpty) {
        return Archive(
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          initialMarkers: {},
          initialStrokes: {},
        );
      }

      try {
        final json = jsonDecode(content) as Map<String, dynamic>;
        final archive = Archive.fromJson(json);
        print('archive: ${archive}');
        return archive;
      } catch (e) {
        logger.e('Error parsing archive file: $e');
        // 如果解析失败，返回一个新的空 Archive
        return Archive(
          dateCreated: DateTime.now(),
          dateModified: DateTime.now(),
          initialMarkers: {},
          initialStrokes: {},
        );
      }
    }

    // 如果文件不存在，返回新的空 Archive
    return Archive(
      dateCreated: DateTime.now(),
      dateModified: DateTime.now(),
      initialMarkers: {},
      initialStrokes: {},
    );
  }
}
