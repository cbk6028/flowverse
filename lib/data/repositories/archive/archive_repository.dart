import 'dart:convert';
import 'dart:io';

import 'package:flowverse/config/type.dart';
import 'package:flowverse/domain/models/archive/archive.dart';
import 'package:flowverse/domain/models/tool/stroke.dart';

class ArchiveRepository {
  // 保存归档到文件
  Future<void> saveArchive(String pdfPath, Archive archive) async {
    final savePath = '${pdfPath}_archive.json';
    // final archive = Archive(
    //   dateCreated: DateTime.now(),
    //   dateModified: DateTime.now(),
    //   initialMarkers: Map.from(markers),
    //   initialStrokes: Map.from(strokes)
    // );

    final archiveJson = jsonEncode(archive.toJson());
    await File(savePath).writeAsString(archiveJson);
  }

  Future<Archive> loadArchive(String pdfPath) async {
    final savePath = '${pdfPath}_archive.json';
    if (await File(savePath).exists()) {
      final content = await File(savePath).readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final archive = Archive.fromJson(json);

      // markers = Map.from(archive.markers);
      // strokes = Map.from(archive.strokes);
      print('archive: ${archive}');

      return archive;
    }

    final archive = Archive(
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
        initialMarkers: {},
        initialStrokes: {});

    return archive;
  }
}
