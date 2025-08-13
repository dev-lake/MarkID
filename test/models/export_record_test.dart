import 'package:flutter_test/flutter_test.dart';
import 'package:idseal/models/export_record.dart';

void main() {
  group('ExportRecord', () {
    test('应该正确创建ExportRecord实例', () {
      final record = ExportRecord(
        documentId: 'doc-123',
        exportPath: '/path/to/export/image.jpg',
        fileName: '身份证_张三.jpg',
        status: ExportStatus.success,
        fileSize: 1024000,
        appliedWatermarkIds: ['wm-1', 'wm-2'],
        watermarkDetails: '{"visible": "仅限内部使用", "invisible": "2024-01-01"}',
        deviceInfo: 'iPhone 15 Pro',
        purpose: '内部审核',
        notes: '导出测试',
      );

      expect(record.documentId, equals('doc-123'));
      expect(record.exportPath, equals('/path/to/export/image.jpg'));
      expect(record.fileName, equals('身份证_张三.jpg'));
      expect(record.status, equals(ExportStatus.success));
      expect(record.fileSize, equals(1024000));
      expect(record.appliedWatermarkIds, equals(['wm-1', 'wm-2']));
      expect(
        record.watermarkDetails,
        equals('{"visible": "仅限内部使用", "invisible": "2024-01-01"}'),
      );
      expect(record.deviceInfo, equals('iPhone 15 Pro'));
      expect(record.purpose, equals('内部审核'));
      expect(record.notes, equals('导出测试'));
      expect(record.errorMessage, isNull);
      expect(record.id, isNotEmpty);
      expect(record.exportTime, isA<DateTime>());
      expect(record.createdAt, isA<DateTime>());
      expect(record.updatedAt, isA<DateTime>());
    });

    test('应该使用默认值创建ExportRecord实例', () {
      final record = ExportRecord(
        documentId: 'doc-456',
        exportPath: '/path/to/export/test.jpg',
        fileName: 'test.jpg',
        fileSize: 512000,
        watermarkDetails: '{}',
        deviceInfo: 'Android Device',
      );

      expect(record.documentId, equals('doc-456'));
      expect(record.exportPath, equals('/path/to/export/test.jpg'));
      expect(record.fileName, equals('test.jpg'));
      expect(record.status, equals(ExportStatus.exporting));
      expect(record.fileSize, equals(512000));
      expect(record.appliedWatermarkIds, isEmpty);
      expect(record.watermarkDetails, equals('{}'));
      expect(record.deviceInfo, equals('Android Device'));
      expect(record.purpose, isNull);
      expect(record.notes, isNull);
      expect(record.errorMessage, isNull);
    });

    test('copyWith应该正确更新字段', () {
      final original = ExportRecord(
        documentId: 'doc-789',
        exportPath: '/path/to/original.jpg',
        fileName: 'original.jpg',
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test Device',
      );

      final updated = original.copyWith(
        status: ExportStatus.success,
        appliedWatermarkIds: ['wm-1'],
        watermarkDetails: '{"visible": "测试水印"}',
        purpose: '测试用途',
        notes: '测试备注',
        errorMessage: null,
      );

      expect(updated.id, equals(original.id));
      expect(updated.documentId, equals(original.documentId));
      expect(updated.exportPath, equals(original.exportPath));
      expect(updated.fileName, equals(original.fileName));
      expect(updated.fileSize, equals(original.fileSize));
      expect(updated.deviceInfo, equals(original.deviceInfo));
      expect(updated.status, equals(ExportStatus.success));
      expect(updated.appliedWatermarkIds, equals(['wm-1']));
      expect(updated.watermarkDetails, equals('{"visible": "测试水印"}'));
      expect(updated.purpose, equals('测试用途'));
      expect(updated.notes, equals('测试备注'));
      expect(updated.errorMessage, isNull);
    });

    test('toMap应该正确序列化数据', () {
      final record = ExportRecord(
        documentId: 'doc-999',
        exportPath: '/path/to/export/final.jpg',
        fileName: 'final.jpg',
        status: ExportStatus.failed,
        fileSize: 2048000,
        appliedWatermarkIds: ['wm-1', 'wm-2', 'wm-3'],
        watermarkDetails: '{"error": "水印应用失败"}',
        deviceInfo: 'MacBook Pro',
        purpose: '最终导出',
        notes: '导出失败测试',
        errorMessage: '文件写入失败',
      );

      final map = record.toMap();

      expect(map['documentId'], equals('doc-999'));
      expect(map['exportPath'], equals('/path/to/export/final.jpg'));
      expect(map['fileName'], equals('final.jpg'));
      expect(map['status'], equals(ExportStatus.failed.index));
      expect(map['fileSize'], equals(2048000));
      expect(map['appliedWatermarkIds'], equals('wm-1,wm-2,wm-3'));
      expect(map['watermarkDetails'], equals('{"error": "水印应用失败"}'));
      expect(map['deviceInfo'], equals('MacBook Pro'));
      expect(map['purpose'], equals('最终导出'));
      expect(map['notes'], equals('导出失败测试'));
      expect(map['errorMessage'], equals('文件写入失败'));
      expect(map['id'], isNotEmpty);
      expect(map['exportTime'], isA<int>());
      expect(map['createdAt'], isA<int>());
      expect(map['updatedAt'], isA<int>());
    });

    test('fromMap应该正确反序列化数据', () {
      final map = {
        'id': 'test-record-123',
        'documentId': 'doc-123',
        'exportPath': '/path/to/export/test.jpg',
        'fileName': 'test.jpg',
        'status': ExportStatus.success.index,
        'exportTime': 1640995200000, // 2022-01-01 00:00:00 UTC
        'fileSize': 1536000,
        'appliedWatermarkIds': 'wm-1,wm-2',
        'watermarkDetails': '{"visible": "测试", "invisible": "隐藏"}',
        'deviceInfo': 'Test Device',
        'purpose': '测试用途',
        'notes': '测试备注',
        'errorMessage': null,
        'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
        'updatedAt': 1640995200000,
      };

      final record = ExportRecord.fromMap(map);

      expect(record.id, equals('test-record-123'));
      expect(record.documentId, equals('doc-123'));
      expect(record.exportPath, equals('/path/to/export/test.jpg'));
      expect(record.fileName, equals('test.jpg'));
      expect(record.status, equals(ExportStatus.success));
      expect(record.fileSize, equals(1536000));
      expect(record.appliedWatermarkIds, equals(['wm-1', 'wm-2']));
      expect(
        record.watermarkDetails,
        equals('{"visible": "测试", "invisible": "隐藏"}'),
      );
      expect(record.deviceInfo, equals('Test Device'));
      expect(record.purpose, equals('测试用途'));
      expect(record.notes, equals('测试备注'));
      expect(record.errorMessage, isNull);
      expect(
        record.exportTime,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
      expect(
        record.createdAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
      expect(
        record.updatedAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
    });

    test('fromMap应该处理空值', () {
      final map = {
        'id': 'test-record-456',
        'documentId': 'doc-456',
        'exportPath': '/path/to/export/empty.jpg',
        'fileName': 'empty.jpg',
        'status': ExportStatus.exporting.index,
        'exportTime': 1640995200000,
        'fileSize': 1024000,
        'appliedWatermarkIds': '',
        'watermarkDetails': '{}',
        'deviceInfo': 'Empty Device',
        'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
        'updatedAt': 1640995200000,
      };

      final record = ExportRecord.fromMap(map);

      expect(record.appliedWatermarkIds, isEmpty);
      expect(record.purpose, isNull);
      expect(record.notes, isNull);
      expect(record.errorMessage, isNull);
    });

    test('fileSizeFormatted应该正确格式化文件大小', () {
      final record1 = ExportRecord(
        documentId: 'doc-1',
        exportPath: '/path/to/small.jpg',
        fileName: 'small.jpg',
        fileSize: 512,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      final record2 = ExportRecord(
        documentId: 'doc-2',
        exportPath: '/path/to/medium.jpg',
        fileName: 'medium.jpg',
        fileSize: 1536000,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      final record3 = ExportRecord(
        documentId: 'doc-3',
        exportPath: '/path/to/large.jpg',
        fileName: 'large.jpg',
        fileSize: 3145728,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      expect(record1.fileSizeFormatted, equals('512B'));
      expect(record2.fileSizeFormatted, equals('1.5MB'));
      expect(record3.fileSizeFormatted, equals('3.0MB'));
    });

    test('statusText应该返回正确的中文描述', () {
      final exporting = ExportRecord(
        documentId: 'doc-1',
        exportPath: '/path/to/exporting.jpg',
        fileName: 'exporting.jpg',
        status: ExportStatus.exporting,
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      final success = ExportRecord(
        documentId: 'doc-2',
        exportPath: '/path/to/success.jpg',
        fileName: 'success.jpg',
        status: ExportStatus.success,
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      final failed = ExportRecord(
        documentId: 'doc-3',
        exportPath: '/path/to/failed.jpg',
        fileName: 'failed.jpg',
        status: ExportStatus.failed,
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      final cancelled = ExportRecord(
        documentId: 'doc-4',
        exportPath: '/path/to/cancelled.jpg',
        fileName: 'cancelled.jpg',
        status: ExportStatus.cancelled,
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test',
      );

      expect(exporting.statusText, equals('导出中'));
      expect(success.statusText, equals('导出成功'));
      expect(failed.statusText, equals('导出失败'));
      expect(cancelled.statusText, equals('已取消'));
    });

    test('相等性比较应该正确工作', () {
      final record1 = ExportRecord(
        id: 'same-id',
        documentId: 'doc-1',
        exportPath: '/path/to/record1.jpg',
        fileName: 'record1.jpg',
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Device 1',
      );

      final record2 = ExportRecord(
        id: 'same-id',
        documentId: 'doc-2', // 不同内容
        exportPath: '/path/to/record2.jpg',
        fileName: 'record2.jpg',
        fileSize: 2048000,
        watermarkDetails: '{"different": "content"}',
        deviceInfo: 'Device 2',
      );

      final record3 = ExportRecord(
        id: 'different-id',
        documentId: 'doc-1',
        exportPath: '/path/to/record1.jpg',
        fileName: 'record1.jpg',
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Device 1',
      );

      expect(record1, equals(record2)); // 相同ID
      expect(record1, isNot(equals(record3))); // 不同ID
      expect(record1.hashCode, equals(record2.hashCode));
      expect(record1.hashCode, isNot(equals(record3.hashCode)));
    });

    test('toString应该返回有意义的字符串', () {
      final record = ExportRecord(
        documentId: 'doc-123',
        exportPath: '/path/to/export.jpg',
        fileName: 'export.jpg',
        status: ExportStatus.success,
        fileSize: 1024000,
        watermarkDetails: '{}',
        deviceInfo: 'Test Device',
      );

      final str = record.toString();
      expect(str, contains('ExportRecord'));
      expect(str, contains('doc-123'));
      expect(str, contains('export.jpg'));
      expect(str, contains('success'));
    });

    test('ExportStatus枚举应该正确工作', () {
      expect(ExportStatus.exporting.index, equals(0));
      expect(ExportStatus.success.index, equals(1));
      expect(ExportStatus.failed.index, equals(2));
      expect(ExportStatus.cancelled.index, equals(3));
      expect(ExportStatus.values.length, equals(4));
    });
  });
}
