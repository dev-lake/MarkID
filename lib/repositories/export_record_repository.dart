import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';

/// 导出记录存储服务
class ExportRecordRepository {
  static const String _fileName = 'export_records.json';
  static String? _cachedFilePath;

  /// 获取存储文件路径
  static Future<String> get _filePath async {
    if (_cachedFilePath != null) return _cachedFilePath!;

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String filePath = path.join(appDir.path, _fileName);
    _cachedFilePath = filePath;
    return _cachedFilePath!;
  }

  /// 保存导出记录
  static Future<void> saveExportRecord(ExportRecord record) async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();

      // 检查是否已存在相同ID的记录
      final int existingIndex = records.indexWhere((r) => r.id == record.id);
      if (existingIndex != -1) {
        // 更新现有记录
        records[existingIndex] = record;
      } else {
        // 添加新记录
        records.add(record);
      }

      await _saveRecords(records);
    } catch (e) {
      throw Exception('保存导出记录失败: $e');
    }
  }

  /// 批量保存导出记录
  static Future<void> saveExportRecords(List<ExportRecord> records) async {
    try {
      final List<ExportRecord> existingRecords = await getAllExportRecords();

      // 合并记录，避免重复
      final Map<String, ExportRecord> recordMap = {};

      // 先添加现有记录
      for (final record in existingRecords) {
        recordMap[record.id] = record;
      }

      // 添加新记录，覆盖相同ID的记录
      for (final record in records) {
        recordMap[record.id] = record;
      }

      await _saveRecords(recordMap.values.toList());
    } catch (e) {
      throw Exception('批量保存导出记录失败: $e');
    }
  }

  /// 获取所有导出记录
  static Future<List<ExportRecord>> getAllExportRecords() async {
    try {
      final String filePath = await _filePath;
      final File file = File(filePath);

      if (!await file.exists()) {
        return [];
      }

      final String content = await file.readAsString();
      if (content.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(content);
      return jsonList.map((json) => ExportRecord.fromMap(json)).toList();
    } catch (e) {
      throw Exception('获取导出记录失败: $e');
    }
  }

  /// 根据证件ID获取导出记录
  static Future<List<ExportRecord>> getExportRecordsByDocumentId(
    String documentId,
  ) async {
    try {
      final List<ExportRecord> allRecords = await getAllExportRecords();
      return allRecords
          .where((record) => record.documentId == documentId)
          .toList();
    } catch (e) {
      throw Exception('获取证件导出记录失败: $e');
    }
  }

  /// 根据ID获取导出记录
  static Future<ExportRecord?> getExportRecordById(String id) async {
    try {
      final List<ExportRecord> allRecords = await getAllExportRecords();
      final int index = allRecords.indexWhere((record) => record.id == id);
      return index != -1 ? allRecords[index] : null;
    } catch (e) {
      throw Exception('获取导出记录失败: $e');
    }
  }

  /// 删除导出记录
  static Future<void> deleteExportRecord(String id) async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();
      records.removeWhere((record) => record.id == id);
      await _saveRecords(records);
    } catch (e) {
      throw Exception('删除导出记录失败: $e');
    }
  }

  /// 删除证件的所有导出记录
  static Future<void> deleteExportRecordsByDocumentId(String documentId) async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();
      records.removeWhere((record) => record.documentId == documentId);
      await _saveRecords(records);
    } catch (e) {
      throw Exception('删除证件导出记录失败: $e');
    }
  }

  /// 获取导出统计信息
  static Future<Map<String, dynamic>> getExportStats() async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();

      int totalRecords = records.length;
      int successRecords = records
          .where((r) => r.status == ExportStatus.success)
          .length;
      int failedRecords = records
          .where((r) => r.status == ExportStatus.failed)
          .length;
      int totalFileSize = records.fold(
        0,
        (sum, record) => sum + record.fileSize,
      );

      DateTime? oldestRecord;
      DateTime? newestRecord;

      for (final record in records) {
        if (oldestRecord == null || record.exportTime.isBefore(oldestRecord)) {
          oldestRecord = record.exportTime;
        }
        if (newestRecord == null || record.exportTime.isAfter(newestRecord)) {
          newestRecord = record.exportTime;
        }
      }

      return {
        'totalRecords': totalRecords,
        'successRecords': successRecords,
        'failedRecords': failedRecords,
        'totalFileSize': totalFileSize,
        'oldestRecord': oldestRecord,
        'newestRecord': newestRecord,
      };
    } catch (e) {
      throw Exception('获取导出统计失败: $e');
    }
  }

  /// 清理过期的导出记录（保留最近30天的记录）
  static Future<void> cleanupOldRecords({int daysToKeep = 30}) async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: daysToKeep),
      );

      final List<ExportRecord> filteredRecords = records
          .where((record) => record.exportTime.isAfter(cutoffDate))
          .toList();

      if (filteredRecords.length != records.length) {
        await _saveRecords(filteredRecords);
      }
    } catch (e) {
      throw Exception('清理过期记录失败: $e');
    }
  }

  /// 保存记录到文件
  static Future<void> _saveRecords(List<ExportRecord> records) async {
    try {
      final String filePath = await _filePath;
      final File file = File(filePath);

      // 按导出时间倒序排列
      records.sort((a, b) => b.exportTime.compareTo(a.exportTime));

      final List<Map<String, dynamic>> jsonList = records
          .map((record) => record.toMap())
          .toList();
      final String content = json.encode(jsonList);

      await file.writeAsString(content);
    } catch (e) {
      throw Exception('保存记录到文件失败: $e');
    }
  }

  /// 修复历史导出记录状态
  /// 将已有导出路径且文件存在的记录状态更新为success
  static Future<int> fixHistoricalExportStatus() async {
    try {
      final List<ExportRecord> records = await getAllExportRecords();
      int fixedCount = 0;
      final List<ExportRecord> updatedRecords = [];

      for (final record in records) {
        ExportRecord updatedRecord = record;

        // 如果状态是exporting但有导出路径，检查文件是否存在
        if (record.status == ExportStatus.exporting &&
            record.exportPath.isNotEmpty) {
          final File exportFile = File(record.exportPath);
          if (await exportFile.exists()) {
            // 文件存在，更新状态为success
            updatedRecord = record.copyWith(
              status: ExportStatus.success,
              updatedAt: DateTime.now(),
            );
            fixedCount++;
          }
        }

        updatedRecords.add(updatedRecord);
      }

      if (fixedCount > 0) {
        await _saveRecords(updatedRecords);
      }

      return fixedCount;
    } catch (e) {
      throw Exception('修复历史导出记录状态失败: $e');
    }
  }
}
