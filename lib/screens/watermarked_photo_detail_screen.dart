import 'package:flutter/material.dart';
import 'dart:io';
import '../services/watermarked_photo_service.dart';

/// 水印照片详情页面
class WatermarkedPhotoDetailScreen extends StatefulWidget {
  final String recordId;

  const WatermarkedPhotoDetailScreen({super.key, required this.recordId});

  @override
  State<WatermarkedPhotoDetailScreen> createState() =>
      _WatermarkedPhotoDetailScreenState();
}

class _WatermarkedPhotoDetailScreenState
    extends State<WatermarkedPhotoDetailScreen> {
  WatermarkedPhotoInfo? _photo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotoDetail();
  }

  Future<void> _loadPhotoDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final photo = await WatermarkedPhotoService.getWatermarkedPhotoById(
        widget.recordId,
      );

      setState(() {
        _photo = photo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载照片详情失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出详情'),
        actions: [
          if (_photo != null) ...[
            if (_photo!.canViewPhoto)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _sharePhoto,
                tooltip: '分享',
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePhoto,
              tooltip: '删除',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPhotoDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_photo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('照片不存在', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('该导出记录可能已被删除', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 照片预览
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _photo!.hasActualFile
                    ? Image.file(
                        File(_photo!.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage('图片加载失败');
                        },
                      )
                    : _buildPlaceholderImage(_photo!.statusText),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 基本信息
          _buildInfoSection('基本信息', [
            _buildInfoRow('文件名', _photo!.fileName),
            _buildInfoRow('状态', _photo!.statusText),
            _buildInfoRow('文件大小', _photo!.fileSizeFormatted),
            _buildInfoRow('导出时间', _photo!.relativeTime),
            _buildInfoRow('最后修改', _formatDateTime(_photo!.lastModified)),
          ]),

          const SizedBox(height: 16),

          // 水印信息
          _buildInfoSection('水印信息', [
            _buildInfoRow('水印文本', _photo!.watermarkText),
            _buildInfoRow('水印配置', _photo!.watermarkConfigName),
          ]),

          if (_photo!.purpose != null) ...[
            const SizedBox(height: 16),
            _buildInfoSection('用途信息', [_buildInfoRow('用途', _photo!.purpose!)]),
          ],

          if (_photo!.notes != null && _photo!.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoSection('备注', [_buildInfoRow('备注', _photo!.notes!)]),
          ],

          if (_photo!.errorMessage != null &&
              _photo!.errorMessage!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoSection('错误信息', [
              _buildInfoRow('错误', _photo!.errorMessage!),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getStatusIcon(text), size: 48, color: _getStatusColor(text)),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 16, color: _getStatusColor(text)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case '导出中':
        return Icons.hourglass_empty;
      case '导出成功':
        return Icons.check_circle;
      case '导出失败':
        return Icons.error;
      case '已取消':
        return Icons.cancel;
      case '图片加载失败':
        return Icons.error_outline;
      default:
        return Icons.photo;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '导出中':
        return Colors.orange;
      case '导出成功':
        return Colors.green;
      case '导出失败':
        return Colors.red;
      case '已取消':
        return Colors.grey;
      case '图片加载失败':
        return Colors.grey[400]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _sharePhoto() {
    // TODO: 实现分享功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享功能开发中...')));
  }

  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条导出记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await WatermarkedPhotoService.deleteWatermarkedPhoto(
          widget.recordId,
        );
        if (success) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('记录已删除')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('删除失败')));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败: $e')));
        }
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
