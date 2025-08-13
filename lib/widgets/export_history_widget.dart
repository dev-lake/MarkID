import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/export_record_repository.dart';
import '../screens/watermarked_photo_detail_screen.dart';

/// 导出历史记录组件
class ExportHistoryWidget extends StatefulWidget {
  final String documentId;

  const ExportHistoryWidget({super.key, required this.documentId});

  @override
  State<ExportHistoryWidget> createState() => _ExportHistoryWidgetState();
}

class _ExportHistoryWidgetState extends State<ExportHistoryWidget> {
  List<ExportRecord> _exportRecords = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExportRecords();
    _fixHistoricalRecords();
  }

  Future<void> _loadExportRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final records = await ExportRecordRepository.getExportRecordsByDocumentId(
        widget.documentId,
      );

      setState(() {
        _exportRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载导出记录失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fixHistoricalRecords() async {
    try {
      final fixedCount =
          await ExportRecordRepository.fixHistoricalExportStatus();
      if (fixedCount > 0) {
        // 如果有修复的记录，重新加载数据
        _loadExportRecords();
      }
    } catch (e) {
      debugPrint('修复历史记录失败: $e');
    }
  }

  void _viewRecordDetail(String recordId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WatermarkedPhotoDetailScreen(recordId: recordId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('导出历史', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_exportRecords.isNotEmpty)
                  Text(
                    '${_exportRecords.length} 条记录',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          _buildContent(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadExportRecords, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_exportRecords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('暂无导出记录', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              '导出带水印的照片后将在此显示记录',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _exportRecords
          .map((record) => _buildRecordItem(record))
          .toList(),
    );
  }

  Widget _buildRecordItem(ExportRecord record) {
    return InkWell(
      onTap: () => _viewRecordDetail(record.id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(record.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(record.status),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDateTime(record.exportTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.fileSizeFormatted,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            if (record.purpose != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.label, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '用途: ${record.purpose}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.note, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (record.errorMessage != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.error, size: 14, color: Colors.red[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.errorMessage!,
                      style: TextStyle(fontSize: 12, color: Colors.red[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ExportStatus status) {
    IconData iconData;
    Color color;

    switch (status) {
      case ExportStatus.success:
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case ExportStatus.failed:
        iconData = Icons.error;
        color = Colors.red;
        break;
      case ExportStatus.exporting:
        iconData = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case ExportStatus.cancelled:
        iconData = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return Icon(iconData, size: 16, color: color);
  }

  Color _getStatusColor(ExportStatus status) {
    switch (status) {
      case ExportStatus.success:
        return Colors.green;
      case ExportStatus.failed:
        return Colors.red;
      case ExportStatus.exporting:
        return Colors.orange;
      case ExportStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}
