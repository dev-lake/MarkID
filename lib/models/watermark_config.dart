/// 水印类型枚举
enum WatermarkType {
  /// 显性水印（可见文字）
  visible,

  /// 暗水印（隐藏信息）
  invisible,
}

/// 水印位置枚举
enum WatermarkPosition {
  /// 左上角
  topLeft,

  /// 右上角
  topRight,

  /// 左下角
  bottomLeft,

  /// 右下角
  bottomRight,

  /// 中心
  center,

  /// 随机位置
  random,
}

/// 水印配置数据模型
class WatermarkConfig {
  /// 唯一标识符
  final String id;

  /// 水印名称
  final String name;

  /// 水印类型
  final WatermarkType type;

  /// 水印内容
  final String content;

  /// 水印位置
  final WatermarkPosition position;

  /// 字体大小
  final double fontSize;

  /// 字体颜色（显性水印）
  final int? color;

  /// 透明度（0.0-1.0）
  final double opacity;

  /// 旋转角度（度）
  final double rotation;

  /// 是否启用
  final bool isEnabled;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  /// 是否为默认配置
  final bool isDefault;

  WatermarkConfig({
    String? id,
    required this.name,
    required this.type,
    required this.content,
    this.position = WatermarkPosition.bottomRight,
    this.fontSize = 24.0,
    this.color,
    this.opacity = 0.7,
    this.rotation = 0.0,
    this.isEnabled = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDefault = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 创建副本并更新指定字段
  WatermarkConfig copyWith({
    String? id,
    String? name,
    WatermarkType? type,
    String? content,
    WatermarkPosition? position,
    double? fontSize,
    int? color,
    double? opacity,
    double? rotation,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
  }) {
    return WatermarkConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      content: content ?? this.content,
      position: position ?? this.position,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'content': content,
      'position': position.index,
      'fontSize': fontSize,
      'color': color,
      'opacity': opacity,
      'rotation': rotation,
      'isEnabled': isEnabled ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  /// 从Map创建实例（用于数据库读取）
  factory WatermarkConfig.fromMap(Map<String, dynamic> map) {
    return WatermarkConfig(
      id: map['id'],
      name: map['name'],
      type: WatermarkType.values[map['type']],
      content: map['content'],
      position: WatermarkPosition.values[map['position']],
      fontSize: map['fontSize']?.toDouble() ?? 24.0,
      color: map['color'],
      opacity: map['opacity']?.toDouble() ?? 0.7,
      rotation: map['rotation']?.toDouble() ?? 0.0,
      isEnabled: map['isEnabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isDefault: map['isDefault'] == 1,
    );
  }

  /// 创建默认的显性水印配置
  factory WatermarkConfig.defaultVisible() {
    return WatermarkConfig(
      name: '默认显性水印',
      type: WatermarkType.visible,
      content: '仅限内部使用',
      position: WatermarkPosition.bottomRight,
      fontSize: 20.0,
      color: 0xFF000000, // 黑色
      opacity: 0.8,
      rotation: -15.0,
      isDefault: true,
    );
  }

  /// 创建默认的暗水印配置
  factory WatermarkConfig.defaultInvisible() {
    return WatermarkConfig(
      name: '默认暗水印',
      type: WatermarkType.invisible,
      content: '{{timestamp}}', // 时间戳占位符
      position: WatermarkPosition.random,
      fontSize: 12.0,
      opacity: 0.1,
      isDefault: true,
    );
  }

  /// 转换为JSON（用于备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'content': content,
      'position': position.index,
      'fontSize': fontSize,
      'color': color,
      'opacity': opacity,
      'rotation': rotation,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  /// 从JSON创建实例（用于备份恢复）
  factory WatermarkConfig.fromJson(Map<String, dynamic> json) {
    return WatermarkConfig(
      id: json['id'],
      name: json['name'],
      type: WatermarkType.values[json['type']],
      content: json['content'],
      position: WatermarkPosition.values[json['position']],
      fontSize: json['fontSize']?.toDouble() ?? 24.0,
      color: json['color'],
      opacity: json['opacity']?.toDouble() ?? 0.7,
      rotation: json['rotation']?.toDouble() ?? 0.0,
      isEnabled: json['isEnabled'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
    );
  }

  @override
  String toString() {
    return 'WatermarkConfig(id: $id, name: $name, type: $type, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WatermarkConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
