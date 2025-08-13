import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';
import '../repositories/document_repository.dart';
import '../utils/permission_utils.dart';
import '../screens/multi_photo_add_screen.dart';

/// 证件照片业务逻辑层
class DocumentService {
  final DocumentRepository _repository = DocumentRepository();
  final ImagePicker _imagePicker = ImagePicker();

  /// 从相机拍照
  Future<IdDocument?> captureFromCamera({
    required String documentType,
    String? documentNumber,
    String? holderName,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      // 检查相机权限
      final status = await PermissionUtils.checkCameraPermission();
      if (!status) {
        throw Exception('相机权限被拒绝');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      return await _processImage(
        image,
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        tags: tags,
        notes: notes,
      );
    } catch (e) {
      print('拍照失败: $e');
      rethrow;
    }
  }

  /// 从相册选择照片
  Future<IdDocument?> pickFromGallery({
    required String documentType,
    String? documentNumber,
    String? holderName,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      // 检查存储权限
      final status = await PermissionUtils.checkStoragePermission();
      if (!status) {
        throw Exception('存储权限被拒绝');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image == null) return null;

      return await _processImage(
        image,
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        tags: tags,
        notes: notes,
      );
    } catch (e) {
      print('选择照片失败: $e');
      rethrow;
    }
  }

  /// 处理图片文件
  Future<IdDocument> _processImage(
    XFile image, {
    required String documentType,
    String? documentNumber,
    String? holderName,
    List<String>? tags,
    String? notes,
  }) async {
    // 读取图片数据
    final Uint8List imageData = await image.readAsBytes();

    // 获取图片信息
    final img.Image? decodedImage = img.decodeImage(imageData);
    if (decodedImage == null) {
      throw Exception('无法解码图片');
    }

    // 生成文件名
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

    // 保存原图
    final String originalPath = await _repository.saveImageFile(
      imageData,
      fileName,
    );

    // 生成缩略图
    final String? thumbnailPath = await _repository.generateThumbnail(
      originalPath,
      fileName,
    );

    // 创建照片对象
    final DocumentPhoto photo = DocumentPhoto(
      photoType: '正面',
      description: '证件正面照片',
      originalImagePath: originalPath,
      thumbnailPath: thumbnailPath,
      fileSize: imageData.length,
      width: decodedImage.width,
      height: decodedImage.height,
      sortIndex: 0,
      isPrimary: true,
    );

    // 创建证件对象
    final IdDocument document = IdDocument(
      documentType: documentType,
      documentNumber: documentNumber,
      holderName: holderName,
      photos: [photo],
      tags: tags ?? [],
      notes: notes,
    );

    // 保存到数据库
    return await _repository.addDocument(document);
  }

  /// 获取所有证件照片
  Future<List<IdDocument>> getAllDocuments() async {
    return await _repository.getAllDocuments();
  }

  /// 根据类型获取证件照片
  Future<List<IdDocument>> getDocumentsByType(String documentType) async {
    return await _repository.getDocumentsByType(documentType);
  }

  /// 搜索证件照片
  Future<List<IdDocument>> searchDocuments(String query) async {
    if (query.trim().isEmpty) {
      return await getAllDocuments();
    }
    return await _repository.searchDocuments(query.trim());
  }

  /// 根据标签获取证件照片
  Future<List<IdDocument>> getDocumentsByTag(String tag) async {
    return await _repository.getDocumentsByTag(tag);
  }

  /// 更新证件照片信息
  Future<IdDocument?> updateDocument(IdDocument document) async {
    try {
      return await _repository.updateDocument(document);
    } catch (e) {
      print('更新证件照片失败: $e');
      return null;
    }
  }

  /// 删除证件照片
  Future<bool> deleteDocument(String id) async {
    try {
      // await _repository.deleteDocument(id);
      await _repository.permanentlyDeleteDocument(id);
      return true;
    } catch (e) {
      print('删除证件照片失败: $e');
      return false;
    }
  }

  /// 永久删除证件照片
  Future<bool> permanentlyDeleteDocument(String id) async {
    try {
      await _repository.permanentlyDeleteDocument(id);
      return true;
    } catch (e) {
      print('永久删除证件照片失败: $e');
      return false;
    }
  }

  /// 批量删除证件照片
  Future<bool> batchDeleteDocuments(List<String> ids) async {
    try {
      await _repository.batchDeleteDocuments(ids);
      return true;
    } catch (e) {
      print('批量删除证件照片失败: $e');
      return false;
    }
  }

  /// 批量更新标签
  Future<bool> batchUpdateTags(List<String> ids, List<String> tags) async {
    try {
      await _repository.batchUpdateTags(ids, tags);
      return true;
    } catch (e) {
      print('批量更新标签失败: $e');
      return false;
    }
  }

  /// 获取证件照片统计信息
  Future<Map<String, dynamic>> getDocumentStats() async {
    return await _repository.getDocumentStats();
  }

  /// 获取证件类型列表
  Future<List<String>> getDocumentTypes() async {
    final stats = await getDocumentStats();
    final typeStats = stats['typeStats'] as List;
    return typeStats.map((stat) => stat['documentType'] as String).toList();
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    final documents = await getAllDocuments();
    final Set<String> tags = {};

    for (final document in documents) {
      tags.addAll(document.tags);
    }

    return tags.toList()..sort();
  }

  /// 验证证件照片信息
  bool validateDocumentInfo({
    required String documentType,
    String? documentNumber,
    String? holderName,
  }) {
    if (documentType.trim().isEmpty) {
      return false;
    }

    // 可以根据需要添加更多验证规则
    // 例如：证件号码格式验证、姓名长度验证等

    return true;
  }

  /// 获取文件大小的人类可读格式
  String getFileSizeFormatted(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// 获取文件信息
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final imageData = await file.readAsBytes();
      final image = img.decodeImage(imageData);

      return {
        'size': stat.size,
        'modified': stat.modified,
        'width': image?.width,
        'height': image?.height,
        'exists': true,
      };
    } catch (e) {
      print('获取文件信息失败: $e');
      return null;
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    await _repository.close();
  }

  /// 获取所有导出记录
  Future<List<ExportRecord>> getAllExportRecords() async {
    try {
      return await _repository.getAllExportRecords();
    } catch (e) {
      print('获取导出记录失败: $e');
      return [];
    }
  }

  /// 获取安全配置
  Future<SecurityConfig> getSecurityConfig() async {
    try {
      return await _repository.getSecurityConfig();
    } catch (e) {
      print('获取安全配置失败: $e');
      return SecurityConfig.defaultConfig();
    }
  }

  /// 保存安全配置
  Future<void> saveSecurityConfig(SecurityConfig config) async {
    try {
      await _repository.saveSecurityConfig(config);
    } catch (e) {
      print('保存安全配置失败: $e');
    }
  }

  /// 获取水印配置
  Future<WatermarkConfig> getWatermarkConfig() async {
    try {
      return await _repository.getWatermarkConfig();
    } catch (e) {
      print('获取水印配置失败: $e');
      return WatermarkConfig.defaultVisible();
    }
  }

  /// 保存水印配置
  Future<void> saveWatermarkConfig(WatermarkConfig config) async {
    try {
      await _repository.saveWatermarkConfig(config);
    } catch (e) {
      print('保存水印配置失败: $e');
    }
  }

  /// 恢复文档数据
  Future<void> restoreDocuments(List<IdDocument> documents) async {
    try {
      await _repository.restoreDocuments(documents);
    } catch (e) {
      print('恢复文档数据失败: $e');
    }
  }

  /// 恢复导出记录
  Future<void> restoreExportRecords(List<ExportRecord> records) async {
    try {
      await _repository.restoreExportRecords(records);
    } catch (e) {
      print('恢复导出记录失败: $e');
    }
  }

  /// 创建包含多张照片的证件
  Future<IdDocument?> createDocumentWithMultiplePhotos({
    required String documentType,
    String? documentNumber,
    String? holderName,
    required List<PhotoItem> photoItems,
    List<String>? tags,
    String? notes,
  }) async {
    try {
      final List<DocumentPhoto> photos = [];

      for (int i = 0; i < photoItems.length; i++) {
        final photoItem = photoItems[i];
        if (photoItem.imageData != null) {
          // 生成文件名
          final String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${i}_${photoItem.photoType}.png';

          // 保存原图
          final String originalPath = await _repository.saveImageFile(
            photoItem.imageData!,
            fileName,
          );

          // 生成缩略图
          final String? thumbnailPath = await _repository.generateThumbnail(
            originalPath,
            fileName,
          );

          // 获取图片信息
          final img.Image? decodedImage = img.decodeImage(photoItem.imageData!);

          // 创建照片对象
          final DocumentPhoto photo = DocumentPhoto(
            photoType: photoItem.photoType,
            description: photoItem.description,
            originalImagePath: originalPath,
            thumbnailPath: thumbnailPath,
            fileSize: photoItem.imageData!.length,
            width: decodedImage?.width ?? 0,
            height: decodedImage?.height ?? 0,
            sortIndex: i,
            isPrimary: i == 0, // 第一张照片为主照片
          );

          photos.add(photo);
        }
      }

      if (photos.isEmpty) {
        throw Exception('没有有效的照片');
      }

      // 创建证件对象
      final IdDocument document = IdDocument(
        documentType: documentType,
        documentNumber: documentNumber,
        holderName: holderName,
        photos: photos,
        tags: tags ?? [],
        notes: notes,
      );

      // 保存到数据库
      return await _repository.addDocument(document);
    } catch (e) {
      print('创建多照片证件失败: $e');
      rethrow;
    }
  }
}
