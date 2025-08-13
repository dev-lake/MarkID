import 'package:uuid/uuid.dart';

/// 证件照片模型
class DocumentPhoto {
  /// 唯一标识符
  final String id;

  /// 照片类型（正面、反面、内页等）
  final String photoType;

  /// 照片描述
  final String? description;

  /// 原始照片路径（加密存储）
  final String originalImagePath;

  /// 缩略图路径
  final String? thumbnailPath;

  /// 照片拍摄时间
  final DateTime captureTime;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  /// 是否已加密
  final bool isEncrypted;

  /// 加密密钥哈希（用于验证）
  final String? encryptionKeyHash;

  /// 照片大小（字节）
  final int fileSize;

  /// 照片尺寸
  final int? width;
  final int? height;

  /// 排序索引（用于确定照片显示顺序）
  final int sortIndex;

  /// 是否为主照片（用于缩略图显示）
  final bool isPrimary;

  /// 是否已删除（软删除）
  final bool isDeleted;

  DocumentPhoto({
    String? id,
    required this.photoType,
    this.description,
    required this.originalImagePath,
    this.thumbnailPath,
    DateTime? captureTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isEncrypted = false,
    this.encryptionKeyHash,
    required this.fileSize,
    this.width,
    this.height,
    this.sortIndex = 0,
    this.isPrimary = false,
    this.isDeleted = false,
  }) : id = id ?? const Uuid().v4(),
       captureTime = captureTime ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 创建副本并更新指定字段
  DocumentPhoto copyWith({
    String? id,
    String? photoType,
    String? description,
    String? originalImagePath,
    String? thumbnailPath,
    DateTime? captureTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEncrypted,
    String? encryptionKeyHash,
    int? fileSize,
    int? width,
    int? height,
    int? sortIndex,
    bool? isPrimary,
    bool? isDeleted,
  }) {
    return DocumentPhoto(
      id: id ?? this.id,
      photoType: photoType ?? this.photoType,
      description: description ?? this.description,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      captureTime: captureTime ?? this.captureTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKeyHash: encryptionKeyHash ?? this.encryptionKeyHash,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      sortIndex: sortIndex ?? this.sortIndex,
      isPrimary: isPrimary ?? this.isPrimary,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoType': photoType,
      'description': description,
      'originalImagePath': originalImagePath,
      'thumbnailPath': thumbnailPath,
      'captureTime': captureTime.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isEncrypted': isEncrypted ? 1 : 0,
      'encryptionKeyHash': encryptionKeyHash,
      'fileSize': fileSize,
      'width': width,
      'height': height,
      'sortIndex': sortIndex,
      'isPrimary': isPrimary ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  /// 从Map创建实例（用于数据库读取）
  factory DocumentPhoto.fromMap(Map<String, dynamic> map) {
    return DocumentPhoto(
      id: map['id'],
      photoType: map['photoType'],
      description: map['description'],
      originalImagePath: map['originalImagePath'],
      thumbnailPath: map['thumbnailPath'],
      captureTime: DateTime.fromMillisecondsSinceEpoch(map['captureTime']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isEncrypted: map['isEncrypted'] == 1,
      encryptionKeyHash: map['encryptionKeyHash'],
      fileSize: map['fileSize'],
      width: map['width'],
      height: map['height'],
      sortIndex: map['sortIndex'] ?? 0,
      isPrimary: map['isPrimary'] == 1,
      isDeleted: map['isDeleted'] == 1,
    );
  }

  /// 转换为JSON（用于备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'photoType': photoType,
      'description': description,
      'originalImagePath': originalImagePath,
      'thumbnailPath': thumbnailPath,
      'captureTime': captureTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEncrypted': isEncrypted,
      'encryptionKeyHash': encryptionKeyHash,
      'fileSize': fileSize,
      'width': width,
      'height': height,
      'sortIndex': sortIndex,
      'isPrimary': isPrimary,
      'isDeleted': isDeleted,
    };
  }

  /// 从JSON创建实例（用于备份恢复）
  factory DocumentPhoto.fromJson(Map<String, dynamic> json) {
    return DocumentPhoto(
      id: json['id'],
      photoType: json['photoType'],
      description: json['description'],
      originalImagePath: json['originalImagePath'],
      thumbnailPath: json['thumbnailPath'],
      captureTime: DateTime.parse(json['captureTime']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isEncrypted: json['isEncrypted'] ?? false,
      encryptionKeyHash: json['encryptionKeyHash'],
      fileSize: json['fileSize'],
      width: json['width'],
      height: json['height'],
      sortIndex: json['sortIndex'] ?? 0,
      isPrimary: json['isPrimary'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  @override
  String toString() {
    return 'DocumentPhoto(id: $id, photoType: $photoType, isEncrypted: $isEncrypted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentPhoto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// 获取文件大小的人类可读格式
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取照片类型的中文描述
  String get photoTypeDisplay {
    switch (photoType.toLowerCase()) {
      case 'front':
      case '正面':
        return '正面';
      case 'back':
      case '反面':
        return '反面';
      case 'inside':
      case '内页':
        return '内页';
      case 'page1':
      case '第一页':
        return '第一页';
      case 'page2':
      case '第二页':
        return '第二页';
      case 'page3':
      case '第三页':
        return '第三页';
      case 'other':
      case '其他':
        return '其他';
      default:
        return photoType;
    }
  }
}
