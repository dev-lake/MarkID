import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../providers/document_provider.dart';
import '../services/multi_photo_service.dart';

class MultiPhotoAddScreen extends StatefulWidget {
  const MultiPhotoAddScreen({super.key});

  @override
  State<MultiPhotoAddScreen> createState() => _MultiPhotoAddScreenState();
}

class _MultiPhotoAddScreenState extends State<MultiPhotoAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentTypeController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _notesController = TextEditingController();

  // 常见证件类型快捷标签
  static const List<String> _commonDocumentTypes = [
    '身份证',
    '护照',
    '驾驶证',
    '港澳通行证',
    '台湾通行证',
    '社保卡',
    '学生证',
    '工作证',
  ];

  final List<String> _tags = [];
  final List<String> _availableTags = [];

  final List<PhotoItem> _photoItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _holderNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    final provider = context.read<DocumentProvider>();
    _availableTags.clear();
    _availableTags.addAll(provider.getAllTags());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加证件'),
        actions: [
          if (_photoItems.isNotEmpty)
            TextButton(
              onPressed: _isLoading ? null : _saveDocument,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotoListSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildTagsSection(),
            const SizedBox(height: 24),
            _buildNotesSection(),
            const SizedBox(height: 100), // 底部留白
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
                Text('基本信息', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentTypeController,
              decoration: const InputDecoration(
                labelText: '证件类型 *',
                hintText: '如：身份证、护照、驾驶证',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入证件类型';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonDocumentTypes.map((type) {
                final selected = _documentTypeController.text == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _documentTypeController.text = type;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(
                labelText: '持有人姓名',
                hintText: '请输入持有人姓名',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: '证件号码',
                hintText: '请输入证件号码',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoListSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.photo_library,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text('证件照片', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddPhotoDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('添加照片'),
                ),
                const SizedBox(width: 8),
                Text('${_photoItems.length}张'),
              ],
            ),
            const SizedBox(height: 16),
            if (_photoItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无照片',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击上方“添加照片”按钮添加照片',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _photoItems.length,
                itemBuilder: (context, index) {
                  return _buildPhotoItem(_photoItems[index], index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(PhotoItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '照片 ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPhotoItem(item, index),
                  tooltip: '编辑',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removePhotoItem(index),
                  tooltip: '删除',
                ),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageData != null
                      ? Image.memory(item.imageData!, fit: BoxFit.contain)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '图片加载中...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('类型: ${item.photoType}'),
            if (item.description?.isNotEmpty == true)
              Text('描述: ${item.description}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
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
                const Spacer(),
                TextButton.icon(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '暂无标签，点击添加按钮添加标签',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('备注', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: '备注信息',
                hintText: '请输入备注信息（可选）',
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddPhotoDialog(
        onPhotoAdded: (photoItem) {
          setState(() {
            _photoItems.add(photoItem);
          });
        },
      ),
    );
  }

  void _editPhotoItem(PhotoItem item, int index) {
    showDialog(
      context: context,
      builder: (context) => _EditPhotoDialog(
        photoItem: item,
        onPhotoUpdated: (updatedItem) {
          setState(() {
            _photoItems[index] = updatedItem;
          });
        },
      ),
    );
  }

  void _removePhotoItem(int index) {
    setState(() {
      _photoItems.removeAt(index);
    });
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标签名称',
                hintText: '请输入标签名称',
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addTagToList(value.trim());
                  Navigator.of(context).pop();
                }
              },
            ),
            if (_availableTags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('常用标签：'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableTags
                    .where((tag) => !_tags.contains(tag))
                    .take(10)
                    .map(
                      (tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          _addTagToList(tag);
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _addTagToList(String tag) {
    if (!_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_photoItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请至少添加一张照片')));
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = context.read<DocumentProvider>();
      final success = await provider.createDocumentWithMultiplePhotos(
        documentType: _documentTypeController.text.trim(),
        documentNumber: _documentNumberController.text.trim().isEmpty
            ? null
            : _documentNumberController.text.trim(),
        holderName: _holderNameController.text.trim().isEmpty
            ? null
            : _holderNameController.text.trim(),
        photoItems: _photoItems,
        tags: _tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('证件添加成功')));
      }
    } catch (e) {
      setState(() {
        _error = '保存失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class PhotoItem {
  final Uint8List? imageData;
  final String photoType;
  final String? description;
  final ImageSource source;

  PhotoItem({
    this.imageData,
    required this.photoType,
    this.description,
    required this.source,
  });

  PhotoItem copyWith({
    Uint8List? imageData,
    String? photoType,
    String? description,
    ImageSource? source,
  }) {
    return PhotoItem(
      imageData: imageData ?? this.imageData,
      photoType: photoType ?? this.photoType,
      description: description ?? this.description,
      source: source ?? this.source,
    );
  }
}

class _AddPhotoDialog extends StatefulWidget {
  final Function(PhotoItem) onPhotoAdded;

  const _AddPhotoDialog({required this.onPhotoAdded});

  @override
  State<_AddPhotoDialog> createState() => _AddPhotoDialogState();
}

class _AddPhotoDialogState extends State<_AddPhotoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _photoTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MultiPhotoService _photoService = MultiPhotoService();
  bool _isLoading = false;
  ImageSource _selectedSource = ImageSource.camera;

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
                labelText: '照片类型 *',
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
            const SizedBox(height: 16),
            SegmentedButton<ImageSource>(
              segments: const [
                ButtonSegment(
                  value: ImageSource.camera,
                  label: Text('拍照'),
                  icon: Icon(Icons.camera_alt),
                ),
                ButtonSegment(
                  value: ImageSource.gallery,
                  label: Text('相册'),
                  icon: Icon(Icons.photo_library),
                ),
              ],
              selected: {_selectedSource},
              onSelectionChanged: (Set<ImageSource> selection) {
                setState(() {
                  _selectedSource = selection.first;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final XFile? image = await _photoService.imagePicker.pickImage(
        source: _selectedSource,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final imageData = await image.readAsBytes();
        final photoItem = PhotoItem(
          imageData: imageData,
          photoType: _photoTypeController.text,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          source: _selectedSource,
        );

        widget.onPhotoAdded(photoItem);
        Navigator.of(context).pop();
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
  final PhotoItem photoItem;
  final Function(PhotoItem) onPhotoUpdated;

  const _EditPhotoDialog({
    required this.photoItem,
    required this.onPhotoUpdated,
  });

  @override
  State<_EditPhotoDialog> createState() => _EditPhotoDialogState();
}

class _EditPhotoDialogState extends State<_EditPhotoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _photoTypeController;
  late final TextEditingController _descriptionController;

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
    _photoTypeController = TextEditingController(
      text: widget.photoItem.photoType,
    );
    _descriptionController = TextEditingController(
      text: widget.photoItem.description ?? '',
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
      title: const Text('编辑照片'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.photoItem.imageData != null
                      ? Image.memory(
                          widget.photoItem.imageData!,
                          fit: BoxFit.contain,
                        )
                      : const Center(child: Text('图片加载失败')),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _photoTypeController.text,
              decoration: const InputDecoration(
                labelText: '照片类型 *',
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(onPressed: _updatePhoto, child: const Text('保存')),
      ],
    );
  }

  void _updatePhoto() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedItem = widget.photoItem.copyWith(
      photoType: _photoTypeController.text,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
    );

    widget.onPhotoUpdated(updatedItem);
    Navigator.of(context).pop();
  }
}
