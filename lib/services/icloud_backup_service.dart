import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/backup_config.dart';
import '../models/backup_record.dart';
import '../models/id_document.dart';
import '../models/export_record.dart';
import '../models/security_config.dart';
import '../models/watermark_config.dart';
import 'document_service.dart';

/// iCloud 备份服务
class ICloudBackupService {
  static const String _backupConfigKey = 'backup_config';
  static const String _backupRecordsKey = 'backup_records';
  static const String _backupFolderName = 'MarkID_Backups';

  final DocumentService _documentService;
  final Uuid _uuid = const Uuid();

  ICloudBackupService(this._documentService);

  /// 获取备份配置
  Future<BackupConfig> getBackupConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_backupConfigKey);

    if (configJson != null) {
      try {
        return BackupConfig.fromJson(jsonDecode(configJson));
      } catch (e) {
        debugPrint('解析备份配置失败: $e');
      }
    }

    return const BackupConfig();
  }

  /// 保存备份配置
  Future<void> saveBackupConfig(BackupConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupConfigKey, jsonEncode(config.toJson()));
  }

  /// 获取备份记录列表
  Future<List<BackupRecord>> getBackupRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_backupRecordsKey) ?? [];

    final records = <BackupRecord>[];
    for (final recordJson in recordsJson) {
      try {
        records.add(BackupRecord.fromJson(jsonDecode(recordJson)));
      } catch (e) {
        debugPrint('解析备份记录失败: $e');
      }
    }

    // 按时间倒序排列
    records.sort((a, b) => b.backupTime.compareTo(a.backupTime));
    return records;
  }

  /// 保存备份记录
  Future<void> saveBackupRecord(BackupRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getBackupRecords();

    // 添加新记录
    records.insert(0, record);

    // 只保留最近50条记录
    if (records.length > 50) {
      records.removeRange(50, records.length);
    }

    // 保存记录
    final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_backupRecordsKey, recordsJson);
  }

  /// 执行自动备份
  Future<BackupRecord> performAutoBackup() async {
    return await _performBackup(BackupType.automatic);
  }

  /// 执行手动备份
  Future<BackupRecord> performManualBackup() async {
    return await _performBackup(BackupType.manual);
  }

  /// 执行备份
  Future<BackupRecord> _performBackup(BackupType type) async {
    final startTime = DateTime.now();
    final backupId = _uuid.v4();

    // 创建备份记录
    BackupRecord record = BackupRecord(
      id: backupId,
      backupTime: startTime,
      type: type,
      status: BackupStatus.inProgress,
      sizeBytes: 0,
      contents: [],
      deviceInfo: await _getDeviceInfo(),
      appVersion: await _getAppVersion(),
    );

    try {
      // 获取备份配置
      final config = await getBackupConfig();

      // 检查网络条件
      if (config.backupOnlyOnWifi && !await _isWifiConnected()) {
        throw Exception('当前网络不是WiFi，无法执行备份');
      }

      // 准备备份数据
      final backupData = await _prepareBackupData(config);

      // 创建备份文件
      final backupFile = await _createBackupFile(
        backupData,
        config.compressBackup,
      );

      // 上传到iCloud
      final cloudPath = await _uploadToICloud(backupFile, backupId);

      // 计算备份大小
      final fileSize = await backupFile.length();

      // 更新备份记录
      record = record.copyWith(
        status: BackupStatus.success,
        sizeBytes: fileSize,
        backupFilePath: cloudPath,
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
        contents: backupData.contents,
      );

      // 保存备份记录
      await saveBackupRecord(record);

      // 更新备份配置
      final updatedConfig = config.copyWith(
        lastBackupTime: startTime,
        nextBackupTime: config.calculateNextBackupTime(),
      );
      await saveBackupConfig(updatedConfig);

      debugPrint(
        '备份完成: ${record.sizeFormatted}, 耗时: ${record.durationFormatted}',
      );
    } catch (e) {
      debugPrint('备份失败: $e');

      // 更新失败记录
      record = record.copyWith(
        status: BackupStatus.failed,
        errorMessage: e.toString(),
        durationMs: DateTime.now().difference(startTime).inMilliseconds,
      );

      await saveBackupRecord(record);
    }

    return record;
  }

  /// 准备备份数据
  Future<BackupData> _prepareBackupData(BackupConfig config) async {
    final contents = <BackupContent>[];
    final data = <String, dynamic>{};

    try {
      // 备份文档数据
      if (config.backupDocuments) {
        final documents = await _documentService.getAllDocuments();
        data['documents'] = documents.map((d) => d.toJson()).toList();

        contents.add(
          BackupContent(
            type: 'documents',
            name: '证件数据',
            sizeBytes: jsonEncode(data['documents']).length,
            success: true,
          ),
        );
      }

      // 备份导出记录
      if (config.backupExportRecords) {
        final exportRecords = await _documentService.getAllExportRecords();
        data['exportRecords'] = exportRecords.map((r) => r.toJson()).toList();

        contents.add(
          BackupContent(
            type: 'exportRecords',
            name: '导出记录',
            sizeBytes: jsonEncode(data['exportRecords']).length,
            success: true,
          ),
        );
      }

      // 备份安全配置
      if (config.backupSecurityConfig) {
        final securityConfig = await _documentService.getSecurityConfig();
        data['securityConfig'] = securityConfig.toJson();

        contents.add(
          BackupContent(
            type: 'securityConfig',
            name: '安全配置',
            sizeBytes: jsonEncode(data['securityConfig']).length,
            success: true,
          ),
        );
      }

      // 备份水印配置
      if (config.backupWatermarkConfig) {
        final watermarkConfig = await _documentService.getWatermarkConfig();
        data['watermarkConfig'] = watermarkConfig.toJson();

        contents.add(
          BackupContent(
            type: 'watermarkConfig',
            name: '水印配置',
            sizeBytes: jsonEncode(data['watermarkConfig']).length,
            success: true,
          ),
        );
      }

      // 备份加密密钥（谨慎处理）
      if (config.backupEncryptionKeys) {
        // 这里应该实现安全的密钥备份逻辑
        // 出于安全考虑，暂时不实现
        contents.add(
          BackupContent(
            type: 'encryptionKeys',
            name: '加密密钥',
            sizeBytes: 0,
            success: false,
            errorMessage: '出于安全考虑，暂不支持密钥备份',
          ),
        );
      }

      // 添加备份元数据
      data['backupMetadata'] = {
        'version': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'config': config.toJson(),
      };
    } catch (e) {
      debugPrint('准备备份数据失败: $e');
      contents.add(
        BackupContent(
          type: 'error',
          name: '数据准备',
          sizeBytes: 0,
          success: false,
          errorMessage: e.toString(),
        ),
      );
    }

    return BackupData(data: data, contents: contents);
  }

  /// 创建备份文件
  Future<File> _createBackupFile(BackupData backupData, bool compress) async {
    final backupDir = await _getBackupDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'backup_$timestamp.json';
    final filePath = path.join(backupDir.path, fileName);

    final file = File(filePath);
    final jsonString = jsonEncode(backupData.data);

    if (compress) {
      // 这里可以实现压缩逻辑
      // 暂时直接保存JSON
      await file.writeAsString(jsonString);
    } else {
      await file.writeAsString(jsonString);
    }

    return file;
  }

  /// 上传到iCloud
  Future<String> _uploadToICloud(File backupFile, String backupId) async {
    // 这里应该实现真正的iCloud上传逻辑
    // 由于Flutter的限制，我们需要使用原生平台通道或第三方插件

    // 模拟上传过程
    await Future.delayed(const Duration(seconds: 2));

    // 返回云存储路径
    return 'iCloud/$_backupFolderName/$backupId.json';
  }

  /// 从iCloud恢复备份
  Future<bool> restoreFromBackup(String backupId) async {
    try {
      // 从iCloud下载备份文件
      final backupFile = await _downloadFromICloud(backupId);

      // 解析备份数据
      final jsonString = await backupFile.readAsString();
      final backupData = jsonDecode(jsonString);

      // 恢复数据
      await _restoreData(backupData);

      return true;
    } catch (e) {
      debugPrint('恢复备份失败: $e');
      return false;
    }
  }

  /// 从iCloud下载备份文件
  Future<File> _downloadFromICloud(String backupId) async {
    // 这里应该实现真正的iCloud下载逻辑
    // 模拟下载过程
    await Future.delayed(const Duration(seconds: 2));

    // 返回临时文件路径
    final tempDir = await getTemporaryDirectory();
    final filePath = path.join(tempDir.path, 'restore_$backupId.json');
    return File(filePath);
  }

  /// 恢复数据
  Future<void> _restoreData(Map<String, dynamic> backupData) async {
    // 恢复文档数据
    if (backupData['documents'] != null) {
      final documents = (backupData['documents'] as List)
          .map((d) => IdDocument.fromJson(d))
          .toList();
      await _documentService.restoreDocuments(documents);
    }

    // 恢复导出记录
    if (backupData['exportRecords'] != null) {
      final exportRecords = (backupData['exportRecords'] as List)
          .map((r) => ExportRecord.fromJson(r))
          .toList();
      await _documentService.restoreExportRecords(exportRecords);
    }

    // 恢复安全配置
    if (backupData['securityConfig'] != null) {
      final securityConfig = SecurityConfig.fromJson(
        backupData['securityConfig'],
      );
      await _documentService.saveSecurityConfig(securityConfig);
    }

    // 恢复水印配置
    if (backupData['watermarkConfig'] != null) {
      final watermarkConfig = WatermarkConfig.fromJson(
        backupData['watermarkConfig'],
      );
      await _documentService.saveWatermarkConfig(watermarkConfig);
    }
  }

  /// 获取备份目录
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, _backupFolderName));

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// 检查是否需要自动备份
  Future<bool> needsAutoBackup() async {
    final config = await getBackupConfig();
    return config.needsBackup;
  }

  /// 检查WiFi连接
  Future<bool> _isWifiConnected() async {
    try {
      // 这里应该实现真正的网络检查逻辑
      // 暂时返回true
      return true;
    } catch (e) {
      debugPrint('检查网络连接失败: $e');
      return false;
    }
  }

  /// 获取设备信息
  Future<String> _getDeviceInfo() async {
    // 这里应该获取真实的设备信息
    return 'iOS Device';
  }

  /// 获取应用版本
  Future<String> _getAppVersion() async {
    // 这里应该获取真实的应用版本
    return '1.0.0';
  }

  /// 删除备份记录
  Future<void> deleteBackupRecord(String backupId) async {
    final records = await getBackupRecords();
    records.removeWhere((record) => record.id == backupId);

    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_backupRecordsKey, recordsJson);
  }

  /// 清理过期备份
  Future<void> cleanupOldBackups({int keepDays = 30}) async {
    final records = await getBackupRecords();
    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

    final validRecords = records
        .where((record) => record.backupTime.isAfter(cutoffDate))
        .toList();

    if (validRecords.length != records.length) {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = validRecords
          .map((r) => jsonEncode(r.toJson()))
          .toList();
      await prefs.setStringList(_backupRecordsKey, recordsJson);
    }
  }
}

/// 备份数据包装类
class BackupData {
  final Map<String, dynamic> data;
  final List<BackupContent> contents;

  const BackupData({required this.data, required this.contents});
}
