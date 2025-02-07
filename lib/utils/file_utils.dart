import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class FileUtils {
  static Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
