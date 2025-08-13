import 'package:flutter_test/flutter_test.dart';
import 'package:idseal/services/icloud_sync_service.dart';
import 'package:idseal/services/document_service.dart';

void main() {
  group('ICloudSyncService Tests', () {
    late ICloudSyncService syncService;
    late DocumentService documentService;

    setUp(() {
      documentService = DocumentService();
      syncService = ICloudSyncService(documentService);
    });

    test('should create sync service', () {
      expect(syncService, isNotNull);
    });

    test('should get sync status', () async {
      final status = await syncService.getSyncStatus();
      // 初始状态可能为 null
      expect(status, isA<Map<String, dynamic>?>());
    });

    test('should check cloud updates', () async {
      final hasUpdates = await syncService.hasCloudUpdates();
      expect(hasUpdates, isA<bool>());
    });

    test('should clear sync data', () async {
      // 这个测试不会抛出异常
      await syncService.clearSyncData();
      expect(true, isTrue); // 如果执行到这里说明没有异常
    });
  });
}
