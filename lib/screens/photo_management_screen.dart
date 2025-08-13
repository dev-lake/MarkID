import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../providers/document_provider.dart';
import '../services/multi_photo_service.dart';
import '../utils/image_debug_utils.dart';

class PhotoManagementScreen extends StatefulWidget {
  final String documentId;

  const PhotoManagementScreen({super.key, required this.documentId});

  @override
  State<PhotoManagementScreen> createState() => _PhotoManagementScreenState();
}

class _PhotoManagementScreenState extends State<PhotoManagementScreen> {
  IdDocument? _document;
  bool _isLoading = true;
  String? _error;
  final MultiPhotoService _photoService = MultiPhotoService();

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
      appBar: AppBar(
        title: const Text('照片管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _showAddPhotoDialog,
            tooltip: '添加照片',
          ),
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
            Text(_error!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadDocument, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_document == null) {
      return const Center(child: Text('证件不存在'));
    }

    final photos = _document!.sortedPhotos;

    if (photos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildPhotoStats(),
        Expanded(child: _buildPhotoList(photos)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无照片',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text('点击右上角按钮添加照片', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPhotoDialog,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('添加第一张照片'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStats() {
    final stats = _photoService.getPhotoStats(_document!.photos);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              '总照片数',
              '${stats['totalPhotos']}',
              Icons.photo_library,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '总大小',
              _formatFileSize(stats['totalSize']),
              Icons.storage,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              '照片类型',
              '${stats['photoTypes'].length}',
              Icons.category,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPhotoList(List<DocumentPhoto> photos) {
    return ReorderableListView.builder(
      itemCount: photos.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _buildPhotoCard(photo, index);
      },
    );
  }

  Widget _buildPhotoCard(DocumentPhoto photo, int index) {
    return Card(
      key: ValueKey(photo.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: _buildPhotoImage(photo),
                ),
              ),
              if (photo.isPrimary)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '主照片',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    photo.photoTypeDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (photo.description != null) ...[
                            Text(
                              photo.description!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            '${photo.width} × ${photo.height}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            photo.fileSizeFormatted,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handlePhotoAction(value, photo),
                      itemBuilder: (context) => [
                        if (!photo.isPrimary)
                          const PopupMenuItem(
                            value: 'set_primary',
                            child: Row(
                              children: [
                                Icon(Icons.star),
                                SizedBox(width: 8),
                                Text('设为主照片'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('编辑信息'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoImage(DocumentPhoto photo) {
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

  void _showAddPhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPhotoDialog(
        documentId: widget.documentId,
        onPhotoAdded: (photo) {
          Navigator.of(context).pop();
          _loadDocument();
        },
      ),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final photos = _document!.sortedPhotos;
    final photo = photos.removeAt(oldIndex);
    photos.insert(newIndex, photo);

    final photoIds = photos.map((p) => p.id).toList();

    try {
      final success = await _photoService.reorderPhotos(
        documentId: widget.documentId,
        photoIds: photoIds,
      );

      if (success) {
        _loadDocument();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('重新排序失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重新排序失败: $e')));
    }
  }

  Future<void> _handlePhotoAction(String action, DocumentPhoto photo) async {
    switch (action) {
      case 'set_primary':
        await _setPrimaryPhoto(photo);
        break;
      case 'edit':
        _showEditPhotoDialog(photo);
        break;
      case 'delete':
        await _deletePhoto(photo);
        break;
    }
  }

  Future<void> _setPrimaryPhoto(DocumentPhoto photo) async {
    try {
      final success = await _photoService.setPrimaryPhoto(
        documentId: widget.documentId,
        photoId: photo.id,
      );

      if (success) {
        _loadDocument();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已设置为主照片')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置主照片失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设置主照片失败: $e')));
    }
  }

  void _showEditPhotoDialog(DocumentPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => _EditPhotoDialog(
        photo: photo,
        onPhotoUpdated: () {
          Navigator.of(context).pop();
          _loadDocument();
        },
      ),
    );
  }

  Future<void> _deletePhoto(DocumentPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这张照片吗？\n\n${photo.photoTypeDisplay}'),
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
        final success = await _photoService.removePhotoFromDocument(
          documentId: widget.documentId,
          photoId: photo.id,
        );

        if (success) {
          _loadDocument();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('照片已删除')));
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('删除照片失败')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除照片失败: $e')));
      }
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
}

class _AddPhotoDialog extends StatefulWidget {
  final String documentId;
  final Function(DocumentPhoto) onPhotoAdded;

  const _AddPhotoDialog({required this.documentId, required this.onPhotoAdded});

  @override
  State<_AddPhotoDialog> createState() => _AddPhotoDialogState();
}

class _AddPhotoDialogState extends State<_AddPhotoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _photoTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MultiPhotoService _photoService = MultiPhotoService();
  bool _isLoading = false;

  final List<String> _photoTypes = [
    '正面',
    '反面',
    '内页',
    '第一页',
    '第二页',
    '第三页',
    '其他',
  ];

  @override
  void dispose() {
    _photoTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加照片'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _photoTypeController.text.isEmpty
                  ? null
                  : _photoTypeController.text,
              decoration: const InputDecoration(
                labelText: '照片类型',
                border: OutlineInputBorder(),
              ),
              items: _photoTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _photoTypeController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择照片类型';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '照片描述（可选）',
                border: OutlineInputBorder(),
                hintText: '例如：身份证正面、护照内页等',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPhoto,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _addPhoto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<DocumentProvider>();
      final success = await provider.addPhotoToDocument(
        documentId: widget.documentId,
        photoType: _photoTypeController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (success) {
        widget.onPhotoAdded(
          DocumentPhoto(
            photoType: _photoTypeController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            originalImagePath: '',
            fileSize: 0,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('添加照片失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('添加照片失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _EditPhotoDialog extends StatefulWidget {
  final DocumentPhoto photo;
  final VoidCallback onPhotoUpdated;

  const _EditPhotoDialog({required this.photo, required this.onPhotoUpdated});

  @override
  State<_EditPhotoDialog> createState() => _EditPhotoDialogState();
}

class _EditPhotoDialogState extends State<_EditPhotoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _photoTypeController;
  late final TextEditingController _descriptionController;
  final MultiPhotoService _photoService = MultiPhotoService();
  bool _isLoading = false;

  final List<String> _photoTypes = [
    '正面',
    '反面',
    '内页',
    '第一页',
    '第二页',
    '第三页',
    '其他',
  ];

  @override
  void initState() {
    super.initState();
    _photoTypeController = TextEditingController(text: widget.photo.photoType);
    _descriptionController = TextEditingController(
      text: widget.photo.description ?? '',
    );
  }

  @override
  void dispose() {
    _photoTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑照片信息'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _photoTypeController.text,
              decoration: const InputDecoration(
                labelText: '照片类型',
                border: OutlineInputBorder(),
              ),
              items: _photoTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _photoTypeController.text = value ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择照片类型';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '照片描述（可选）',
                border: OutlineInputBorder(),
                hintText: '例如：身份证正面、护照内页等',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePhoto,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _updatePhoto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _photoService.updatePhotoInfo(
        documentId: 'temp', // 这里需要从context获取documentId
        photoId: widget.photo.id,
        photoType: _photoTypeController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (success) {
        widget.onPhotoUpdated();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('更新照片信息失败')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('更新照片信息失败: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
