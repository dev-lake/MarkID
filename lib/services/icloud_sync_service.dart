import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/id_document.dart';
import '../models/export_record.dart';
import '../models/security_config.dart';
import '../models/watermark_config.dart';
import 'document_service.dart';

/// iCloud 同步服务
/// 使用系统自带的 iCloud 文档同步功能
class ICloudSyncService {
  static const String _syncFolderName = 'MarkID_Sync';
  static const String _documentsFileName = 'documents.json';
  static const String _exportRecordsFileName = 'export_records.json';
  static const String _securityConfigFileName = 'security_config.json';
  static const String _watermarkConfigFileName = 'watermark_config.json';
  static const String _syncStatusKey = 'icloud_sync_status';

  final DocumentService _documentService;

  ICloudSyncService(this._documentService);

  /// 获取 iCloud 同步目录
  Future<Directory?> _getICloudDirectory() async {
    try {
      // 获取 iCloud 容器目录
      final containers = await getApplicationSupportDirectory();
      final iCloudPath = path.join(containers.path, 'iCloud');
      final syncDir = Directory(path.join(iCloudPath, _syncFolderName));

      if (!await syncDir.exists()) {
        await syncDir.create(recursive: true);
      }

      return syncDir;
    } catch (e) {
      debugPrint('获取 iCloud 目录失败: $e');
      return null;
    }
  }

  /// 获取本地同步目录（作为备份）
  Future<Directory> _getLocalSyncDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final syncDir = Directory(path.join(appDir.path, _syncFolderName));

    if (!await syncDir.exists()) {
      await syncDir.create(recursive: true);
    }

    return syncDir;
  }

  /// 同步所有数据到 iCloud
  Future<bool> syncToICloud() async {
    try {
      debugPrint('开始同步数据到 iCloud...');

      final syncDir = await _getICloudDirectory();
      if (syncDir == null) {
        debugPrint('无法获取 iCloud 目录，使用本地同步');
        return await _syncToLocal();
      }

      // 同步证件数据
      await _syncDocuments(syncDir);

      // 同步导出记录
      await _syncExportRecords(syncDir);

      // 同步安全配置
      await _syncSecurityConfig(syncDir);

      // 同步水印配置
      await _syncWatermarkConfig(syncDir);

      // 更新同步状态
      await _updateSyncStatus(true);

      debugPrint('数据同步到 iCloud 完成');
      return true;
    } catch (e) {
      debugPrint('同步到 iCloud 失败: $e');
      await _updateSyncStatus(false, error: e.toString());
      return false;
    }
  }

  /// 从 iCloud 同步数据
  Future<bool> syncFromICloud() async {
    try {
      debugPrint('开始从 iCloud 同步数据...');

      final syncDir = await _getICloudDirectory();
      if (syncDir == null) {
        debugPrint('无法获取 iCloud 目录，从本地同步');
        return await _syncFromLocal();
      }

      // 同步证件数据
      await _syncDocumentsFromCloud(syncDir);

      // 同步导出记录
      await _syncExportRecordsFromCloud(syncDir);

      // 同步安全配置
      await _syncSecurityConfigFromCloud(syncDir);

      // 同步水印配置
      await _syncWatermarkConfigFromCloud(syncDir);

      // 更新同步状态
      await _updateSyncStatus(true);

      debugPrint('从 iCloud 同步数据完成');
      return true;
    } catch (e) {
      debugPrint('从 iCloud 同步失败: $e');
      await _updateSyncStatus(false, error: e.toString());
      return false;
    }
  }

  /// 同步证件数据（含图片文件）
  Future<void> _syncDocuments(Directory syncDir) async {
    try {
      final documents = await _documentService.getAllDocuments();
      final imagesDir = Directory(path.join(syncDir.path, 'images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      final List<Map<String, dynamic>> documentsJson = [];
      for (final doc in documents) {
        final List<Map<String, dynamic>> photosJson = [];

        for (final photo in doc.photos) {
          // 复制原始图片
          String? newOriginalPath;
          if (photo.originalImagePath.isNotEmpty &&
              await File(photo.originalImagePath).exists()) {
            final fileName = path.basename(photo.originalImagePath);
            final destPath = path.join(imagesDir.path, fileName);
            await File(photo.originalImagePath).copy(destPath);
            newOriginalPath = 'images/$fileName';
          }
          // 复制缩略图
          String? newThumbPath;
          if (photo.thumbnailPath != null &&
              photo.thumbnailPath!.isNotEmpty &&
              await File(photo.thumbnailPath!).exists()) {
            final thumbName = path.basename(photo.thumbnailPath!);
            final destThumbPath = path.join(imagesDir.path, thumbName);
            await File(photo.thumbnailPath!).copy(destThumbPath);
            newThumbPath = 'images/$thumbName';
          }

          // 创建照片JSON
          final photoJson = photo.toJson();
          if (newOriginalPath != null)
            photoJson['originalImagePath'] = newOriginalPath;
          if (newThumbPath != null) photoJson['thumbnailPath'] = newThumbPath;
          photosJson.add(photoJson);
        }

        // 保存证件JSON
        final json = doc.toJson();
        json['photos'] = photosJson;
        documentsJson.add(json);
      }
      final file = File(path.join(syncDir.path, _documentsFileName));
      await file.writeAsString(
        jsonEncode({
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'documents': documentsJson,
        }),
      );
      debugPrint('证件数据和图片同步完成: ${documents.length} 条记录');
    } catch (e) {
      debugPrint('同步证件数据失败: $e');
      rethrow;
    }
  }

  /// 从云端同步证件数据（含图片文件）
  Future<void> _syncDocumentsFromCloud(Directory syncDir) async {
    try {
      final file = File(path.join(syncDir.path, _documentsFileName));
      if (!await file.exists()) {
        debugPrint('云端证件数据文件不存在');
        return;
      }
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data['documents'] != null) {
        final List<IdDocument> documents = [];
        final imagesDir = Directory(path.join(syncDir.path, 'images'));
        final appDocDir = await getApplicationDocumentsDirectory();
        final localImagesDir = Directory(path.join(appDocDir.path, 'images'));
        if (!await localImagesDir.exists()) {
          await localImagesDir.create(recursive: true);
        }
        for (final d in data['documents']) {
          final List<Map<String, dynamic>> photosJson = [];

          if (d['photos'] != null) {
            for (final photoData in d['photos']) {
              // 恢复图片文件
              String? restoredOriginalPath;
              if (photoData['originalImagePath'] != null &&
                  photoData['originalImagePath'].toString().startsWith(
                    'images/',
                  )) {
                final fileName = path.basename(photoData['originalImagePath']);
                final srcPath = path.join(imagesDir.path, fileName);
                final destPath = path.join(localImagesDir.path, fileName);
                if (await File(srcPath).exists()) {
                  await File(srcPath).copy(destPath);
                  restoredOriginalPath = destPath;
                }
              }
              String? restoredThumbPath;
              if (photoData['thumbnailPath'] != null &&
                  photoData['thumbnailPath'].toString().startsWith('images/')) {
                final thumbName = path.basename(photoData['thumbnailPath']);
                final srcThumbPath = path.join(imagesDir.path, thumbName);
                final destThumbPath = path.join(localImagesDir.path, thumbName);
                if (await File(srcThumbPath).exists()) {
                  await File(srcThumbPath).copy(destThumbPath);
                  restoredThumbPath = destThumbPath;
                }
              }

              // 更新照片路径
              final photoJson = Map<String, dynamic>.from(photoData);
              photoJson['originalImagePath'] =
                  restoredOriginalPath ?? photoData['originalImagePath'];
              photoJson['thumbnailPath'] =
                  restoredThumbPath ?? photoData['thumbnailPath'];
              photosJson.add(photoJson);
            }
          }

          // 更新证件数据
          final documentJson = Map<String, dynamic>.from(d);
          documentJson['photos'] = photosJson;
          documents.add(IdDocument.fromJson(documentJson));
        }
        await _documentService.restoreDocuments(documents);
        debugPrint('从云端同步证件数据和图片完成: ${documents.length} 条记录');
      }
    } catch (e) {
      debugPrint('从云端同步证件数据失败: $e');
      rethrow;
    }
  }

  /// 同步导出记录（含水印照片文件）
  Future<void> _syncExportRecords(Directory syncDir) async {
    try {
      final records = await _documentService.getAllExportRecords();
      final exportedDir = Directory(path.join(syncDir.path, 'exported'));
      if (!await exportedDir.exists()) {
        await exportedDir.create(recursive: true);
      }
      final List<Map<String, dynamic>> recordsJson = [];
      for (final record in records) {
        String? newExportPath;
        if (record.exportPath.isNotEmpty &&
            await File(record.exportPath).exists()) {
          final fileName = path.basename(record.exportPath);
          final destPath = path.join(exportedDir.path, fileName);
          await File(record.exportPath).copy(destPath);
          newExportPath = 'exported/$fileName';
        }
        final json = record.toJson();
        if (newExportPath != null) json['exportPath'] = newExportPath;
        recordsJson.add(json);
      }
      final file = File(path.join(syncDir.path, _exportRecordsFileName));
      await file.writeAsString(
        jsonEncode({
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'records': recordsJson,
        }),
      );
      debugPrint('导出记录和水印照片同步完成: ${records.length} 条记录');
    } catch (e) {
      debugPrint('同步导出记录失败: $e');
      rethrow;
    }
  }

  /// 从云端同步导出记录（含水印照片文件）
  Future<void> _syncExportRecordsFromCloud(Directory syncDir) async {
    try {
      final file = File(path.join(syncDir.path, _exportRecordsFileName));
      if (!await file.exists()) {
        debugPrint('云端导出记录文件不存在');
        return;
      }
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data['records'] != null) {
        final List<ExportRecord> records = [];
        final exportedDir = Directory(path.join(syncDir.path, 'exported'));
        final appDocDir = await getApplicationDocumentsDirectory();
        final localExportedDir = Directory(
          path.join(appDocDir.path, 'exported'),
        );
        if (!await localExportedDir.exists()) {
          await localExportedDir.create(recursive: true);
        }
        for (final r in data['records']) {
          String? restoredExportPath;
          if (r['exportPath'] != null &&
              r['exportPath'].toString().startsWith('exported/')) {
            final fileName = path.basename(r['exportPath']);
            final srcPath = path.join(exportedDir.path, fileName);
            final destPath = path.join(localExportedDir.path, fileName);
            if (await File(srcPath).exists()) {
              await File(srcPath).copy(destPath);
              restoredExportPath = destPath;
            }
          }
          r['exportPath'] = restoredExportPath ?? r['exportPath'];
          records.add(ExportRecord.fromJson(r));
        }
        await _documentService.restoreExportRecords(records);
        debugPrint('从云端同步导出记录和水印照片完成: ${records.length} 条记录');
      }
    } catch (e) {
      debugPrint('从云端同步导出记录失败: $e');
      rethrow;
    }
  }

  /// 同步安全配置
  Future<void> _syncSecurityConfig(Directory syncDir) async {
    try {
      final config = await _documentService.getSecurityConfig();

      final file = File(path.join(syncDir.path, _securityConfigFileName));
      await file.writeAsString(
        jsonEncode({
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'config': config.toJson(),
        }),
      );

      debugPrint('安全配置同步完成');
    } catch (e) {
      debugPrint('同步安全配置失败: $e');
      rethrow;
    }
  }

  /// 从云端同步安全配置
  Future<void> _syncSecurityConfigFromCloud(Directory syncDir) async {
    try {
      final file = File(path.join(syncDir.path, _securityConfigFileName));
      if (!await file.exists()) {
        debugPrint('云端安全配置文件不存在');
        return;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data['config'] != null) {
        final config = SecurityConfig.fromJson(data['config']);
        await _documentService.saveSecurityConfig(config);
        debugPrint('从云端同步安全配置完成');
      }
    } catch (e) {
      debugPrint('从云端同步安全配置失败: $e');
      rethrow;
    }
  }

  /// 同步水印配置
  Future<void> _syncWatermarkConfig(Directory syncDir) async {
    try {
      final config = await _documentService.getWatermarkConfig();

      final file = File(path.join(syncDir.path, _watermarkConfigFileName));
      await file.writeAsString(
        jsonEncode({
          'version': '1.0',
          'timestamp': DateTime.now().toIso8601String(),
          'config': config.toJson(),
        }),
      );

      debugPrint('水印配置同步完成');
    } catch (e) {
      debugPrint('同步水印配置失败: $e');
      rethrow;
    }
  }

  /// 从云端同步水印配置
  Future<void> _syncWatermarkConfigFromCloud(Directory syncDir) async {
    try {
      final file = File(path.join(syncDir.path, _watermarkConfigFileName));
      if (!await file.exists()) {
        debugPrint('云端水印配置文件不存在');
        return;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content);

      if (data['config'] != null) {
        final config = WatermarkConfig.fromJson(data['config']);
        await _documentService.saveWatermarkConfig(config);
        debugPrint('从云端同步水印配置完成');
      }
    } catch (e) {
      debugPrint('从云端同步水印配置失败: $e');
      rethrow;
    }
  }

  /// 本地同步（作为备份方案）
  Future<bool> _syncToLocal() async {
    try {
      final syncDir = await _getLocalSyncDirectory();

      await _syncDocuments(syncDir);
      await _syncExportRecords(syncDir);
      await _syncSecurityConfig(syncDir);
      await _syncWatermarkConfig(syncDir);

      await _updateSyncStatus(true, isLocal: true);
      debugPrint('数据同步到本地完成');
      return true;
    } catch (e) {
      debugPrint('本地同步失败: $e');
      await _updateSyncStatus(false, error: e.toString(), isLocal: true);
      return false;
    }
  }

  /// 从本地同步
  Future<bool> _syncFromLocal() async {
    try {
      final syncDir = await _getLocalSyncDirectory();

      await _syncDocumentsFromCloud(syncDir);
      await _syncExportRecordsFromCloud(syncDir);
      await _syncSecurityConfigFromCloud(syncDir);
      await _syncWatermarkConfigFromCloud(syncDir);

      await _updateSyncStatus(true, isLocal: true);
      debugPrint('从本地同步数据完成');
      return true;
    } catch (e) {
      debugPrint('从本地同步失败: $e');
      await _updateSyncStatus(false, error: e.toString(), isLocal: true);
      return false;
    }
  }

  /// 更新同步状态
  Future<void> _updateSyncStatus(
    bool success, {
    String? error,
    bool isLocal = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final status = {
      'lastSyncTime': DateTime.now().toIso8601String(),
      'success': success,
      'isLocal': isLocal,
      'error': error,
    };
    await prefs.setString(_syncStatusKey, jsonEncode(status));
  }

  /// 获取同步状态
  Future<Map<String, dynamic>?> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusJson = prefs.getString(_syncStatusKey);
      if (statusJson != null) {
        return jsonDecode(statusJson);
      }
    } catch (e) {
      debugPrint('获取同步状态失败: $e');
    }
    return null;
  }

  /// 检查是否有新的云端数据
  Future<bool> hasCloudUpdates() async {
    try {
      final syncDir = await _getICloudDirectory();
      if (syncDir == null) return false;

      final status = await getSyncStatus();
      if (status == null) return true;

      final lastSyncTime = DateTime.parse(status['lastSyncTime']);
      final now = DateTime.now();

      // 检查文件修改时间
      final files = [
        _documentsFileName,
        _exportRecordsFileName,
        _securityConfigFileName,
        _watermarkConfigFileName,
      ];

      for (final fileName in files) {
        final file = File(path.join(syncDir.path, fileName));
        if (await file.exists()) {
          final stat = await file.stat();
          if (stat.modified.isAfter(lastSyncTime)) {
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('检查云端更新失败: $e');
      return false;
    }
  }

  /// 强制同步（忽略时间戳）
  Future<bool> forceSync() async {
    try {
      await _updateSyncStatus(false); // 清除上次同步状态
      return await syncFromICloud();
    } catch (e) {
      debugPrint('强制同步失败: $e');
      return false;
    }
  }

  /// 清理同步数据
  Future<void> clearSyncData() async {
    try {
      final syncDir = await _getICloudDirectory();
      if (syncDir != null && await syncDir.exists()) {
        await syncDir.delete(recursive: true);
      }

      final localSyncDir = await _getLocalSyncDirectory();
      if (await localSyncDir.exists()) {
        await localSyncDir.delete(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncStatusKey);

      debugPrint('同步数据已清理');
    } catch (e) {
      debugPrint('清理同步数据失败: $e');
    }
  }
}
