/// 导出状态枚举
enum ExportStatus {
  /// 导出中
  exporting,

  /// 导出成功
  success,

  /// 导出失败
  failed,

  /// 已取消
  cancelled,
}

/// 导出记录数据模型
class ExportRecord {
  /// 唯一标识符
  final String id;

  /// 关联的证件照片ID
  final String documentId;

  /// 导出文件路径
  final String exportPath;

  /// 导出文件名
  final String fileName;

  /// 导出状态
  final ExportStatus status;

  /// 导出时间
  final DateTime exportTime;

  /// 文件大小（字节）
  final int fileSize;

  /// 应用的水印配置ID列表
  final List<String> appliedWatermarkIds;

  /// 水印内容详情（JSON格式）
  final String watermarkDetails;

  /// 导出设备信息
  final String deviceInfo;

  /// 导出用途
  final String? purpose;

  /// 导出备注
  final String? notes;

  /// 错误信息（如果导出失败）
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  ExportRecord({
    String? id,
    required this.documentId,
    required this.exportPath,
    required this.fileName,
    this.status = ExportStatus.exporting,
    DateTime? exportTime,
    required this.fileSize,
    List<String>? appliedWatermarkIds,
    required this.watermarkDetails,
    required this.deviceInfo,
    this.purpose,
    this.notes,
    this.errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       exportTime = exportTime ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       appliedWatermarkIds = appliedWatermarkIds ?? [];

  /// 创建副本并更新指定字段
  ExportRecord copyWith({
    String? id,
    String? documentId,
    String? exportPath,
    String? fileName,
    ExportStatus? status,
    DateTime? exportTime,
    int? fileSize,
    List<String>? appliedWatermarkIds,
    String? watermarkDetails,
    String? deviceInfo,
    String? purpose,
    String? notes,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExportRecord(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      exportPath: exportPath ?? this.exportPath,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      exportTime: exportTime ?? this.exportTime,
      fileSize: fileSize ?? this.fileSize,
      appliedWatermarkIds: appliedWatermarkIds ?? this.appliedWatermarkIds,
      watermarkDetails: watermarkDetails ?? this.watermarkDetails,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentId': documentId,
      'exportPath': exportPath,
      'fileName': fileName,
      'status': status.index,
      'exportTime': exportTime.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'appliedWatermarkIds': appliedWatermarkIds.join(','),
      'watermarkDetails': watermarkDetails,
      'deviceInfo': deviceInfo,
      'purpose': purpose,
      'notes': notes,
      'errorMessage': errorMessage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 从Map创建实例（用于数据库读取）
  factory ExportRecord.fromMap(Map<String, dynamic> map) {
    return ExportRecord(
      id: map['id'],
      documentId: map['documentId'],
      exportPath: map['exportPath'],
      fileName: map['fileName'],
      status: ExportStatus.values[map['status']],
      exportTime: DateTime.fromMillisecondsSinceEpoch(map['exportTime']),
      fileSize: map['fileSize'],
      appliedWatermarkIds: map['appliedWatermarkIds']?.isNotEmpty == true
          ? map['appliedWatermarkIds'].split(',')
          : [],
      watermarkDetails: map['watermarkDetails'],
      deviceInfo: map['deviceInfo'],
      purpose: map['purpose'],
      notes: map['notes'],
      errorMessage: map['errorMessage'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  /// 转换为JSON（用于备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentId': documentId,
      'exportPath': exportPath,
      'fileName': fileName,
      'status': status.index,
      'exportTime': exportTime.toIso8601String(),
      'fileSize': fileSize,
      'appliedWatermarkIds': appliedWatermarkIds,
      'watermarkDetails': watermarkDetails,
      'deviceInfo': deviceInfo,
      'purpose': purpose,
      'notes': notes,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从JSON创建实例（用于备份恢复）
  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'],
      documentId: json['documentId'],
      exportPath: json['exportPath'],
      fileName: json['fileName'],
      status: ExportStatus.values[json['status']],
      exportTime: DateTime.parse(json['exportTime']),
      fileSize: json['fileSize'],
      appliedWatermarkIds: List<String>.from(json['appliedWatermarkIds'] ?? []),
      watermarkDetails: json['watermarkDetails'],
      deviceInfo: json['deviceInfo'],
      purpose: json['purpose'],
      notes: json['notes'],
      errorMessage: json['errorMessage'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

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

  @override
  String toString() {
    return 'ExportRecord(id: $id, documentId: $documentId, fileName: $fileName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExportRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
