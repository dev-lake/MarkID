import 'package:flutter/foundation.dart';

/// 备份记录模型
class BackupRecord {
  /// 备份ID
  final String id;

  /// 备份时间
  final DateTime backupTime;

  /// 备份类型（自动/手动）
  final BackupType type;

  /// 备份状态
  final BackupStatus status;

  /// 备份大小（字节）
  final int sizeBytes;

  /// 备份内容
  final List<BackupContent> contents;

  /// 备份文件路径
  final String? backupFilePath;

  /// 错误信息（如果备份失败）
  final String? errorMessage;

  /// 备份耗时（毫秒）
  final int? durationMs;

  /// 设备信息
  final String deviceInfo;

  /// 应用版本
  final String appVersion;

  const BackupRecord({
    required this.id,
    required this.backupTime,
    required this.type,
    required this.status,
    required this.sizeBytes,
    required this.contents,
    this.backupFilePath,
    this.errorMessage,
    this.durationMs,
    required this.deviceInfo,
    required this.appVersion,
  });

  /// 从JSON创建实例
  factory BackupRecord.fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      id: json['id'],
      backupTime: DateTime.parse(json['backupTime']),
      type: BackupType.values.firstWhere(
        (e) => e.toString() == 'BackupType.${json['type']}',
        orElse: () => BackupType.manual,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString() == 'BackupStatus.${json['status']}',
        orElse: () => BackupStatus.failed,
      ),
      sizeBytes: json['sizeBytes'] ?? 0,
      contents:
          (json['contents'] as List<dynamic>?)
              ?.map((e) => BackupContent.fromJson(e))
              .toList() ??
          [],
      backupFilePath: json['backupFilePath'],
      errorMessage: json['errorMessage'],
      durationMs: json['durationMs'],
      deviceInfo: json['deviceInfo'] ?? '',
      appVersion: json['appVersion'] ?? '',
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'backupTime': backupTime.toIso8601String(),
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'sizeBytes': sizeBytes,
      'contents': contents.map((e) => e.toJson()).toList(),
      'backupFilePath': backupFilePath,
      'errorMessage': errorMessage,
      'durationMs': durationMs,
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  /// 复制并更新
  BackupRecord copyWith({
    String? id,
    DateTime? backupTime,
    BackupType? type,
    BackupStatus? status,
    int? sizeBytes,
    List<BackupContent>? contents,
    String? backupFilePath,
    String? errorMessage,
    int? durationMs,
    String? deviceInfo,
    String? appVersion,
  }) {
    return BackupRecord(
      id: id ?? this.id,
      backupTime: backupTime ?? this.backupTime,
      type: type ?? this.type,
      status: status ?? this.status,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      contents: contents ?? this.contents,
      backupFilePath: backupFilePath ?? this.backupFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
      durationMs: durationMs ?? this.durationMs,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  /// 获取备份大小（MB）
  double get sizeMB => sizeBytes / (1024 * 1024);

  /// 获取备份大小（格式化字符串）
  String get sizeFormatted {
    if (sizeBytes < 1024) {
      return '${sizeBytes}B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取备份耗时（格式化字符串）
  String get durationFormatted {
    if (durationMs == null) return '未知';
    if (durationMs! < 1000) {
      return '${durationMs}ms';
    } else {
      return '${(durationMs! / 1000).toStringAsFixed(1)}s';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupRecord &&
        other.id == id &&
        other.backupTime == backupTime &&
        other.type == type &&
        other.status == status &&
        other.sizeBytes == sizeBytes &&
        listEquals(other.contents, contents) &&
        other.backupFilePath == backupFilePath &&
        other.errorMessage == errorMessage &&
        other.durationMs == durationMs &&
        other.deviceInfo == deviceInfo &&
        other.appVersion == appVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      backupTime,
      type,
      status,
      sizeBytes,
      Object.hashAll(contents),
      backupFilePath,
      errorMessage,
      durationMs,
      deviceInfo,
      appVersion,
    );
  }

  @override
  String toString() {
    return 'BackupRecord(id: $id, backupTime: $backupTime, type: $type, status: $status, sizeBytes: $sizeBytes, contents: $contents, backupFilePath: $backupFilePath, errorMessage: $errorMessage, durationMs: $durationMs, deviceInfo: $deviceInfo, appVersion: $appVersion)';
  }
}

/// 备份类型
enum BackupType {
  /// 自动备份
  automatic,

  /// 手动备份
  manual,
}

/// 备份状态
enum BackupStatus {
  /// 进行中
  inProgress,

  /// 成功
  success,

  /// 失败
  failed,

  /// 取消
  cancelled,
}

/// 备份内容
class BackupContent {
  /// 内容类型
  final String type;

  /// 内容名称
  final String name;

  /// 内容大小（字节）
  final int sizeBytes;

  /// 是否成功备份
  final bool success;

  /// 错误信息
  final String? errorMessage;

  const BackupContent({
    required this.type,
    required this.name,
    required this.sizeBytes,
    required this.success,
    this.errorMessage,
  });

  /// 从JSON创建实例
  factory BackupContent.fromJson(Map<String, dynamic> json) {
    return BackupContent(
      type: json['type'],
      name: json['name'],
      sizeBytes: json['sizeBytes'] ?? 0,
      success: json['success'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'sizeBytes': sizeBytes,
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  /// 获取大小（格式化字符串）
  String get sizeFormatted {
    if (sizeBytes < 1024) {
      return '${sizeBytes}B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupContent &&
        other.type == type &&
        other.name == name &&
        other.sizeBytes == sizeBytes &&
        other.success == success &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(type, name, sizeBytes, success, errorMessage);
  }

  @override
  String toString() {
    return 'BackupContent(type: $type, name: $name, sizeBytes: $sizeBytes, success: $success, errorMessage: $errorMessage)';
  }
}
