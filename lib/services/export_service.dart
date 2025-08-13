import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import '../repositories/export_record_repository.dart';
import 'watermark.dart';

/// 导出服务
class ExportService {
  /// 导出带水印的照片（单张）
  static Future<ExportRecord> exportWatermarkedImage({
    required IdDocument document,
    required WatermarkConfig watermarkConfig,
    required String watermarkText,
    String? customOutputPath,
    WatermarkMethod watermarkMethod = WatermarkMethod.type1,
    int gridRows = 4,
    int gridColumns = 2,
    int photoIndex = 0,
  }) async {
    try {
      // 读取原始图片文件
      if (document.photos.isEmpty) {
        throw Exception('证件没有照片');
      }
      if (photoIndex >= document.photos.length) {
        throw Exception('照片索引超出范围');
      }
      final selectedPhoto = document.photos[photoIndex];
      final File originalFile = File(selectedPhoto.originalImagePath);
      final Uint8List originalImageData = await originalFile.readAsBytes();

      // 根据选择的方式添加水印
      Uint8List watermarkedImageData;

      switch (watermarkMethod) {
        case WatermarkMethod.type1:
          watermarkedImageData = await Watermark.imageAddWaterMarkType1(
            originalImageData,
            watermarkText,
          );
          break;
        case WatermarkMethod.type2:
          final result = await Watermark.imageAddWaterMarkType2(
            originalImageData,
            watermarkText,
            rows: gridRows,
            columns: gridColumns,
            angle: watermarkConfig.rotation,
            opacity: watermarkConfig.opacity,
          );
          if (result == null) {
            throw Exception('水印处理失败');
          }
          watermarkedImageData = result;
          break;
      }

      // 保存水印图片
      final String exportDir = await getExportDirectory();

      // 生成唯一文件名，避免重复
      final String originalFileName = path.basename(
        selectedPhoto.originalImagePath,
      );
      final String fileExtension = path.extension(originalFileName);
      final String fileNameWithoutExt = path.basenameWithoutExtension(
        originalFileName,
      );
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName =
          'watermarked_${fileNameWithoutExt}_$timestamp$fileExtension';

      final String watermarkedImagePath = path.join(exportDir, fileName);
      final File watermarkedFile = File(watermarkedImagePath);
      await watermarkedFile.writeAsBytes(watermarkedImageData);

      // 获取文件信息
      final int fileSize = await watermarkedFile.length();

      // 创建导出记录
      final ExportRecord exportRecord = ExportRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: document.id,
        exportPath: watermarkedImagePath,
        fileName: path.basename(watermarkedImagePath),
        fileSize: fileSize,
        appliedWatermarkIds: [watermarkConfig.id],
        watermarkDetails:
            '{"text": "$watermarkText", "config": "${watermarkConfig.name}"}',
        deviceInfo: 'iOS/Android Device',
        notes: '导出成功',
        status: ExportStatus.success,
      );

      // 保存导出记录
      await ExportRecordRepository.saveExportRecord(exportRecord);

      return exportRecord;
    } catch (e) {
      // 创建失败记录
      final ExportRecord failureRecord = ExportRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        documentId: document.id,
        exportPath: '',
        fileName: '导出失败_${DateTime.now().millisecondsSinceEpoch}',
        fileSize: 0,
        appliedWatermarkIds: [watermarkConfig.id],
        watermarkDetails:
            '{"text": "$watermarkText", "config": "${watermarkConfig.name}"}',
        deviceInfo: 'iOS/Android Device',
        notes: '导出失败: $e',
        errorMessage: e.toString(),
        status: ExportStatus.failed,
      );

      // 保存失败记录
      await ExportRecordRepository.saveExportRecord(failureRecord);

      throw Exception('导出失败: $e');
    }
  }

  /// 导出证件的所有照片（带水印）
  static Future<List<ExportRecord>> exportAllWatermarkedImages({
    required IdDocument document,
    required WatermarkConfig watermarkConfig,
    required String watermarkText,
    WatermarkMethod watermarkMethod = WatermarkMethod.type1,
    int gridRows = 4,
    int gridColumns = 2,
  }) async {
    try {
      final List<ExportRecord> exportRecords = [];

      for (int i = 0; i < document.photos.length; i++) {
        final photo = document.photos[i];

        try {
          // 读取原始图片文件
          final File originalFile = File(photo.originalImagePath);
          final Uint8List originalImageData = await originalFile.readAsBytes();

          // 根据选择的方式添加水印
          Uint8List watermarkedImageData;

          switch (watermarkMethod) {
            case WatermarkMethod.type1:
              watermarkedImageData = await Watermark.imageAddWaterMarkType1(
                originalImageData,
                watermarkText,
              );
              break;
            case WatermarkMethod.type2:
              final result = await Watermark.imageAddWaterMarkType2(
                originalImageData,
                watermarkText,
                rows: gridRows,
                columns: gridColumns,
                angle: watermarkConfig.rotation,
                opacity: watermarkConfig.opacity,
              );
              if (result == null) {
                throw Exception('水印处理失败');
              }
              watermarkedImageData = result;
              break;
          }

          // 保存水印图片
          final String exportDir = await getExportDirectory();

          // 生成唯一文件名，包含照片类型和索引
          final String originalFileName = path.basename(
            photo.originalImagePath,
          );
          final String fileExtension = path.extension(originalFileName);
          final String fileNameWithoutExt = path.basenameWithoutExtension(
            originalFileName,
          );
          final String timestamp = DateTime.now().millisecondsSinceEpoch
              .toString();
          final String fileName =
              'watermarked_${document.documentType}_${photo.photoType}_${i + 1}_$timestamp$fileExtension';

          final String watermarkedImagePath = path.join(exportDir, fileName);
          final File watermarkedFile = File(watermarkedImagePath);
          await watermarkedFile.writeAsBytes(watermarkedImageData);

          // 获取文件信息
          final int fileSize = await watermarkedFile.length();

          // 创建导出记录
          final ExportRecord exportRecord = ExportRecord(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            documentId: document.id,
            exportPath: watermarkedImagePath,
            fileName: path.basename(watermarkedImagePath),
            fileSize: fileSize,
            appliedWatermarkIds: [watermarkConfig.id],
            watermarkDetails:
                '{"text": "$watermarkText", "config": "${watermarkConfig.name}", "photoType": "${photo.photoType}", "photoIndex": $i}',
            deviceInfo: 'iOS/Android Device',
            notes: '导出成功 - ${photo.photoType}',
            status: ExportStatus.success,
          );

          // 保存导出记录
          await ExportRecordRepository.saveExportRecord(exportRecord);
          exportRecords.add(exportRecord);
        } catch (e) {
          // 创建失败记录
          final ExportRecord failureRecord = ExportRecord(
            id: '${DateTime.now().millisecondsSinceEpoch}_${i}_failed',
            documentId: document.id,
            exportPath: '',
            fileName:
                '导出失败_${photo.photoType}_${DateTime.now().millisecondsSinceEpoch}',
            fileSize: 0,
            appliedWatermarkIds: [watermarkConfig.id],
            watermarkDetails:
                '{"text": "$watermarkText", "config": "${watermarkConfig.name}", "photoType": "${photo.photoType}", "photoIndex": $i}',
            deviceInfo: 'iOS/Android Device',
            notes: '导出失败 - ${photo.photoType}: $e',
            errorMessage: e.toString(),
            status: ExportStatus.failed,
          );

          await ExportRecordRepository.saveExportRecord(failureRecord);
          exportRecords.add(failureRecord);
        }
      }

      return exportRecords;
    } catch (e) {
      throw Exception('批量导出失败: $e');
    }
  }

  /// 批量导出带水印的照片
  static Future<List<ExportRecord>> batchExportWatermarkedImages({
    required List<IdDocument> documents,
    required WatermarkConfig watermarkConfig,
    required String watermarkText,
  }) async {
    final List<ExportRecord> results = [];

    for (final document in documents) {
      try {
        final exportRecord = await exportWatermarkedImage(
          document: document,
          watermarkConfig: watermarkConfig,
          watermarkText: watermarkText,
        );
        results.add(exportRecord);
      } catch (e) {
        // 创建失败记录
        final failureRecord = ExportRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          documentId: document.id,
          exportPath: '',
          fileName: '导出失败_${DateTime.now().millisecondsSinceEpoch}',
          fileSize: 0,
          appliedWatermarkIds: [watermarkConfig.id],
          watermarkDetails:
              '{"text": "$watermarkText", "config": "${watermarkConfig.name}"}',
          deviceInfo: 'iOS/Android Device',
          notes: '导出失败: $e',
          errorMessage: e.toString(),
          status: ExportStatus.failed,
        );
        results.add(failureRecord);
      }
    }

    return results;
  }

  /// 保存到相册（模拟实现）
  static Future<bool> saveToGallery(String imagePath) async {
    try {
      // 这里应该使用 image_gallery_saver 或其他插件
      // 目前只是模拟实现
      debugPrint('保存到相册: $imagePath');
      return true;
    } catch (e) {
      debugPrint('保存到相册失败: $e');
      return false;
    }
  }

  /// 分享图片（模拟实现）
  static Future<bool> shareImage(String imagePath) async {
    try {
      // 这里应该使用 share_plus 或其他分享插件
      // 目前只是模拟实现
      debugPrint('分享图片: $imagePath');
      return true;
    } catch (e) {
      debugPrint('分享图片失败: $e');
      return false;
    }
  }

  /// 获取导出目录
  static Future<String> getExportDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String exportDir = path.join(appDir.path, 'exports');

    // 确保目录存在
    final Directory dir = Directory(exportDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return exportDir;
  }

  /// 清理过期的导出文件
  static Future<void> cleanupExpiredExports({int maxAgeDays = 30}) async {
    try {
      final String exportDir = await getExportDirectory();
      final Directory dir = Directory(exportDir);

      if (!await dir.exists()) return;

      final List<FileSystemEntity> files = await dir.list().toList();
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: maxAgeDays),
      );

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final FileStat stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            debugPrint('删除过期文件: ${entity.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('清理过期文件失败: $e');
    }
  }

  /// 获取导出统计信息
  static Future<Map<String, dynamic>> getExportStats() async {
    try {
      final String exportDir = await getExportDirectory();
      final Directory dir = Directory(exportDir);

      if (!await dir.exists()) {
        return {
          'totalFiles': 0,
          'totalSize': 0,
          'oldestFile': null,
          'newestFile': null,
        };
      }

      final List<FileSystemEntity> files = await dir.list().toList();
      int totalSize = 0;
      DateTime? oldestFile;
      DateTime? newestFile;

      for (final FileSystemEntity entity in files) {
        if (entity is File) {
          final FileStat stat = await entity.stat();
          totalSize += stat.size;

          if (oldestFile == null || stat.modified.isBefore(oldestFile)) {
            oldestFile = stat.modified;
          }

          if (newestFile == null || stat.modified.isAfter(newestFile)) {
            newestFile = stat.modified;
          }
        }
      }

      return {
        'totalFiles': files.length,
        'totalSize': totalSize,
        'oldestFile': oldestFile,
        'newestFile': newestFile,
      };
    } catch (e) {
      debugPrint('获取导出统计失败: $e');
      return {
        'totalFiles': 0,
        'totalSize': 0,
        'oldestFile': null,
        'newestFile': null,
      };
    }
  }

  /// 验证导出配置
  static bool validateExportConfig({
    required WatermarkConfig watermarkConfig,
    required String watermarkText,
  }) {
    if (watermarkText.trim().isEmpty) {
      return false;
    }

    // 简单验证水印配置
    if (watermarkConfig.name.isEmpty) {
      return false;
    }

    return true;
  }

  /// 生成水印文本
  static String generateWatermarkText({
    required IdDocument document,
    required String template,
  }) {
    String result = template;

    // 替换占位符
    result = result.replaceAll('{{documentType}}', document.documentType);
    result = result.replaceAll('{{holderName}}', document.holderName ?? '未知');
    result = result.replaceAll(
      '{{documentNumber}}',
      document.documentNumber ?? '未知',
    );
    result = result.replaceAll(
      '{{timestamp}}',
      DateTime.now().toIso8601String(),
    );
    result = result.replaceAll(
      '{{date}}',
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
    );
    result = result.replaceAll(
      '{{time}}',
      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    );

    return result;
  }
}
