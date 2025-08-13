import 'package:flutter/foundation.dart';

/// 备份配置模型
class BackupConfig {
  /// 是否启用自动备份
  final bool enabled;

  /// 备份频率（小时）
  final int frequencyHours;

  /// 是否备份文档数据
  final bool backupDocuments;

  /// 是否备份导出记录
  final bool backupExportRecords;

  /// 是否备份安全配置
  final bool backupSecurityConfig;

  /// 是否备份水印配置
  final bool backupWatermarkConfig;

  /// 是否备份加密密钥
  final bool backupEncryptionKeys;

  /// 最后备份时间
  final DateTime? lastBackupTime;

  /// 下次备份时间
  final DateTime? nextBackupTime;

  /// 备份大小限制（MB）
  final int maxBackupSizeMB;

  /// 是否仅在WiFi下备份
  final bool backupOnlyOnWifi;

  /// 是否压缩备份数据
  final bool compressBackup;

  const BackupConfig({
    this.enabled = false,
    this.frequencyHours = 24,
    this.backupDocuments = true,
    this.backupExportRecords = true,
    this.backupSecurityConfig = true,
    this.backupWatermarkConfig = true,
    this.backupEncryptionKeys = false, // 默认不备份加密密钥，出于安全考虑
    this.lastBackupTime,
    this.nextBackupTime,
    this.maxBackupSizeMB = 100,
    this.backupOnlyOnWifi = true,
    this.compressBackup = true,
  });

  /// 从JSON创建实例
  factory BackupConfig.fromJson(Map<String, dynamic> json) {
    return BackupConfig(
      enabled: json['enabled'] ?? false,
      frequencyHours: json['frequencyHours'] ?? 24,
      backupDocuments: json['backupDocuments'] ?? true,
      backupExportRecords: json['backupExportRecords'] ?? true,
      backupSecurityConfig: json['backupSecurityConfig'] ?? true,
      backupWatermarkConfig: json['backupWatermarkConfig'] ?? true,
      backupEncryptionKeys: json['backupEncryptionKeys'] ?? false,
      lastBackupTime: json['lastBackupTime'] != null
          ? DateTime.parse(json['lastBackupTime'])
          : null,
      nextBackupTime: json['nextBackupTime'] != null
          ? DateTime.parse(json['nextBackupTime'])
          : null,
      maxBackupSizeMB: json['maxBackupSizeMB'] ?? 100,
      backupOnlyOnWifi: json['backupOnlyOnWifi'] ?? true,
      compressBackup: json['compressBackup'] ?? true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'frequencyHours': frequencyHours,
      'backupDocuments': backupDocuments,
      'backupExportRecords': backupExportRecords,
      'backupSecurityConfig': backupSecurityConfig,
      'backupWatermarkConfig': backupWatermarkConfig,
      'backupEncryptionKeys': backupEncryptionKeys,
      'lastBackupTime': lastBackupTime?.toIso8601String(),
      'nextBackupTime': nextBackupTime?.toIso8601String(),
      'maxBackupSizeMB': maxBackupSizeMB,
      'backupOnlyOnWifi': backupOnlyOnWifi,
      'compressBackup': compressBackup,
    };
  }

  /// 复制并更新
  BackupConfig copyWith({
    bool? enabled,
    int? frequencyHours,
    bool? backupDocuments,
    bool? backupExportRecords,
    bool? backupSecurityConfig,
    bool? backupWatermarkConfig,
    bool? backupEncryptionKeys,
    DateTime? lastBackupTime,
    DateTime? nextBackupTime,
    int? maxBackupSizeMB,
    bool? backupOnlyOnWifi,
    bool? compressBackup,
  }) {
    return BackupConfig(
      enabled: enabled ?? this.enabled,
      frequencyHours: frequencyHours ?? this.frequencyHours,
      backupDocuments: backupDocuments ?? this.backupDocuments,
      backupExportRecords: backupExportRecords ?? this.backupExportRecords,
      backupSecurityConfig: backupSecurityConfig ?? this.backupSecurityConfig,
      backupWatermarkConfig:
          backupWatermarkConfig ?? this.backupWatermarkConfig,
      backupEncryptionKeys: backupEncryptionKeys ?? this.backupEncryptionKeys,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      nextBackupTime: nextBackupTime ?? this.nextBackupTime,
      maxBackupSizeMB: maxBackupSizeMB ?? this.maxBackupSizeMB,
      backupOnlyOnWifi: backupOnlyOnWifi ?? this.backupOnlyOnWifi,
      compressBackup: compressBackup ?? this.compressBackup,
    );
  }

  /// 检查是否需要备份
  bool get needsBackup {
    if (!enabled) return false;
    if (nextBackupTime == null) return true;
    return DateTime.now().isAfter(nextBackupTime!);
  }

  /// 计算下次备份时间
  DateTime calculateNextBackupTime() {
    return DateTime.now().add(Duration(hours: frequencyHours));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupConfig &&
        other.enabled == enabled &&
        other.frequencyHours == frequencyHours &&
        other.backupDocuments == backupDocuments &&
        other.backupExportRecords == backupExportRecords &&
        other.backupSecurityConfig == backupSecurityConfig &&
        other.backupWatermarkConfig == backupWatermarkConfig &&
        other.backupEncryptionKeys == backupEncryptionKeys &&
        other.lastBackupTime == lastBackupTime &&
        other.nextBackupTime == nextBackupTime &&
        other.maxBackupSizeMB == maxBackupSizeMB &&
        other.backupOnlyOnWifi == backupOnlyOnWifi &&
        other.compressBackup == compressBackup;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      frequencyHours,
      backupDocuments,
      backupExportRecords,
      backupSecurityConfig,
      backupWatermarkConfig,
      backupEncryptionKeys,
      lastBackupTime,
      nextBackupTime,
      maxBackupSizeMB,
      backupOnlyOnWifi,
      compressBackup,
    );
  }

  @override
  String toString() {
    return 'BackupConfig(enabled: $enabled, frequencyHours: $frequencyHours, backupDocuments: $backupDocuments, backupExportRecords: $backupExportRecords, backupSecurityConfig: $backupSecurityConfig, backupWatermarkConfig: $backupWatermarkConfig, backupEncryptionKeys: $backupEncryptionKeys, lastBackupTime: $lastBackupTime, nextBackupTime: $nextBackupTime, maxBackupSizeMB: $maxBackupSizeMB, backupOnlyOnWifi: $backupOnlyOnWifi, compressBackup: $compressBackup)';
  }
}
