import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/backup_provider.dart';

/// 自动备份服务
class AutoBackupService {
  static AutoBackupService? _instance;
  Timer? _timer;
  final BackupProvider _backupProvider;

  AutoBackupService._(this._backupProvider);

  /// 获取单例实例
  static AutoBackupService getInstance(BackupProvider backupProvider) {
    _instance ??= AutoBackupService._(backupProvider);
    return _instance!;
  }

  /// 启动自动备份检查
  void startAutoBackupCheck() {
    // 停止现有的定时器
    stopAutoBackupCheck();

    // 创建新的定时器，每小时检查一次
    _timer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkAndPerformAutoBackup();
    });

    debugPrint('自动备份检查已启动');
  }

  /// 停止自动备份检查
  void stopAutoBackupCheck() {
    _timer?.cancel();
    _timer = null;
    debugPrint('自动备份检查已停止');
  }

  /// 检查并执行自动备份
  Future<void> _checkAndPerformAutoBackup() async {
    try {
      final needsBackup = await _backupProvider.needsAutoBackup();

      if (needsBackup) {
        debugPrint('开始执行自动备份');
        await _backupProvider.performAutoBackup();
        debugPrint('自动备份完成');
      }
    } catch (e) {
      debugPrint('自动备份检查失败: $e');
    }
  }

  /// 立即检查一次
  Future<void> checkNow() async {
    await _checkAndPerformAutoBackup();
  }

  /// 销毁服务
  void dispose() {
    stopAutoBackupCheck();
    _instance = null;
  }
}
