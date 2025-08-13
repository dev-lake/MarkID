import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repositories/export_record_repository.dart';

/// 水印照片管理服务
class WatermarkedPhotoService {
  /// 获取所有水印照片信息
  static Future<List<WatermarkedPhotoInfo>> getAllWatermarkedPhotos() async {
    try {
      final List<ExportRecord> records =
          await ExportRecordRepository.getAllExportRecords();
      final List<WatermarkedPhotoInfo> photos = [];

      for (final record in records) {
        WatermarkedPhotoInfo? photoInfo;

        if (record.status == ExportStatus.success &&
            record.exportPath.isNotEmpty) {
          // 成功的记录，检查文件是否存在
          final File photoFile = File(record.exportPath);
          if (await photoFile.exists()) {
            final FileStat stat = await photoFile.stat();
            photoInfo = WatermarkedPhotoInfo(
              id: record.id,
              documentId: record.documentId,
              filePath: record.exportPath,
              fileName: record.fileName,
              fileSize: record.fileSize,
              exportTime: record.exportTime,
              watermarkDetails: record.watermarkDetails,
              purpose: record.purpose,
              notes: record.notes,
              lastModified: stat.modified,
              status: record.status,
              errorMessage: record.errorMessage,
            );
          }
        } else {
          // 失败或进行中的记录，创建虚拟照片信息
          photoInfo = WatermarkedPhotoInfo(
            id: record.id,
            documentId: record.documentId,
            filePath: record.exportPath.isNotEmpty ? record.exportPath : '',
            fileName: record.fileName.isNotEmpty ? record.fileName : '未生成',
            fileSize: record.fileSize,
            exportTime: record.exportTime,
            watermarkDetails: record.watermarkDetails,
            purpose: record.purpose,
            notes: record.notes,
            lastModified: record.updatedAt,
            status: record.status,
            errorMessage: record.errorMessage,
          );
        }

        if (photoInfo != null) {
          photos.add(photoInfo);
        }
      }

      // 按导出时间倒序排列
      photos.sort((a, b) => b.exportTime.compareTo(a.exportTime));
      return photos;
    } catch (e) {
      debugPrint('获取水印照片失败: $e');
      return [];
    }
  }

  /// 根据证件ID获取水印照片
  static Future<List<WatermarkedPhotoInfo>> getWatermarkedPhotosByDocumentId(
    String documentId,
  ) async {
    try {
      final List<ExportRecord> records =
          await ExportRecordRepository.getExportRecordsByDocumentId(documentId);
      final List<WatermarkedPhotoInfo> photos = [];

      for (final record in records) {
        WatermarkedPhotoInfo? photoInfo;

        if (record.status == ExportStatus.success &&
            record.exportPath.isNotEmpty) {
          // 成功的记录，检查文件是否存在
          final File photoFile = File(record.exportPath);
          if (await photoFile.exists()) {
            final FileStat stat = await photoFile.stat();
            photoInfo = WatermarkedPhotoInfo(
              id: record.id,
              documentId: record.documentId,
              filePath: record.exportPath,
              fileName: record.fileName,
              fileSize: record.fileSize,
              exportTime: record.exportTime,
              watermarkDetails: record.watermarkDetails,
              purpose: record.purpose,
              notes: record.notes,
              lastModified: stat.modified,
              status: record.status,
              errorMessage: record.errorMessage,
            );
          }
        } else {
          // 失败或进行中的记录，创建虚拟照片信息
          photoInfo = WatermarkedPhotoInfo(
            id: record.id,
            documentId: record.documentId,
            filePath: record.exportPath.isNotEmpty ? record.exportPath : '',
            fileName: record.fileName.isNotEmpty ? record.fileName : '未生成',
            fileSize: record.fileSize,
            exportTime: record.exportTime,
            watermarkDetails: record.watermarkDetails,
            purpose: record.purpose,
            notes: record.notes,
            lastModified: record.updatedAt,
            status: record.status,
            errorMessage: record.errorMessage,
          );
        }

        if (photoInfo != null) {
          photos.add(photoInfo);
        }
      }

      // 按导出时间倒序排列
      photos.sort((a, b) => b.exportTime.compareTo(a.exportTime));
      return photos;
    } catch (e) {
      debugPrint('获取证件水印照片失败: $e');
      return [];
    }
  }

  /// 获取水印照片详情
  static Future<WatermarkedPhotoInfo?> getWatermarkedPhotoById(
    String id,
  ) async {
    try {
      final ExportRecord? record =
          await ExportRecordRepository.getExportRecordById(id);
      if (record == null) {
        return null;
      }

      if (record.status == ExportStatus.success &&
          record.exportPath.isNotEmpty) {
        // 成功的记录，检查文件是否存在
        final File photoFile = File(record.exportPath);
        if (!await photoFile.exists()) {
          return null;
        }

        final FileStat stat = await photoFile.stat();
        return WatermarkedPhotoInfo(
          id: record.id,
          documentId: record.documentId,
          filePath: record.exportPath,
          fileName: record.fileName,
          fileSize: record.fileSize,
          exportTime: record.exportTime,
          watermarkDetails: record.watermarkDetails,
          purpose: record.purpose,
          notes: record.notes,
          lastModified: stat.modified,
          status: record.status,
          errorMessage: record.errorMessage,
        );
      } else {
        // 失败或进行中的记录，创建虚拟照片信息
        return WatermarkedPhotoInfo(
          id: record.id,
          documentId: record.documentId,
          filePath: record.exportPath.isNotEmpty ? record.exportPath : '',
          fileName: record.fileName.isNotEmpty ? record.fileName : '未生成',
          fileSize: record.fileSize,
          exportTime: record.exportTime,
          watermarkDetails: record.watermarkDetails,
          purpose: record.purpose,
          notes: record.notes,
          lastModified: record.updatedAt,
          status: record.status,
          errorMessage: record.errorMessage,
        );
      }
    } catch (e) {
      debugPrint('获取水印照片详情失败: $e');
      return null;
    }
  }

  /// 删除水印照片
  static Future<bool> deleteWatermarkedPhoto(String id) async {
    try {
      final ExportRecord? record =
          await ExportRecordRepository.getExportRecordById(id);
      if (record == null) {
        return false;
      }

      // 删除文件
      if (record.exportPath.isNotEmpty) {
        final File photoFile = File(record.exportPath);
        if (await photoFile.exists()) {
          await photoFile.delete();
        }
      }

      // 删除记录
      await ExportRecordRepository.deleteExportRecord(id);
      return true;
    } catch (e) {
      debugPrint('删除水印照片失败: $e');
      return false;
    }
  }

  /// 批量删除水印照片
  static Future<int> deleteWatermarkedPhotos(List<String> ids) async {
    int deletedCount = 0;
    for (final id in ids) {
      if (await deleteWatermarkedPhoto(id)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  /// 删除证件的所有水印照片
  static Future<int> deleteWatermarkedPhotosByDocumentId(
    String documentId,
  ) async {
    try {
      final List<WatermarkedPhotoInfo> photos =
          await getWatermarkedPhotosByDocumentId(documentId);
      final List<String> ids = photos.map((photo) => photo.id).toList();
      return await deleteWatermarkedPhotos(ids);
    } catch (e) {
      debugPrint('删除证件水印照片失败: $e');
      return 0;
    }
  }

  /// 复制水印照片到指定位置
  static Future<String?> copyWatermarkedPhoto(
    String id,
    String targetPath,
  ) async {
    try {
      final WatermarkedPhotoInfo? photo = await getWatermarkedPhotoById(id);
      if (photo == null) {
        return null;
      }

      final File sourceFile = File(photo.filePath);
      final File targetFile = File(targetPath);

      // 确保目标目录存在
      final Directory targetDir = targetFile.parent;
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('复制水印照片失败: $e');
      return null;
    }
  }

  /// 获取水印照片统计信息
  static Future<Map<String, dynamic>> getWatermarkedPhotoStats() async {
    try {
      final List<WatermarkedPhotoInfo> photos = await getAllWatermarkedPhotos();

      int totalPhotos = photos.length;
      int totalSize = photos.fold(0, (sum, photo) => sum + photo.fileSize);
      DateTime? oldestPhoto;
      DateTime? newestPhoto;

      for (final photo in photos) {
        if (oldestPhoto == null || photo.exportTime.isBefore(oldestPhoto)) {
          oldestPhoto = photo.exportTime;
        }
        if (newestPhoto == null || photo.exportTime.isAfter(newestPhoto)) {
          newestPhoto = photo.exportTime;
        }
      }

      return {
        'totalPhotos': totalPhotos,
        'totalSize': totalSize,
        'oldestPhoto': oldestPhoto,
        'newestPhoto': newestPhoto,
      };
    } catch (e) {
      debugPrint('获取水印照片统计失败: $e');
      return {
        'totalPhotos': 0,
        'totalSize': 0,
        'oldestPhoto': null,
        'newestPhoto': null,
      };
    }
  }

  /// 清理过期的水印照片
  static Future<int> cleanupExpiredWatermarkedPhotos({
    int maxAgeDays = 90,
  }) async {
    try {
      final List<WatermarkedPhotoInfo> photos = await getAllWatermarkedPhotos();
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: maxAgeDays),
      );

      int deletedCount = 0;
      for (final photo in photos) {
        if (photo.exportTime.isBefore(cutoffDate)) {
          if (await deleteWatermarkedPhoto(photo.id)) {
            deletedCount++;
          }
        }
      }

      return deletedCount;
    } catch (e) {
      debugPrint('清理过期水印照片失败: $e');
      return 0;
    }
  }

  /// 验证水印照片文件是否存在
  static Future<bool> isWatermarkedPhotoExists(String id) async {
    try {
      final WatermarkedPhotoInfo? photo = await getWatermarkedPhotoById(id);
      return photo != null;
    } catch (e) {
      return false;
    }
  }

  /// 获取水印照片文件大小
  static Future<int> getWatermarkedPhotoFileSize(String id) async {
    try {
      final WatermarkedPhotoInfo? photo = await getWatermarkedPhotoById(id);
      return photo?.fileSize ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

/// 水印照片信息模型
class WatermarkedPhotoInfo {
  final String id;
  final String documentId;
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime exportTime;
  final String watermarkDetails;
  final String? purpose;
  final String? notes;
  final DateTime lastModified;
  final ExportStatus status;
  final String? errorMessage;

  WatermarkedPhotoInfo({
    required this.id,
    required this.documentId,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.exportTime,
    required this.watermarkDetails,
    this.purpose,
    this.notes,
    required this.lastModified,
    this.status = ExportStatus.success,
    this.errorMessage,
  });

  /// 获取文件大小的可读格式
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取相对时间描述
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(exportTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  /// 解析水印详情
  Map<String, dynamic> get parsedWatermarkDetails {
    try {
      return Map<String, dynamic>.from(jsonDecode(watermarkDetails));
    } catch (e) {
      return {};
    }
  }

  /// 获取水印文本
  String get watermarkText {
    final details = parsedWatermarkDetails;
    return details['text'] ?? '未知水印';
  }

  /// 获取水印配置名称
  String get watermarkConfigName {
    final details = parsedWatermarkDetails;
    return details['config'] ?? '未知配置';
  }

  /// 获取状态的中文描述
  String get statusText {
    switch (status) {
      case ExportStatus.exporting:
        return '导出中';
      case ExportStatus.success:
        return '导出成功';
      case ExportStatus.failed:
        return '导出失败';
      case ExportStatus.cancelled:
        return '已取消';
    }
  }

  /// 检查是否有实际的照片文件
  bool get hasActualFile {
    return status == ExportStatus.success && filePath.isNotEmpty;
  }

  /// 检查是否可以查看照片
  bool get canViewPhoto {
    return hasActualFile;
  }

  @override
  String toString() {
    return 'WatermarkedPhotoInfo(id: $id, fileName: $fileName, fileSize: $fileSizeFormatted, status: $statusText)';
  }
}
