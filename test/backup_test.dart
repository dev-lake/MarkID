import 'package:flutter_test/flutter_test.dart';
import 'package:idseal/models/backup_config.dart';
import 'package:idseal/models/backup_record.dart';

void main() {
  group('BackupConfig Tests', () {
    test('should create default config', () {
      final config = const BackupConfig();

      expect(config.enabled, false);
      expect(config.frequencyHours, 24);
      expect(config.backupDocuments, true);
      expect(config.backupExportRecords, true);
      expect(config.backupSecurityConfig, true);
      expect(config.backupWatermarkConfig, true);
      expect(config.backupEncryptionKeys, false);
      expect(config.maxBackupSizeMB, 100);
      expect(config.backupOnlyOnWifi, true);
      expect(config.compressBackup, true);
    });

    test('should convert to and from JSON', () {
      final originalConfig = BackupConfig(
        enabled: true,
        frequencyHours: 12,
        backupDocuments: true,
        backupExportRecords: false,
        backupSecurityConfig: true,
        backupWatermarkConfig: false,
        backupEncryptionKeys: true,
        maxBackupSizeMB: 200,
        backupOnlyOnWifi: false,
        compressBackup: false,
      );

      final json = originalConfig.toJson();
      final restoredConfig = BackupConfig.fromJson(json);

      expect(restoredConfig.enabled, originalConfig.enabled);
      expect(restoredConfig.frequencyHours, originalConfig.frequencyHours);
      expect(restoredConfig.backupDocuments, originalConfig.backupDocuments);
      expect(
        restoredConfig.backupExportRecords,
        originalConfig.backupExportRecords,
      );
      expect(
        restoredConfig.backupSecurityConfig,
        originalConfig.backupSecurityConfig,
      );
      expect(
        restoredConfig.backupWatermarkConfig,
        originalConfig.backupWatermarkConfig,
      );
      expect(
        restoredConfig.backupEncryptionKeys,
        originalConfig.backupEncryptionKeys,
      );
      expect(restoredConfig.maxBackupSizeMB, originalConfig.maxBackupSizeMB);
      expect(restoredConfig.backupOnlyOnWifi, originalConfig.backupOnlyOnWifi);
      expect(restoredConfig.compressBackup, originalConfig.compressBackup);
    });

    test('should check if backup is needed', () {
      final config = BackupConfig(
        enabled: true,
        frequencyHours: 24,
        nextBackupTime: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(config.needsBackup, true);
    });

    test('should calculate next backup time', () {
      final config = const BackupConfig(frequencyHours: 12);
      final nextBackupTime = config.calculateNextBackupTime();
      final now = DateTime.now();

      expect(nextBackupTime.isAfter(now), true);
      expect(nextBackupTime.difference(now).inHours, greaterThanOrEqualTo(11));
      expect(nextBackupTime.difference(now).inHours, lessThanOrEqualTo(13));
    });
  });

  group('BackupRecord Tests', () {
    test('should create backup record', () {
      final record = BackupRecord(
        id: 'test-id',
        backupTime: DateTime.now(),
        type: BackupType.automatic,
        status: BackupStatus.success,
        sizeBytes: 1024,
        contents: [
          const BackupContent(
            type: 'documents',
            name: '证件数据',
            sizeBytes: 512,
            success: true,
          ),
        ],
        deviceInfo: 'Test Device',
        appVersion: '1.0.0',
      );

      expect(record.id, 'test-id');
      expect(record.type, BackupType.automatic);
      expect(record.status, BackupStatus.success);
      expect(record.sizeBytes, 1024);
      expect(record.contents.length, 1);
      expect(record.deviceInfo, 'Test Device');
      expect(record.appVersion, '1.0.0');
    });

    test('should format size correctly', () {
      final record1 = BackupRecord(
        id: 'test1',
        backupTime: DateTime.now(),
        type: BackupType.manual,
        status: BackupStatus.success,
        sizeBytes: 512,
        contents: [],
        deviceInfo: 'Test',
        appVersion: '1.0.0',
      );

      final record2 = BackupRecord(
        id: 'test2',
        backupTime: DateTime.now(),
        type: BackupType.manual,
        status: BackupStatus.success,
        sizeBytes: 1024 * 1024,
        contents: [],
        deviceInfo: 'Test',
        appVersion: '1.0.0',
      );

      expect(record1.sizeFormatted, '512B');
      expect(record2.sizeFormatted, '1.0MB');
    });

    test('should convert to and from JSON', () {
      final originalRecord = BackupRecord(
        id: 'test-id',
        backupTime: DateTime(2023, 1, 1, 12, 0, 0),
        type: BackupType.manual,
        status: BackupStatus.success,
        sizeBytes: 1024,
        contents: [
          const BackupContent(
            type: 'documents',
            name: '证件数据',
            sizeBytes: 512,
            success: true,
          ),
        ],
        deviceInfo: 'Test Device',
        appVersion: '1.0.0',
        durationMs: 5000,
      );

      final json = originalRecord.toJson();
      final restoredRecord = BackupRecord.fromJson(json);

      expect(restoredRecord.id, originalRecord.id);
      expect(restoredRecord.type, originalRecord.type);
      expect(restoredRecord.status, originalRecord.status);
      expect(restoredRecord.sizeBytes, originalRecord.sizeBytes);
      expect(restoredRecord.deviceInfo, originalRecord.deviceInfo);
      expect(restoredRecord.appVersion, originalRecord.appVersion);
      expect(restoredRecord.durationMs, originalRecord.durationMs);
    });
  });

  group('BackupContent Tests', () {
    test('should create backup content', () {
      final content = const BackupContent(
        type: 'documents',
        name: '证件数据',
        sizeBytes: 1024,
        success: true,
        errorMessage: null,
      );

      expect(content.type, 'documents');
      expect(content.name, '证件数据');
      expect(content.sizeBytes, 1024);
      expect(content.success, true);
      expect(content.errorMessage, null);
    });

    test('should format size correctly', () {
      final content1 = const BackupContent(
        type: 'test',
        name: 'Test',
        sizeBytes: 512,
        success: true,
      );

      final content2 = const BackupContent(
        type: 'test',
        name: 'Test',
        sizeBytes: 1024 * 1024,
        success: true,
      );

      expect(content1.sizeFormatted, '512B');
      expect(content2.sizeFormatted, '1.0MB');
    });
  });
}
