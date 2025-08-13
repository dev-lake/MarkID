import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/document_service.dart';
import '../services/multi_photo_service.dart';
import '../screens/multi_photo_add_screen.dart';
import '../utils/app_initializer.dart';

/// 证件照片状态管理
class DocumentProvider extends ChangeNotifier {
  final DocumentService _service = DocumentService();
  final MultiPhotoService _photoService = MultiPhotoService();

  // 状态变量
  List<IdDocument> _documents = [];
  List<IdDocument> _filteredDocuments = [];
  bool _isLoading = false;
  String _error = '';
  String _searchQuery = '';
  String _selectedDocumentType = '';
  String _selectedTag = '';
  Map<String, dynamic> _stats = {};

  // Getters
  List<IdDocument> get documents => _documents;
  List<IdDocument> get filteredDocuments => _filteredDocuments;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get searchQuery => _searchQuery;
  String get selectedDocumentType => _selectedDocumentType;
  String get selectedTag => _selectedTag;
  Map<String, dynamic> get stats => _stats;

  /// 初始化数据
  Future<void> initialize() async {
    // 初始化应用（首次启动时添加范例数据）
    await AppInitializer.initializeApp();

    await loadDocuments();
    await loadStats();
  }

  /// 加载所有证件照片
  Future<void> loadDocuments() async {
    _setLoading(true);
    try {
      _documents = await _service.getAllDocuments();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('加载证件照片失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载统计信息
  Future<void> loadStats() async {
    try {
      _stats = await _service.getDocumentStats();
      notifyListeners();
    } catch (e) {
      print('加载统计信息失败: $e');
    }
  }

  /// 从相机拍照
  Future<bool> captureFromCamera({
    required String documentType,
    String? documentNumber,
    String? holderName,
    List<String>? tags,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final document = await _service.captureFromCamera(
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        tags: tags,
        notes: notes,
      );

      if (document != null) {
        _documents.insert(0, document);
        _applyFilters();
        await loadStats();
        _clearError();
        return true;
      } else {
        _setError('用户取消了拍照');
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString().contains('权限')
          ? '需要相机权限才能拍照，请在设置中开启相机权限'
          : '拍照失败: $e';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 从相册选择照片
  Future<bool> pickFromGallery({
    required String documentType,
    String? documentNumber,
    String? holderName,
    List<String>? tags,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final document = await _service.pickFromGallery(
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        tags: tags,
        notes: notes,
      );

      if (document != null) {
        _documents.insert(0, document);
        _applyFilters();
        await loadStats();
        _clearError();
        return true;
      } else {
        _setError('用户取消了选择');
        return false;
      }
    } catch (e) {
      final errorMessage = e.toString().contains('权限')
          ? '需要存储权限才能访问相册，请在设置中开启存储权限'
          : '选择照片失败: $e';
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新证件照片
  Future<bool> updateDocument(IdDocument document) async {
    _setLoading(true);
    try {
      final updatedDocument = await _service.updateDocument(document);
      if (updatedDocument != null) {
        final index = _documents.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          _documents[index] = updatedDocument;
          _applyFilters();
          _clearError();
          return true;
        }
      }
      _setError('更新失败');
      return false;
    } catch (e) {
      _setError('更新失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除证件照片
  Future<bool> deleteDocument(String id) async {
    _setLoading(true);
    try {
      final success = await _service.deleteDocument(id);
      if (success) {
        _documents.removeWhere((d) => d.id == id);
        _applyFilters();
        await loadStats();
        _clearError();
        return true;
      } else {
        _setError('删除失败');
        return false;
      }
    } catch (e) {
      _setError('删除失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 批量删除证件照片
  Future<bool> batchDeleteDocuments(List<String> ids) async {
    _setLoading(true);
    try {
      final success = await _service.batchDeleteDocuments(ids);
      if (success) {
        _documents.removeWhere((d) => ids.contains(d.id));
        _applyFilters();
        await loadStats();
        _clearError();
        return true;
      } else {
        _setError('批量删除失败');
        return false;
      }
    } catch (e) {
      _setError('批量删除失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 创建包含多张照片的证件
  Future<bool> createDocumentWithMultiplePhotos({
    required String documentType,
    String? documentNumber,
    String? holderName,
    required List<PhotoItem> photoItems,
    List<String>? tags,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final document = await _service.createDocumentWithMultiplePhotos(
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        photoItems: photoItems,
        tags: tags,
        notes: notes,
      );

      if (document != null) {
        _documents.insert(0, document);
        _applyFilters();
        await loadStats();
        _clearError();
        return true;
      } else {
        _setError('创建证件失败');
        return false;
      }
    } catch (e) {
      _setError('创建证件失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 设置搜索查询
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// 设置选中的证件类型
  void setSelectedDocumentType(String documentType) {
    _selectedDocumentType = documentType;
    _applyFilters();
  }

  /// 设置选中的标签
  void setSelectedTag(String tag) {
    _selectedTag = tag;
    _applyFilters();
  }

  /// 清除所有过滤器
  void clearFilters() {
    _searchQuery = '';
    _selectedDocumentType = '';
    _selectedTag = '';
    _applyFilters();
  }

  /// 应用过滤器
  void _applyFilters() {
    _filteredDocuments = _documents.where((document) {
      // 搜索查询过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch =
            document.documentType.toLowerCase().contains(query) ||
            (document.holderName?.toLowerCase().contains(query) ?? false) ||
            (document.documentNumber?.toLowerCase().contains(query) ?? false) ||
            (document.notes?.toLowerCase().contains(query) ?? false) ||
            document.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!matchesSearch) return false;
      }

      // 证件类型过滤
      if (_selectedDocumentType.isNotEmpty) {
        if (document.documentType != _selectedDocumentType) return false;
      }

      // 标签过滤
      if (_selectedTag.isNotEmpty) {
        if (!document.tags.contains(_selectedTag)) return false;
      }

      return true;
    }).toList();

    notifyListeners();
  }

  /// 获取证件类型列表
  List<String> getDocumentTypes() {
    final types = _documents.map((d) => d.documentType).toSet().toList();
    types.sort();
    return types;
  }

  /// 获取所有标签
  List<String> getAllTags() {
    final tags = <String>{};
    for (final document in _documents) {
      tags.addAll(document.tags);
    }
    return tags.toList()..sort();
  }

  /// 根据ID获取证件照片
  IdDocument? getDocumentById(String id) {
    try {
      return _documents.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取选中的证件照片
  List<IdDocument> getSelectedDocuments(List<String> ids) {
    return _documents.where((d) => ids.contains(d.id)).toList();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _error = '';
    notifyListeners();
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadDocuments();
    await loadStats();
  }

  // ==================== 多照片管理方法 ====================

  /// 为证件添加照片
  Future<bool> addPhotoToDocument({
    required String documentId,
    required String photoType,
    String? description,
  }) async {
    try {
      final photo = await _photoService.addPhotoToDocument(
        documentId: documentId,
        photoType: photoType,
        description: description,
      );

      if (photo != null) {
        // 更新本地数据
        final documentIndex = _documents.indexWhere((d) => d.id == documentId);
        if (documentIndex != -1) {
          final document = _documents[documentIndex];
          final updatedPhotos = List<DocumentPhoto>.from(document.photos)
            ..add(photo);
          _documents[documentIndex] = document.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('添加照片失败: $e');
      return false;
    }
  }

  /// 删除证件中的照片
  Future<bool> removePhotoFromDocument({
    required String documentId,
    required String photoId,
  }) async {
    try {
      final success = await _photoService.removePhotoFromDocument(
        documentId: documentId,
        photoId: photoId,
      );

      if (success) {
        // 更新本地数据
        final documentIndex = _documents.indexWhere((d) => d.id == documentId);
        if (documentIndex != -1) {
          final document = _documents[documentIndex];
          final updatedPhotos = document.photos
              .where((p) => p.id != photoId)
              .toList();
          _documents[documentIndex] = document.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('删除照片失败: $e');
      return false;
    }
  }

  /// 设置主照片
  Future<bool> setPrimaryPhoto({
    required String documentId,
    required String photoId,
  }) async {
    try {
      final success = await _photoService.setPrimaryPhoto(
        documentId: documentId,
        photoId: photoId,
      );

      if (success) {
        // 更新本地数据
        final documentIndex = _documents.indexWhere((d) => d.id == documentId);
        if (documentIndex != -1) {
          final document = _documents[documentIndex];
          final updatedPhotos = document.photos.map((photo) {
            return photo.copyWith(isPrimary: photo.id == photoId);
          }).toList();
          _documents[documentIndex] = document.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('设置主照片失败: $e');
      return false;
    }
  }

  /// 重新排序照片
  Future<bool> reorderPhotos({
    required String documentId,
    required List<String> photoIds,
  }) async {
    try {
      final success = await _photoService.reorderPhotos(
        documentId: documentId,
        photoIds: photoIds,
      );

      if (success) {
        // 更新本地数据
        final documentIndex = _documents.indexWhere((d) => d.id == documentId);
        if (documentIndex != -1) {
          final document = _documents[documentIndex];
          final photoMap = {
            for (final photo in document.photos) photo.id: photo,
          };
          final updatedPhotos = <DocumentPhoto>[];

          for (int i = 0; i < photoIds.length; i++) {
            final photo = photoMap[photoIds[i]];
            if (photo != null) {
              updatedPhotos.add(photo.copyWith(sortIndex: i));
            }
          }

          // 添加未包含在排序列表中的照片
          for (final photo in document.photos) {
            if (!photoIds.contains(photo.id)) {
              updatedPhotos.add(
                photo.copyWith(sortIndex: updatedPhotos.length),
              );
            }
          }

          _documents[documentIndex] = document.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('重新排序照片失败: $e');
      return false;
    }
  }

  /// 更新照片信息
  Future<bool> updatePhotoInfo({
    required String documentId,
    required String photoId,
    String? photoType,
    String? description,
  }) async {
    try {
      final success = await _photoService.updatePhotoInfo(
        documentId: documentId,
        photoId: photoId,
        photoType: photoType,
        description: description,
      );

      if (success) {
        // 更新本地数据
        final documentIndex = _documents.indexWhere((d) => d.id == documentId);
        if (documentIndex != -1) {
          final document = _documents[documentIndex];
          final updatedPhotos = document.photos.map((photo) {
            if (photo.id == photoId) {
              return photo.copyWith(
                photoType: photoType ?? photo.photoType,
                description: description ?? photo.description,
                updatedAt: DateTime.now(),
              );
            }
            return photo;
          }).toList();
          _documents[documentIndex] = document.copyWith(
            photos: updatedPhotos,
            updatedAt: DateTime.now(),
          );
          _applyFilters();
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _setError('更新照片信息失败: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
