import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

/// 过滤抽屉组件
class FilterDrawer extends StatelessWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDocumentTypeFilter(context, provider),
                    const Divider(),
                    _buildTagFilter(context, provider),
                    const Divider(),
                    _buildActions(context, provider),
                  ],
                ),
              ),
              _buildStatsSection(context, provider),
            ],
          );
        },
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.filter_list, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            '过滤和统计',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            '按条件筛选证件照片',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  /// 构建统计部分
  Widget _buildStatsSection(BuildContext context, DocumentProvider provider) {
    final stats = provider.stats;
    final totalCount = stats['totalCount'] as int? ?? 0;
    final totalSize = stats['totalSize'] as int? ?? 0;
    final filteredCount = provider.filteredDocuments.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text('统计信息', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatItem(context, Icons.photo_library, '总数量', '$totalCount 张'),
          const SizedBox(height: 8),
          _buildStatItem(
            context,
            Icons.filter_list,
            '当前显示',
            '$filteredCount 张',
          ),
          const SizedBox(height: 8),
          _buildStatItem(
            context,
            Icons.storage,
            '总大小',
            _formatFileSize(totalSize),
          ),
        ],
      ),
    );
  }

  /// 构建证件类型过滤
  Widget _buildDocumentTypeFilter(
    BuildContext context,
    DocumentProvider provider,
  ) {
    final documentTypes = provider.getDocumentTypes();
    final selectedType = provider.selectedDocumentType;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category),
              const SizedBox(width: 8),
              Text('证件类型', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (documentTypes.isEmpty)
            const Text('暂无证件类型', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: selectedType.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      provider.setSelectedDocumentType('');
                    }
                  },
                ),
                ...documentTypes.map((type) {
                  return FilterChip(
                    label: Text(type),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      provider.setSelectedDocumentType(selected ? type : '');
                    },
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建标签过滤
  Widget _buildTagFilter(BuildContext context, DocumentProvider provider) {
    final tags = provider.getAllTags();
    final selectedTag = provider.selectedTag;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.label),
              const SizedBox(width: 8),
              Text('标签', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          if (tags.isEmpty)
            const Text('暂无标签', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: selectedTag.isEmpty,
                  onSelected: (selected) {
                    if (selected) {
                      provider.setSelectedTag('');
                    }
                  },
                ),
                ...tags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: selectedTag == tag,
                    onSelected: (selected) {
                      provider.setSelectedTag(selected ? tag : '');
                    },
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActions(BuildContext context, DocumentProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              provider.clearFilters();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('清除所有过滤'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              provider.refresh();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('刷新数据'),
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  /// 格式化文件大小
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
