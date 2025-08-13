import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../models/models.dart';
import '../widgets/document_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_drawer.dart';
import 'document_detail_screen.dart';
import 'multi_photo_add_screen.dart';

/// 证件照片列表页面
class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final List<String> _selectedIds = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: const FilterDrawer(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('马克证件'),
      actions: [
        if (_isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _selectedIds.isEmpty ? null : _showDeleteDialog,
            tooltip: '删除选中',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _exitSelectionMode,
            tooltip: '取消选择',
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBar,
            tooltip: '搜索',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: '设置',
          ),
        ],
      ],
    );
  }

  /// 构建主体内容
  Widget _buildBody() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error.isNotEmpty) {
          return _buildErrorWidget(provider.error);
        }

        if (provider.filteredDocuments.isEmpty) {
          return _buildEmptyWidget();
        }

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: _buildDocumentList(provider),
        );
      },
    );
  }

  /// 构建错误提示
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<DocumentProvider>().refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text('暂无证件照片', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('点击右下角按钮添加证件照片', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// 构建证件照片列表
  Widget _buildDocumentList(DocumentProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.filteredDocuments.length,
      itemBuilder: (context, index) {
        final document = provider.filteredDocuments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DocumentCard(
            document: document,
            isSelected: _selectedIds.contains(document.id),
            isSelectionMode: _isSelectionMode,
            onTap: () => _onDocumentTap(document),
            onLongPress: () => _onDocumentLongPress(document),
            onDelete: () => _showDeleteDialog(document.id),
          ),
        );
      },
    );
  }

  /// 构建浮动操作按钮
  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddDocumentDialog,
      icon: const Icon(Icons.add_a_photo),
      label: const Text('添加证件'),
    );
  }

  /// 显示搜索栏
  void _showSearchBar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SearchBarWidget(),
    );
  }

  /// 显示添加证件对话框
  void _showAddDocumentDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MultiPhotoAddScreen()),
    );
  }

  /// 证件点击事件
  void _onDocumentTap(IdDocument document) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedIds.contains(document.id)) {
          _selectedIds.remove(document.id);
        } else {
          _selectedIds.add(document.id);
        }
      });
    } else {
      // 导航到详情页面
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailScreen(documentId: document.id),
        ),
      );
    }
  }

  /// 证件长按事件
  void _onDocumentLongPress(IdDocument document) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.add(document.id);
      });
    }
  }

  /// 退出选择模式
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  /// 显示删除对话框
  void _showDeleteDialog([String? singleId]) {
    final ids = singleId != null ? [singleId] : _selectedIds;
    final count = ids.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除这$count张证件照片吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDocuments(ids);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 删除证件照片
  Future<void> _deleteDocuments(List<String> ids) async {
    final provider = context.read<DocumentProvider>();
    final success = await provider.batchDeleteDocuments(ids);

    if (success) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已删除${ids.length}张证件照片')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败')));
      }
    }
  }
}

/// 添加证件照片的底部表单
class AddDocumentSheet extends StatefulWidget {
  const AddDocumentSheet({super.key});

  @override
  State<AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<AddDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _documentTypeController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _notesController = TextEditingController();
  final List<String> _tags = [];

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

  @override
  void dispose() {
    _documentTypeController.dispose();
    _documentNumberController.dispose();
    _holderNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '添加证件照片',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _documentTypeController,
                  decoration: const InputDecoration(
                    labelText: '证件类型 *',
                    hintText: '如：身份证、护照、驾驶证',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
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
                  controller: _documentNumberController,
                  decoration: const InputDecoration(
                    labelText: '证件号码',
                    hintText: '证件上的编号',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _holderNameController,
                  decoration: const InputDecoration(
                    labelText: '持有人姓名',
                    hintText: '证件持有人姓名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '其他说明信息',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('拍照'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('相册'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 从相机拍照
  Future<void> _captureFromCamera() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DocumentProvider>();
    final success = await provider.captureFromCamera(
      documentType: _documentTypeController.text.trim(),
      documentNumber: _documentNumberController.text.trim().isEmpty
          ? null
          : _documentNumberController.text.trim(),
      holderName: _holderNameController.text.trim().isEmpty
          ? null
          : _holderNameController.text.trim(),
      tags: _tags,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('证件照片添加成功')));
    }
  }

  /// 从相册选择
  Future<void> _pickFromGallery() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<DocumentProvider>();
    final success = await provider.pickFromGallery(
      documentType: _documentTypeController.text.trim(),
      documentNumber: _documentNumberController.text.trim().isEmpty
          ? null
          : _documentNumberController.text.trim(),
      holderName: _holderNameController.text.trim().isEmpty
          ? null
          : _holderNameController.text.trim(),
      tags: _tags,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('证件照片添加成功')));
    }
  }
}
