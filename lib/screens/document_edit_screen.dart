import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../providers/document_provider.dart';

class DocumentEditScreen extends StatefulWidget {
  final String documentId;

  const DocumentEditScreen({super.key, required this.documentId});

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentTypeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _tags = [];
  final List<String> _availableTags = [];

  IdDocument? _document;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _holderNameController.dispose();
    _notesController.dispose();
    super.dispose();
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
        _document = document;
        _documentTypeController.text = document.documentType;
        _documentNumberController.text = document.documentNumber ?? '';
        _holderNameController.text = document.holderName ?? '';
        _notesController.text = document.notes ?? '';
        _tags.clear();
        _tags.addAll(document.tags);

        // 加载可用标签
        _availableTags.clear();
        _availableTags.addAll(provider.getAllTags());

        setState(() {
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
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('编辑证件'),
      actions: [
        if (!_isLoading && _document != null)
          TextButton(
            onPressed: _isSaving ? null : _saveDocument,
            child: _isSaving
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
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

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('证件照片', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _changePhoto,
                  icon: const Icon(Icons.edit),
                  label: const Text('更换'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWidget(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    final primaryPhoto = _document!.primaryPhoto;
    if (primaryPhoto == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text('暂无照片', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final imagePath = primaryPhoto.originalImagePath;
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    }
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
                labelText: '证件类型',
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(
                labelText: '持有人姓名',
                hintText: '请输入持有人姓名',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入持有人姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _documentNumberController,
              decoration: const InputDecoration(
                labelText: '证件号码',
                hintText: '请输入证件号码',
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入证件号码';
                }
                return null;
              },
            ),
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

  void _changePhoto() {
    // TODO: 实现更换照片功能
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('更换照片功能开发中...')));
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

    try {
      setState(() {
        _isSaving = true;
      });

      final updatedDocument = _document!.copyWith(
        documentType: _documentTypeController.text.trim(),
        documentNumber: _documentNumberController.text.trim(),
        holderName: _holderNameController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        tags: List.from(_tags),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<DocumentProvider>();
      await provider.updateDocument(updatedDocument);

      if (mounted) {
        Navigator.of(context).pop(true); // 返回true表示已保存
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存成功')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
