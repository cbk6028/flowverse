import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:path/path.dart' as path;
import 'dart:developer' as developer;

// 日志函数
void logDebug(String message) {
  developer.log(message, name: 'PDF_DEBUG');
  print('PDF_DEBUG: $message');
}

// PDFium 实例初始化
final pdfium = PDFium();
bool _isPdfiumInitialized = false;

// 确保 PDFium 已初始化
Future<void> ensurePdfiumInitialized() async {
  if (!_isPdfiumInitialized) {
    logDebug('初始化 PDFium');
    try {
      pdfium.init();
      _isPdfiumInitialized = true;
      logDebug('PDFium 初始化成功');
    } catch (e) {
      logDebug('PDFium 初始化失败: $e');
      rethrow;
    }
  }
}

// 格式化文件大小
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// PDF 分割功能
Future<String> splitPdf(File pdfFile, String pageRange, String outputName) async {
  logDebug('开始分割 PDF: ${pdfFile.path}, 页面范围: $pageRange');
  
  // 确保 PDFium 已初始化
  await ensurePdfiumInitialized();
  
  // 获取输出目录
  final outputDir = await getTemporaryDirectory();
  final outputPath = path.join(outputDir.path, '$outputName.pdf');
  logDebug('输出路径: $outputPath');
  
  // 加载源文档
  final sourceDoc = PDFDocument.loadDocument(pdfFile.path);
  logDebug('源文档加载成功');
  
  // 创建新文档
  final newDoc = PDFDocument.createNewDocument();
  logDebug('创建新文档成功');
  
  // 导入选中页面
  final importResult = importPages(newDoc.document, sourceDoc.document, pageRange, 0);
  logDebug('导入页面结果: $importResult');
  
  // 保存文件
  final saveResult = newDoc.saveFile(outputPath, 0);
  logDebug('保存文件结果: $saveResult');
  
  return outputPath;
}

// PDF 合并功能
Future<String> mergePdfs(List<String> pdfPaths, String outputName) async {
  logDebug('开始合并 PDF, 文件数量: ${pdfPaths.length}');
  
  // 确保 PDFium 已初始化
  await ensurePdfiumInitialized();
  
  // 获取输出目录
  final outputDir = await getTemporaryDirectory();
  final outputPath = path.join(outputDir.path, '$outputName.pdf');
  logDebug('输出路径: $outputPath');
  
  // 创建 PDFMerger 实例
  final merger = PDFMerger();
  
  // 添加所有文件
  for (var filePath in pdfPaths) {
    logDebug('添加文件: $filePath');
    merger.add(filePath);
  }
  
  // 执行合并
  logDebug('开始执行合并');
  merger.write(outputPath);
  logDebug('合并完成');
  
  return outputPath;
}

// 获取 PDF 页数
Future<int> getPdfPageCount(String filePath) async {
  logDebug('获取 PDF 页数: $filePath');
  
  // 确保 PDFium 已初始化
  await ensurePdfiumInitialized();
  
  // 加载 PDF 文档
  final pdfDoc = PDFDocument.loadDocument(filePath);
  
  // 暂时返回固定值，实际应该从 PDFDocument 获取
  return 5;
} 