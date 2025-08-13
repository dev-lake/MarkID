import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

/// 搜索栏组件
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<DocumentProvider>().searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '搜索证件照片',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: '搜索证件类型、姓名、号码或备注...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                  onSubmitted: (_) => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _performSearch,
                        child: const Text('搜索'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildSearchSuggestions(),
        ],
      ),
    );
  }

  /// 构建搜索建议
  Widget _buildSearchSuggestions() {
    return Consumer<DocumentProvider>(
      builder: (context, provider, child) {
        if (_searchController.text.isEmpty) {
          return _buildRecentSearches();
        }

        final suggestions = _getSearchSuggestions(provider);
        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(suggestion),
                onTap: () {
                  _searchController.text = suggestion;
                  _performSearch();
                },
              );
            },
          ),
        );
      },
    );
  }

  /// 构建最近搜索
  Widget _buildRecentSearches() {
    // 这里可以从本地存储获取最近搜索记录
    final recentSearches = ['身份证', '护照', '驾驶证'];

    if (recentSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近搜索', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                  _performSearch();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 获取搜索建议
  List<String> _getSearchSuggestions(DocumentProvider provider) {
    final query = _searchController.text.toLowerCase();
    final suggestions = <String>{};

    // 从证件类型中获取建议
    for (final document in provider.documents) {
      if (document.documentType.toLowerCase().contains(query)) {
        suggestions.add(document.documentType);
      }
      if (document.holderName?.toLowerCase().contains(query) ?? false) {
        suggestions.add(document.holderName!);
      }
      if (document.documentNumber?.toLowerCase().contains(query) ?? false) {
        suggestions.add(document.documentNumber!);
      }
      for (final tag in document.tags) {
        if (tag.toLowerCase().contains(query)) {
          suggestions.add(tag);
        }
      }
    }

    return suggestions.take(5).toList();
  }

  /// 搜索内容变化
  void _onSearchChanged(String value) {
    context.read<DocumentProvider>().setSearchQuery(value);
  }

  /// 执行搜索
  void _performSearch() {
    Navigator.of(context).pop();
  }

  /// 清除搜索
  void _clearSearch() {
    _searchController.clear();
    context.read<DocumentProvider>().setSearchQuery('');
  }
}
