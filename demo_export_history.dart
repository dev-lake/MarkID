import 'dart:convert';
import 'dart:io';
import 'lib/models/models.dart';
import 'lib/repositories/export_record_repository.dart';

/// 导出历史记录功能演示
void main() async {
  print('=== 导出历史记录功能演示 ===\n');

  try {
    // 1. 创建示例导出记录
    print('1. 创建示例导出记录...');

    final record1 = ExportRecord(
      documentId: 'demo_document_1',
      exportPath: '/storage/emulated/0/Pictures/watermarked_id_card_1.jpg',
      fileName: 'watermarked_id_card_1.jpg',
      fileSize: 1024 * 1024, // 1MB
      appliedWatermarkIds: ['watermark_config_1'],
      watermarkDetails: json.encode({
        'text': '仅限办理业务使用',
        'config': '标准水印配置',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      deviceInfo: 'Android Device',
      purpose: '办理银行业务',
      notes: '用于银行开户验证',
    );

    final record2 = ExportRecord(
      documentId: 'demo_document_1',
      exportPath: '/storage/emulated/0/Pictures/watermarked_id_card_2.jpg',
      fileName: 'watermarked_id_card_2.jpg',
      fileSize: 1024 * 768, // 768KB
      appliedWatermarkIds: ['watermark_config_2'],
      watermarkDetails: json.encode({
        'text': '仅限保险业务使用',
        'config': '保险专用水印',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      deviceInfo: 'Android Device',
      purpose: '办理保险业务',
      notes: '用于保险理赔验证',
    );

    final failedRecord = ExportRecord(
      documentId: 'demo_document_1',
      exportPath: '',
      fileName: '',
      fileSize: 0,
      appliedWatermarkIds: ['watermark_config_3'],
      watermarkDetails: json.encode({
        'text': '测试水印',
        'config': '测试配置',
        'timestamp': DateTime.now().toIso8601String(),
      }),
      deviceInfo: 'Android Device',
      status: ExportStatus.failed,
      errorMessage: '存储空间不足，导出失败',
    );

    print('✓ 创建了3条示例记录（2条成功，1条失败）\n');

    // 2. 保存记录
    print('2. 保存导出记录...');

    await ExportRecordRepository.saveExportRecord(record1);
    await ExportRecordRepository.saveExportRecord(record2);
    await ExportRecordRepository.saveExportRecord(failedRecord);

    print('✓ 记录保存成功\n');

    // 3. 查询记录
    print('3. 查询证件的导出记录...');

    final records = await ExportRecordRepository.getExportRecordsByDocumentId(
      'demo_document_1',
    );

    print('✓ 找到 ${records.length} 条记录：');
    for (final record in records) {
      print(
        '  - ${record.fileName} (${record.statusText}) - ${record.fileSizeFormatted}',
      );
      if (record.purpose != null) {
        print('    用途: ${record.purpose}');
      }
      if (record.notes != null) {
        print('    备注: ${record.notes}');
      }
      if (record.errorMessage != null) {
        print('    错误: ${record.errorMessage}');
      }
      print('');
    }

    // 4. 获取统计信息
    print('4. 获取导出统计信息...');

    final stats = await ExportRecordRepository.getExportStats();

    print('✓ 统计信息：');
    print('  - 总记录数: ${stats['totalRecords']}');
    print('  - 成功记录: ${stats['successRecords']}');
    print('  - 失败记录: ${stats['failedRecords']}');
    print('  - 总文件大小: ${_formatFileSize(stats['totalFileSize'])}');

    if (stats['oldestRecord'] != null) {
      print('  - 最早记录: ${stats['oldestRecord']}');
    }
    if (stats['newestRecord'] != null) {
      print('  - 最新记录: ${stats['newestRecord']}');
    }
    print('');

    // 5. 演示记录详情
    print('5. 记录详情示例...');

    if (records.isNotEmpty) {
      final sampleRecord = records.first;
      print('✓ 示例记录详情：');
      print('  ID: ${sampleRecord.id}');
      print('  证件ID: ${sampleRecord.documentId}');
      print('  文件名: ${sampleRecord.fileName}');
      print('  状态: ${sampleRecord.statusText}');
      print('  导出时间: ${sampleRecord.exportTime}');
      print('  文件大小: ${sampleRecord.fileSizeFormatted}');
      print('  设备信息: ${sampleRecord.deviceInfo}');
      print('  水印配置: ${sampleRecord.appliedWatermarkIds.join(', ')}');

      final watermarkDetails = json.decode(sampleRecord.watermarkDetails);
      print('  水印文本: ${watermarkDetails['text']}');
      print('  水印配置: ${watermarkDetails['config']}');

      if (sampleRecord.purpose != null) {
        print('  用途: ${sampleRecord.purpose}');
      }
      if (sampleRecord.notes != null) {
        print('  备注: ${sampleRecord.notes}');
      }
      if (sampleRecord.errorMessage != null) {
        print('  错误信息: ${sampleRecord.errorMessage}');
      }
    }
    print('');

    // 6. 演示UI组件功能
    print('6. UI组件功能演示...');
    print('✓ ExportHistoryWidget 组件功能：');
    print('  - 自动加载指定证件的导出记录');
    print('  - 显示加载状态和错误处理');
    print('  - 空状态提示用户导出照片');
    print('  - 卡片式布局展示记录详情');
    print('  - 状态图标和颜色区分');
    print('  - 相对时间显示（如"2小时前"）');
    print('  - 文件大小自动格式化');
    print('  - 用途和备注信息展示');
    print('  - 错误信息高亮显示');
    print('');

    print('=== 演示完成 ===');
    print('功能已成功集成到应用中！');
    print('在证件详情页面底部可以看到"导出历史"部分。');
  } catch (e) {
    print('演示过程中出现错误: $e');
  }
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '${bytes}B';
  } else if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)}KB';
  } else {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
