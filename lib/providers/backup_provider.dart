import 'package:flutter/foundation.dart';
import '../models/backup_config.dart';
import '../models/backup_record.dart';
import '../services/icloud_backup_service.dart';
import '../services/document_service.dart';

/// 备份状态提供者
class BackupProvider extends ChangeNotifier {
  final ICloudBackupService _backupService;

  BackupConfig _config = const BackupConfig();
  List<BackupRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  BackupRecord? _currentBackup;

  BackupProvider(DocumentService documentService)
    : _backupService = ICloudBackupService(documentService);

  /// 备份配置
  BackupConfig get config => _config;

  /// 备份记录列表
  List<BackupRecord> get records => _records;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 当前备份
  BackupRecord? get currentBackup => _currentBackup;

  /// 初始化
  Future<void> initialize() async {
    await loadBackupConfig();
    await loadBackupRecords();
  }

  /// 加载备份配置
  Future<void> loadBackupConfig() async {
    try {
      _config = await _backupService.getBackupConfig();
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载备份配置失败: $e';
      notifyListeners();
    }
  }

  /// 保存备份配置
  Future<void> saveBackupConfig(BackupConfig config) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _backupService.saveBackupConfig(config);
      _config = config;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '保存备份配置失败: $e';
      notifyListeners();
    }
  }

  /// 加载备份记录
  Future<void> loadBackupRecords() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _records = await _backupService.getBackupRecords();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '加载备份记录失败: $e';
      notifyListeners();
    }
  }

  /// 执行手动备份
  Future<void> performManualBackup() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentBackup = null;
      notifyListeners();

      final record = await _backupService.performManualBackup();
      _currentBackup = record;

      // 重新加载记录
      await loadBackupRecords();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '手动备份失败: $e';
      notifyListeners();
    }
  }

  /// 执行自动备份
  Future<void> performAutoBackup() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentBackup = null;
      notifyListeners();

      final record = await _backupService.performAutoBackup();
      _currentBackup = record;

      // 重新加载记录
      await loadBackupRecords();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '自动备份失败: $e';
      notifyListeners();
    }
  }

  /// 从备份恢复
  Future<bool> restoreFromBackup(String backupId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _backupService.restoreFromBackup(backupId);

      _isLoading = false;
      notifyListeners();

      return success;
    } catch (e) {
      _isLoading = false;
      _errorMessage = '恢复备份失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 删除备份记录
  Future<void> deleteBackupRecord(String backupId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _backupService.deleteBackupRecord(backupId);

      // 重新加载记录
      await loadBackupRecords();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '删除备份记录失败: $e';
      notifyListeners();
    }
  }

  /// 清理过期备份
  Future<void> cleanupOldBackups({int keepDays = 30}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _backupService.cleanupOldBackups(keepDays: keepDays);

      // 重新加载记录
      await loadBackupRecords();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = '清理过期备份失败: $e';
      notifyListeners();
    }
  }

  /// 检查是否需要自动备份
  Future<bool> needsAutoBackup() async {
    try {
      return await _backupService.needsAutoBackup();
    } catch (e) {
      debugPrint('检查自动备份失败: $e');
      return false;
    }
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除当前备份
  void clearCurrentBackup() {
    _currentBackup = null;
    notifyListeners();
  }

  /// 获取备份统计信息
  Map<String, dynamic> getBackupStats() {
    final totalBackups = _records.length;
    final successfulBackups = _records
        .where((r) => r.status == BackupStatus.success)
        .length;
    final failedBackups = _records
        .where((r) => r.status == BackupStatus.failed)
        .length;
    final totalSize = _records.fold<int>(0, (sum, r) => sum + r.sizeBytes);

    final lastBackup = _records.isNotEmpty ? _records.first : null;

    return {
      'totalBackups': totalBackups,
      'successfulBackups': successfulBackups,
      'failedBackups': failedBackups,
      'totalSize': totalSize,
      'totalSizeFormatted': _formatSize(totalSize),
      'lastBackup': lastBackup,
      'successRate': totalBackups > 0
          ? (successfulBackups / totalBackups * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// 格式化文件大小
  String _formatSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取最近的备份记录
  List<BackupRecord> getRecentBackups({int limit = 10}) {
    return _records.take(limit).toList();
  }

  /// 获取成功的备份记录
  List<BackupRecord> getSuccessfulBackups() {
    return _records.where((r) => r.status == BackupStatus.success).toList();
  }

  /// 获取失败的备份记录
  List<BackupRecord> getFailedBackups() {
    return _records.where((r) => r.status == BackupStatus.failed).toList();
  }
}
