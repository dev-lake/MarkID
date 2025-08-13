import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'document_photo.dart';

/// 证件数据模型
class IdDocument {
  /// 唯一标识符
  final String id;

  /// 证件类型（身份证、护照、驾驶证等）
  final String documentType;

  /// 证件号码
  final String? documentNumber;

  /// 持有人姓名
  final String? holderName;

  /// 照片列表
  final List<DocumentPhoto> photos;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  /// 标签列表
  final List<String> tags;

  /// 备注信息
  final String? notes;

  /// 是否已删除（软删除）
  final bool isDeleted;

  IdDocument({
    String? id,
    required this.documentType,
    this.documentNumber,
    this.holderName,
    List<DocumentPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.notes,
    this.isDeleted = false,
  }) : id = id ?? const Uuid().v4(),
       photos = photos ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       tags = tags ?? [];

  /// 创建副本并更新指定字段
  IdDocument copyWith({
    String? id,
    String? documentType,
    String? documentNumber,
    String? holderName,
    List<DocumentPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    String? notes,
    bool? isDeleted,
  }) {
    return IdDocument(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      holderName: holderName ?? this.holderName,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'holderName': holderName,
      'photos': jsonEncode(photos.map((photo) => photo.toMap()).toList()),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'tags': tags.join(','),
      'notes': notes,
      'isDeleted': isDeleted ? 1 : 0,
    };
  }

  /// 从Map创建实例（用于数据库读取）
  factory IdDocument.fromMap(Map<String, dynamic> map) {
    List<DocumentPhoto> photos = [];
    if (map['photos'] != null) {
      try {
        if (map['photos'] is String) {
          // 新格式：JSON字符串
          final photosJson =
              jsonDecode(map['photos'] as String) as List<dynamic>;
          photos = photosJson
              .map(
                (photoMap) =>
                    DocumentPhoto.fromMap(Map<String, dynamic>.from(photoMap)),
              )
              .toList();
        } else if (map['photos'] is List) {
          // 旧格式：直接列表（兼容性）
          photos = (map['photos'] as List<dynamic>)
              .map(
                (photoMap) =>
                    DocumentPhoto.fromMap(Map<String, dynamic>.from(photoMap)),
              )
              .toList();
        }
      } catch (e) {
        print('解析照片数据失败: $e');
        photos = [];
      }
    }

    return IdDocument(
      id: map['id'],
      documentType: map['documentType'],
      documentNumber: map['documentNumber'],
      holderName: map['holderName'],
      photos: photos,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      tags: map['tags']?.split(',') ?? [],
      notes: map['notes'],
      isDeleted: map['isDeleted'] == 1,
    );
  }

  /// 转换为JSON（用于备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'holderName': holderName,
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'notes': notes,
      'isDeleted': isDeleted,
    };
  }

  /// 从JSON创建实例（用于备份恢复）
  factory IdDocument.fromJson(Map<String, dynamic> json) {
    return IdDocument(
      id: json['id'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      holderName: json['holderName'],
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map(
                (photoJson) => DocumentPhoto.fromJson(
                  Map<String, dynamic>.from(photoJson),
                ),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['notes'],
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  @override
  String toString() {
    return 'IdDocument(id: $id, documentType: $documentType, holderName: $holderName, photoCount: ${photos.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IdDocument && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// 获取主照片（用于缩略图显示）
  DocumentPhoto? get primaryPhoto {
    return photos.where((photo) => photo.isPrimary).firstOrNull ??
        photos.firstOrNull;
  }

  /// 获取所有照片的总大小
  int get totalFileSize {
    return photos.fold(0, (sum, photo) => sum + photo.fileSize);
  }

  /// 获取文件大小的人类可读格式
  String get fileSizeFormatted {
    final totalSize = totalFileSize;
    if (totalSize < 1024) {
      return '${totalSize}B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 获取排序后的照片列表
  List<DocumentPhoto> get sortedPhotos {
    final sorted = List<DocumentPhoto>.from(photos);
    sorted.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    return sorted;
  }
}
