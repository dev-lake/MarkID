import 'package:flutter_test/flutter_test.dart';
import 'package:idseal/models/security_config.dart';

void main() {
  group('SecurityConfig', () {
    test('应该正确创建SecurityConfig实例', () {
      final config = SecurityConfig(
        isAuthEnabled: true,
        authMethod: AuthMethod.pinOrBiometric,
        supportedBiometrics: [BiometricType.fingerprint, BiometricType.face],
        currentBiometric: BiometricType.fingerprint,
        pinHash: 'hashed_pin_123',
        autoLockEnabled: true,
        autoLockTimeout: 10,
        appLockEnabled: true,
        exportVerificationEnabled: true,
        operationLogEnabled: true,
        encryptionAlgorithm: 'AES-256-GCM',
        keyDerivationFunction: 'PBKDF2',
        keyIterations: 150000,
      );

      expect(config.isAuthEnabled, isTrue);
      expect(config.authMethod, equals(AuthMethod.pinOrBiometric));
      expect(
        config.supportedBiometrics,
        equals([BiometricType.fingerprint, BiometricType.face]),
      );
      expect(config.currentBiometric, equals(BiometricType.fingerprint));
      expect(config.pinHash, equals('hashed_pin_123'));
      expect(config.autoLockEnabled, isTrue);
      expect(config.autoLockTimeout, equals(10));
      expect(config.appLockEnabled, isTrue);
      expect(config.exportVerificationEnabled, isTrue);
      expect(config.operationLogEnabled, isTrue);
      expect(config.encryptionAlgorithm, equals('AES-256-GCM'));
      expect(config.keyDerivationFunction, equals('PBKDF2'));
      expect(config.keyIterations, equals(150000));
      expect(config.id, equals('default'));
      expect(config.createdAt, isA<DateTime>());
      expect(config.updatedAt, isA<DateTime>());
    });

    test('应该使用默认值创建SecurityConfig实例', () {
      final config = SecurityConfig();

      expect(config.isAuthEnabled, isTrue);
      expect(config.authMethod, equals(AuthMethod.pinOrBiometric));
      expect(config.supportedBiometrics, isEmpty);
      expect(config.currentBiometric, isNull);
      expect(config.pinHash, isNull);
      expect(config.autoLockEnabled, isTrue);
      expect(config.autoLockTimeout, equals(5));
      expect(config.appLockEnabled, isTrue);
      expect(config.exportVerificationEnabled, isTrue);
      expect(config.operationLogEnabled, isTrue);
      expect(config.encryptionAlgorithm, equals('AES-256-GCM'));
      expect(config.keyDerivationFunction, equals('PBKDF2'));
      expect(config.keyIterations, equals(100000));
    });

    test('copyWith应该正确更新字段', () {
      final original = SecurityConfig(
        isAuthEnabled: true,
        authMethod: AuthMethod.pinOnly,
        autoLockTimeout: 5,
      );

      final updated = original.copyWith(
        authMethod: AuthMethod.biometricOnly,
        supportedBiometrics: [BiometricType.face],
        currentBiometric: BiometricType.face,
        pinHash: 'new_hash',
        autoLockTimeout: 15,
        exportVerificationEnabled: false,
        keyIterations: 200000,
      );

      expect(updated.id, equals(original.id));
      expect(updated.isAuthEnabled, equals(original.isAuthEnabled));
      expect(updated.appLockEnabled, equals(original.appLockEnabled));
      expect(updated.operationLogEnabled, equals(original.operationLogEnabled));
      expect(updated.encryptionAlgorithm, equals(original.encryptionAlgorithm));
      expect(
        updated.keyDerivationFunction,
        equals(original.keyDerivationFunction),
      );
      expect(updated.authMethod, equals(AuthMethod.biometricOnly));
      expect(updated.supportedBiometrics, equals([BiometricType.face]));
      expect(updated.currentBiometric, equals(BiometricType.face));
      expect(updated.pinHash, equals('new_hash'));
      expect(updated.autoLockTimeout, equals(15));
      expect(updated.exportVerificationEnabled, isFalse);
      expect(updated.keyIterations, equals(200000));
    });

    test('toMap应该正确序列化数据', () {
      final config = SecurityConfig(
        id: 'custom-config',
        isAuthEnabled: true,
        authMethod: AuthMethod.pinAndBiometric,
        supportedBiometrics: [
          BiometricType.fingerprint,
          BiometricType.face,
          BiometricType.iris,
        ],
        currentBiometric: BiometricType.face,
        pinHash: 'custom_hash',
        autoLockEnabled: false,
        autoLockTimeout: 20,
        appLockEnabled: false,
        exportVerificationEnabled: false,
        operationLogEnabled: false,
        encryptionAlgorithm: 'ChaCha20-Poly1305',
        keyDerivationFunction: 'Argon2',
        keyIterations: 300000,
      );

      final map = config.toMap();

      expect(map['id'], equals('custom-config'));
      expect(map['isAuthEnabled'], equals(1));
      expect(map['authMethod'], equals(AuthMethod.pinAndBiometric.index));
      expect(map['supportedBiometrics'], equals('0,1,2'));
      expect(map['currentBiometric'], equals(BiometricType.face.index));
      expect(map['pinHash'], equals('custom_hash'));
      expect(map['autoLockEnabled'], equals(0));
      expect(map['autoLockTimeout'], equals(20));
      expect(map['appLockEnabled'], equals(0));
      expect(map['exportVerificationEnabled'], equals(0));
      expect(map['operationLogEnabled'], equals(0));
      expect(map['encryptionAlgorithm'], equals('ChaCha20-Poly1305'));
      expect(map['keyDerivationFunction'], equals('Argon2'));
      expect(map['keyIterations'], equals(300000));
      expect(map['createdAt'], isA<int>());
      expect(map['updatedAt'], isA<int>());
    });

    test('fromMap应该正确反序列化数据', () {
      final map = {
        'id': 'test-config-123',
        'isAuthEnabled': 1,
        'authMethod': AuthMethod.pinOrBiometric.index,
        'supportedBiometrics': '0,1',
        'currentBiometric': BiometricType.fingerprint.index,
        'pinHash': 'test_hash',
        'autoLockEnabled': 1,
        'autoLockTimeout': 8,
        'appLockEnabled': 1,
        'exportVerificationEnabled': 1,
        'operationLogEnabled': 1,
        'encryptionAlgorithm': 'AES-256-GCM',
        'keyDerivationFunction': 'PBKDF2',
        'keyIterations': 120000,
        'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
        'updatedAt': 1640995200000,
      };

      final config = SecurityConfig.fromMap(map);

      expect(config.id, equals('test-config-123'));
      expect(config.isAuthEnabled, isTrue);
      expect(config.authMethod, equals(AuthMethod.pinOrBiometric));
      expect(
        config.supportedBiometrics,
        equals([BiometricType.fingerprint, BiometricType.face]),
      );
      expect(config.currentBiometric, equals(BiometricType.fingerprint));
      expect(config.pinHash, equals('test_hash'));
      expect(config.autoLockEnabled, isTrue);
      expect(config.autoLockTimeout, equals(8));
      expect(config.appLockEnabled, isTrue);
      expect(config.exportVerificationEnabled, isTrue);
      expect(config.operationLogEnabled, isTrue);
      expect(config.encryptionAlgorithm, equals('AES-256-GCM'));
      expect(config.keyDerivationFunction, equals('PBKDF2'));
      expect(config.keyIterations, equals(120000));
      expect(
        config.createdAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
      expect(
        config.updatedAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
    });

    test('fromMap应该处理默认值', () {
      final map = {
        'id': 'test-config-456',
        'isAuthEnabled': 1,
        'authMethod': AuthMethod.pinOnly.index,
        'supportedBiometrics': '',
        'currentBiometric': null,
        'pinHash': null,
        'autoLockEnabled': 1,
        'appLockEnabled': 1,
        'exportVerificationEnabled': 1,
        'operationLogEnabled': 1,
        'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
        'updatedAt': 1640995200000,
      };

      final config = SecurityConfig.fromMap(map);

      expect(config.supportedBiometrics, isEmpty);
      expect(config.currentBiometric, isNull);
      expect(config.pinHash, isNull);
      expect(config.autoLockTimeout, equals(5));
      expect(config.encryptionAlgorithm, equals('AES-256-GCM'));
      expect(config.keyDerivationFunction, equals('PBKDF2'));
      expect(config.keyIterations, equals(100000));
    });

    test('defaultConfig应该创建正确的默认配置', () {
      final config = SecurityConfig.defaultConfig();

      expect(config.id, equals('default'));
      expect(config.isAuthEnabled, isTrue);
      expect(config.authMethod, equals(AuthMethod.pinOrBiometric));
      expect(
        config.supportedBiometrics,
        equals([BiometricType.fingerprint, BiometricType.face]),
      );
      expect(config.currentBiometric, isNull);
      expect(config.pinHash, isNull);
      expect(config.autoLockEnabled, isTrue);
      expect(config.autoLockTimeout, equals(5));
      expect(config.appLockEnabled, isTrue);
      expect(config.exportVerificationEnabled, isTrue);
      expect(config.operationLogEnabled, isTrue);
    });

    test('requiresPin应该正确判断是否需要PIN码', () {
      final pinOnly = SecurityConfig(authMethod: AuthMethod.pinOnly);
      final biometricOnly = SecurityConfig(
        authMethod: AuthMethod.biometricOnly,
      );
      final pinOrBiometric = SecurityConfig(
        authMethod: AuthMethod.pinOrBiometric,
      );
      final pinAndBiometric = SecurityConfig(
        authMethod: AuthMethod.pinAndBiometric,
      );
      final disabled = SecurityConfig(
        isAuthEnabled: false,
        authMethod: AuthMethod.pinOnly,
      );

      expect(pinOnly.requiresPin, isTrue);
      expect(biometricOnly.requiresPin, isFalse);
      expect(pinOrBiometric.requiresPin, isTrue);
      expect(pinAndBiometric.requiresPin, isTrue);
      expect(disabled.requiresPin, isFalse);
    });

    test('requiresBiometric应该正确判断是否需要生物识别', () {
      final pinOnly = SecurityConfig(authMethod: AuthMethod.pinOnly);
      final biometricOnly = SecurityConfig(
        authMethod: AuthMethod.biometricOnly,
      );
      final pinOrBiometric = SecurityConfig(
        authMethod: AuthMethod.pinOrBiometric,
      );
      final pinAndBiometric = SecurityConfig(
        authMethod: AuthMethod.pinAndBiometric,
      );
      final disabled = SecurityConfig(
        isAuthEnabled: false,
        authMethod: AuthMethod.biometricOnly,
      );

      expect(pinOnly.requiresBiometric, isFalse);
      expect(biometricOnly.requiresBiometric, isTrue);
      expect(pinOrBiometric.requiresBiometric, isTrue);
      expect(pinAndBiometric.requiresBiometric, isTrue);
      expect(disabled.requiresBiometric, isFalse);
    });

    test('authMethodText应该返回正确的中文描述', () {
      final pinOnly = SecurityConfig(authMethod: AuthMethod.pinOnly);
      final biometricOnly = SecurityConfig(
        authMethod: AuthMethod.biometricOnly,
      );
      final pinOrBiometric = SecurityConfig(
        authMethod: AuthMethod.pinOrBiometric,
      );
      final pinAndBiometric = SecurityConfig(
        authMethod: AuthMethod.pinAndBiometric,
      );

      expect(pinOnly.authMethodText, equals('仅PIN码'));
      expect(biometricOnly.authMethodText, equals('仅生物识别'));
      expect(pinOrBiometric.authMethodText, equals('PIN码或生物识别'));
      expect(pinAndBiometric.authMethodText, equals('PIN码和生物识别'));
    });

    test('getBiometricTypeText应该返回正确的中文描述', () {
      final config = SecurityConfig();

      expect(
        config.getBiometricTypeText(BiometricType.fingerprint),
        equals('指纹识别'),
      );
      expect(config.getBiometricTypeText(BiometricType.face), equals('人脸识别'));
      expect(config.getBiometricTypeText(BiometricType.iris), equals('虹膜识别'));
      expect(config.getBiometricTypeText(BiometricType.none), equals('无'));
    });

    test('相等性比较应该正确工作', () {
      final config1 = SecurityConfig(
        id: 'same-id',
        authMethod: AuthMethod.pinOnly,
      );
      final config2 = SecurityConfig(
        id: 'same-id',
        authMethod: AuthMethod.biometricOnly,
      );
      final config3 = SecurityConfig(
        id: 'different-id',
        authMethod: AuthMethod.pinOnly,
      );

      expect(config1, equals(config2)); // 相同ID
      expect(config1, isNot(equals(config3))); // 不同ID
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });

    test('toString应该返回有意义的字符串', () {
      final config = SecurityConfig(
        id: 'test-config',
        isAuthEnabled: true,
        authMethod: AuthMethod.pinOrBiometric,
      );

      final str = config.toString();
      expect(str, contains('SecurityConfig'));
      expect(str, contains('test-config'));
      expect(str, contains('true')); // isAuthEnabled
      expect(str, contains('pinOrBiometric'));
    });

    test('BiometricType枚举应该正确工作', () {
      expect(BiometricType.fingerprint.index, equals(0));
      expect(BiometricType.face.index, equals(1));
      expect(BiometricType.iris.index, equals(2));
      expect(BiometricType.none.index, equals(3));
      expect(BiometricType.values.length, equals(4));
    });

    test('AuthMethod枚举应该正确工作', () {
      expect(AuthMethod.pinOnly.index, equals(0));
      expect(AuthMethod.biometricOnly.index, equals(1));
      expect(AuthMethod.pinOrBiometric.index, equals(2));
      expect(AuthMethod.pinAndBiometric.index, equals(3));
      expect(AuthMethod.values.length, equals(4));
    });
  });
}
