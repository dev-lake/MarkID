import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../providers/document_provider.dart';
import '../utils/image_debug_utils.dart';
import '../widgets/export_history_widget.dart';
import 'document_edit_screen.dart';
import 'export_watermark_screen.dart';
import 'photo_management_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:watermark_unique/watermark_unique.dart';

class DocumentDetailScreen extends StatefulWidget {
  final String documentId;

  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  IdDocument? _document;
  bool _isLoading = true;
  String? _error;
  Uint8List? markedImage;
  final watermarkPlugin = WatermarkUnique();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = context.read<DocumentProvider>();
      final document = provider.getDocumentById(widget.documentId);

      if (document != null) {
        setState(() {
          _document = document;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '未找到证件信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载证件信息失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_document?.documentType ?? '证件详情'),
      actions: [
        if (_document != null) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDocument,
            tooltip: '编辑',
          ),
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Color.fromARGB(167, 244, 67, 54),
            ),
            onPressed: _deleteDocument,
            tooltip: '删除',
          ),
        ],
      ],
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
            ElevatedButton(onPressed: _loadDocument, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_document == null) {
      return const Center(child: Text('证件不存在'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSection(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          ExportHistoryWidget(documentId: widget.documentId),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final photos = _document!.sortedPhotos;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.photo, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('证件照片', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${photos.length}张',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  onPressed: _navigateToPhotoManagement,
                  tooltip: '管理照片',
                ),
                if (kDebugMode)
                  IconButton(
                    icon: const Icon(Icons.bug_report, size: 20),
                    onPressed: _debugImage,
                    tooltip: '调试图片',
                  ),
              ],
            ),
          ),
          if (photos.isEmpty)
            _buildEmptyPhotoState()
          else if (photos.length == 1)
            _buildSinglePhotoView(photos.first)
          else
            _buildMultiplePhotosView(photos),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无照片',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text('点击右上角按钮添加照片', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSinglePhotoView(DocumentPhoto photo) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: _buildPhotoWidget(photo),
      ),
    );
  }

  Widget _buildMultiplePhotosView(List<DocumentPhoto> photos) {
    return Column(
      children: [
        // 主照片显示
        AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: _buildPhotoWidget(photos.first),
          ),
        ),
        // 照片缩略图列表
        Container(
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Container(
                width: 64,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: photo.isPrimary
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      _buildPhotoThumbnail(photo),
                      if (photo.isPrimary)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.star,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoWidget(DocumentPhoto photo) {
    return FutureBuilder<File?>(
      future: ImageDebugUtils.getImageFile(photo.originalImagePath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('图片加载失败', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return Image.file(
          snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('图片显示失败', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPhotoThumbnail(DocumentPhoto photo) {
    return FutureBuilder<File?>(
      future: ImageDebugUtils.getImageFile(
        photo.thumbnailPath ?? photo.originalImagePath,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.broken_image, size: 16, color: Colors.grey),
            ),
          );
        }

        return Image.file(
          snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 16, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoSection() {
    final primaryPhoto = _document!.primaryPhoto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('证件信息', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('证件类型', _document!.documentType),
            _buildInfoRow('持有人姓名', _document!.holderName ?? '未填写'),
            _buildInfoRow('证件号码', _document!.documentNumber ?? '未填写'),
            _buildInfoRow('照片数量', '${_document!.photos.length}张'),
            _buildInfoRow('文件大小', _document!.fileSizeFormatted),
            if (primaryPhoto != null)
              _buildInfoRow('拍摄时间', _formatDateTime(primaryPhoto.captureTime)),
            _buildInfoRow('创建时间', _formatDateTime(_document!.createdAt)),
            _buildInfoRow('更新时间', _formatDateTime(_document!.updatedAt)),
            _buildInfoRow('备注', _document!.notes ?? '无'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    if (_document!.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('标签', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _document!.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_document == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.only(left: 40, right: 40, top: 5, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportWithWatermark,
              icon: const Icon(Icons.water_drop),
              label: const Text('导出使用'),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPhotoManagement() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                PhotoManagementScreen(documentId: widget.documentId),
          ),
        )
        .then((_) {
          // 返回时刷新数据
          _loadDocument();
        });
  }

  void _editDocument() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                DocumentEditScreen(documentId: widget.documentId),
          ),
        )
        .then((_) => _loadDocument());
  }

  void _deleteDocument() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这个证件吗？\n\n${_document!.documentType}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await context
                  .read<DocumentProvider>()
                  .deleteDocument(widget.documentId);
              if (success && mounted) {
                Navigator.of(context).pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _exportWithWatermark() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExportWatermarkScreen(documentId: widget.documentId),
      ),
    );
  }

  void _exportWithoutWatermark() {
    // 实现直接导出功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('直接导出功能开发中...')));
  }

  void _debugImage() {
    if (_document!.photos.isNotEmpty) {
      final photo = _document!.photos.first;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('图片调试信息'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('原始路径: ${photo.originalImagePath}'),
              Text('缩略图路径: ${photo.thumbnailPath ?? '无'}'),
              Text('文件大小: ${photo.fileSizeFormatted}'),
              Text('尺寸: ${photo.width} × ${photo.height}'),
              Text('照片类型: ${photo.photoType}'),
              if (photo.description != null) Text('描述: ${photo.description}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
