/// 生物识别类型枚举
enum BiometricType {
  /// 指纹识别
  fingerprint,

  /// 人脸识别
  face,

  /// 虹膜识别
  iris,

  /// 无生物识别
  none,
}

/// 认证方式枚举
enum AuthMethod {
  /// 仅PIN码
  pinOnly,

  /// 仅生物识别
  biometricOnly,

  /// PIN码或生物识别
  pinOrBiometric,

  /// PIN码和生物识别都需要
  pinAndBiometric,
}

/// 安全配置数据模型
class SecurityConfig {
  /// 唯一标识符
  final String id;

  /// 是否启用安全认证
  final bool isAuthEnabled;

  /// 认证方式
  final AuthMethod authMethod;

  /// 支持的生物识别类型列表
  final List<BiometricType> supportedBiometrics;

  /// 当前使用的生物识别类型
  final BiometricType? currentBiometric;

  /// PIN码哈希（加密存储）
  final String? pinHash;

  /// 是否启用自动锁定
  final bool autoLockEnabled;

  /// 自动锁定时间（分钟）
  final int autoLockTimeout;

  /// 是否启用应用锁定
  final bool appLockEnabled;

  /// 是否启用导出验证
  final bool exportVerificationEnabled;

  /// 是否启用操作日志
  final bool operationLogEnabled;

  /// 加密算法
  final String encryptionAlgorithm;

  /// 密钥派生函数
  final String keyDerivationFunction;

  /// 密钥迭代次数
  final int keyIterations;

  /// 创建时间
  final DateTime createdAt;

  /// 最后修改时间
  final DateTime updatedAt;

  SecurityConfig({
    String? id,
    this.isAuthEnabled = true,
    this.authMethod = AuthMethod.pinOrBiometric,
    List<BiometricType>? supportedBiometrics,
    this.currentBiometric,
    this.pinHash,
    this.autoLockEnabled = true,
    this.autoLockTimeout = 5,
    this.appLockEnabled = true,
    this.exportVerificationEnabled = true,
    this.operationLogEnabled = true,
    this.encryptionAlgorithm = 'AES-256-GCM',
    this.keyDerivationFunction = 'PBKDF2',
    this.keyIterations = 100000,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? 'default',
       supportedBiometrics = supportedBiometrics ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 创建副本并更新指定字段
  SecurityConfig copyWith({
    String? id,
    bool? isAuthEnabled,
    AuthMethod? authMethod,
    List<BiometricType>? supportedBiometrics,
    BiometricType? currentBiometric,
    String? pinHash,
    bool? autoLockEnabled,
    int? autoLockTimeout,
    bool? appLockEnabled,
    bool? exportVerificationEnabled,
    bool? operationLogEnabled,
    String? encryptionAlgorithm,
    String? keyDerivationFunction,
    int? keyIterations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecurityConfig(
      id: id ?? this.id,
      isAuthEnabled: isAuthEnabled ?? this.isAuthEnabled,
      authMethod: authMethod ?? this.authMethod,
      supportedBiometrics: supportedBiometrics ?? this.supportedBiometrics,
      currentBiometric: currentBiometric ?? this.currentBiometric,
      pinHash: pinHash ?? this.pinHash,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      exportVerificationEnabled:
          exportVerificationEnabled ?? this.exportVerificationEnabled,
      operationLogEnabled: operationLogEnabled ?? this.operationLogEnabled,
      encryptionAlgorithm: encryptionAlgorithm ?? this.encryptionAlgorithm,
      keyDerivationFunction:
          keyDerivationFunction ?? this.keyDerivationFunction,
      keyIterations: keyIterations ?? this.keyIterations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 转换为Map（用于数据库存储）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isAuthEnabled': isAuthEnabled ? 1 : 0,
      'authMethod': authMethod.index,
      'supportedBiometrics': supportedBiometrics.map((e) => e.index).join(','),
      'currentBiometric': currentBiometric?.index,
      'pinHash': pinHash,
      'autoLockEnabled': autoLockEnabled ? 1 : 0,
      'autoLockTimeout': autoLockTimeout,
      'appLockEnabled': appLockEnabled ? 1 : 0,
      'exportVerificationEnabled': exportVerificationEnabled ? 1 : 0,
      'operationLogEnabled': operationLogEnabled ? 1 : 0,
      'encryptionAlgorithm': encryptionAlgorithm,
      'keyDerivationFunction': keyDerivationFunction,
      'keyIterations': keyIterations,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 从Map创建实例（用于数据库读取）
  factory SecurityConfig.fromMap(Map<String, dynamic> map) {
    return SecurityConfig(
      id: map['id'],
      isAuthEnabled: map['isAuthEnabled'] == 1,
      authMethod: AuthMethod.values[map['authMethod']],
      supportedBiometrics:
          (map['supportedBiometrics'] as String?)?.isNotEmpty == true
          ? (map['supportedBiometrics'] as String)
                .split(',')
                .map((e) => BiometricType.values[int.parse(e)])
                .toList()
          : [],
      currentBiometric: map['currentBiometric'] != null
          ? BiometricType.values[map['currentBiometric']]
          : null,
      pinHash: map['pinHash'],
      autoLockEnabled: map['autoLockEnabled'] == 1,
      autoLockTimeout: map['autoLockTimeout'] ?? 5,
      appLockEnabled: map['appLockEnabled'] == 1,
      exportVerificationEnabled: map['exportVerificationEnabled'] == 1,
      operationLogEnabled: map['operationLogEnabled'] == 1,
      encryptionAlgorithm: map['encryptionAlgorithm'] ?? 'AES-256-GCM',
      keyDerivationFunction: map['keyDerivationFunction'] ?? 'PBKDF2',
      keyIterations: map['keyIterations'] ?? 100000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  /// 创建默认安全配置
  factory SecurityConfig.defaultConfig() {
    return SecurityConfig(
      id: 'default',
      isAuthEnabled: true,
      authMethod: AuthMethod.pinOrBiometric,
      supportedBiometrics: [BiometricType.fingerprint, BiometricType.face],
      autoLockEnabled: true,
      autoLockTimeout: 5,
      appLockEnabled: true,
      exportVerificationEnabled: true,
      operationLogEnabled: true,
    );
  }

  /// 转换为JSON（用于备份）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isAuthEnabled': isAuthEnabled,
      'authMethod': authMethod.index,
      'supportedBiometrics': supportedBiometrics.map((e) => e.index).toList(),
      'currentBiometric': currentBiometric?.index,
      'pinHash': pinHash,
      'autoLockEnabled': autoLockEnabled,
      'autoLockTimeout': autoLockTimeout,
      'appLockEnabled': appLockEnabled,
      'exportVerificationEnabled': exportVerificationEnabled,
      'operationLogEnabled': operationLogEnabled,
      'encryptionAlgorithm': encryptionAlgorithm,
      'keyDerivationFunction': keyDerivationFunction,
      'keyIterations': keyIterations,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 从JSON创建实例（用于备份恢复）
  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      id: json['id'],
      isAuthEnabled: json['isAuthEnabled'] ?? true,
      authMethod: AuthMethod.values[json['authMethod'] ?? 0],
      supportedBiometrics:
          (json['supportedBiometrics'] as List<dynamic>?)
              ?.map((e) => BiometricType.values[e])
              .toList() ??
          [],
      currentBiometric: json['currentBiometric'] != null
          ? BiometricType.values[json['currentBiometric']]
          : null,
      pinHash: json['pinHash'],
      autoLockEnabled: json['autoLockEnabled'] ?? true,
      autoLockTimeout: json['autoLockTimeout'] ?? 5,
      appLockEnabled: json['appLockEnabled'] ?? true,
      exportVerificationEnabled: json['exportVerificationEnabled'] ?? true,
      operationLogEnabled: json['operationLogEnabled'] ?? true,
      encryptionAlgorithm: json['encryptionAlgorithm'] ?? 'AES-256-GCM',
      keyDerivationFunction: json['keyDerivationFunction'] ?? 'PBKDF2',
      keyIterations: json['keyIterations'] ?? 100000,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 检查是否需要PIN码认证
  bool get requiresPin {
    return isAuthEnabled &&
        (authMethod == AuthMethod.pinOnly ||
            authMethod == AuthMethod.pinOrBiometric ||
            authMethod == AuthMethod.pinAndBiometric);
  }

  /// 检查是否需要生物识别认证
  bool get requiresBiometric {
    return isAuthEnabled &&
        (authMethod == AuthMethod.biometricOnly ||
            authMethod == AuthMethod.pinOrBiometric ||
            authMethod == AuthMethod.pinAndBiometric);
  }

  /// 获取认证方式的中文描述
  String get authMethodText {
    switch (authMethod) {
      case AuthMethod.pinOnly:
        return '仅PIN码';
      case AuthMethod.biometricOnly:
        return '仅生物识别';
      case AuthMethod.pinOrBiometric:
        return 'PIN码或生物识别';
      case AuthMethod.pinAndBiometric:
        return 'PIN码和生物识别';
    }
  }

  /// 获取生物识别类型的中文描述
  String getBiometricTypeText(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return '指纹识别';
      case BiometricType.face:
        return '人脸识别';
      case BiometricType.iris:
        return '虹膜识别';
      case BiometricType.none:
        return '无';
    }
  }

  @override
  String toString() {
    return 'SecurityConfig(id: $id, isAuthEnabled: $isAuthEnabled, authMethod: $authMethod)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
