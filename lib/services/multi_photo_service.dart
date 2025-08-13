import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';
import '../repositories/document_repository.dart';
import '../utils/permission_utils.dart';

/// 多张照片管理服务
class MultiPhotoService {
  final DocumentRepository _repository = DocumentRepository();
  final ImagePicker imagePicker = ImagePicker();

  /// 为证件添加单张照片
  Future<DocumentPhoto?> addPhotoToDocument({
    required String documentId,
    required String photoType,
    String? description,
    ImageSource source = ImageSource.camera,
  }) async {
    try {
      // 检查权限
      if (source == ImageSource.camera) {
        final status = await PermissionUtils.checkCameraPermission();
        if (!status) {
          throw Exception('相机权限被拒绝');
        }
      } else {
        final status = await PermissionUtils.checkStoragePermission();
        if (!status) {
          throw Exception('存储权限被拒绝');
        }
      }

      // 选择照片
      final XFile? image = await imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null) return null;

      // 处理照片
      final photo = await _processPhoto(
        image,
        photoType: photoType,
        description: description,
      );

      // 添加到证件
      return await _addPhotoToDocument(documentId, photo);
    } catch (e) {
      print('添加照片失败: $e');
      rethrow;
    }
  }

  /// 批量添加照片到证件
  Future<List<DocumentPhoto>> addMultiplePhotosToDocument({
    required String documentId,
    required List<Map<String, dynamic>> photoConfigs,
  }) async {
    try {
      final List<DocumentPhoto> addedPhotos = [];

      for (final config in photoConfigs) {
        final photo = await addPhotoToDocument(
          documentId: documentId,
          photoType: config['photoType'],
          description: config['description'],
          source: config['source'] ?? ImageSource.camera,
        );

        if (photo != null) {
          addedPhotos.add(photo);
        }
      }

      return addedPhotos;
    } catch (e) {
      print('批量添加照片失败: $e');
      rethrow;
    }
  }

  /// 处理单张照片
  Future<DocumentPhoto> _processPhoto(
    XFile image, {
    required String photoType,
    String? description,
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
    return DocumentPhoto(
      photoType: photoType,
      description: description,
      originalImagePath: originalPath,
      thumbnailPath: thumbnailPath,
      fileSize: imageData.length,
      width: decodedImage.width,
      height: decodedImage.height,
    );
  }

  /// 将照片添加到证件
  Future<DocumentPhoto> _addPhotoToDocument(
    String documentId,
    DocumentPhoto photo,
  ) async {
    // 获取证件
    final document = await _repository.getDocumentById(documentId);
    if (document == null) {
      throw Exception('证件不存在');
    }

    // 确定照片的排序索引
    final int nextSortIndex = document.photos.length;

    // 如果是第一张照片，设为主照片
    final bool isPrimary = document.photos.isEmpty;

    // 创建新的照片对象
    final newPhoto = photo.copyWith(
      sortIndex: nextSortIndex,
      isPrimary: isPrimary,
    );

    // 添加到证件
    final updatedPhotos = List<DocumentPhoto>.from(document.photos)
      ..add(newPhoto);
    final updatedDocument = document.copyWith(
      photos: updatedPhotos,
      updatedAt: DateTime.now(),
    );

    // 保存到数据库
    await _repository.updateDocument(updatedDocument);

    return newPhoto;
  }

  /// 删除证件中的照片
  Future<bool> removePhotoFromDocument({
    required String documentId,
    required String photoId,
  }) async {
    try {
      // 获取证件
      final document = await _repository.getDocumentById(documentId);
      if (document == null) {
        throw Exception('证件不存在');
      }

      // 找到要删除的照片
      final photoIndex = document.photos.indexWhere(
        (photo) => photo.id == photoId,
      );
      if (photoIndex == -1) {
        throw Exception('照片不存在');
      }

      final photoToDelete = document.photos[photoIndex];

      // 删除照片文件
      await _repository.deleteImageFile(photoToDelete.originalImagePath);
      if (photoToDelete.thumbnailPath != null) {
        await _repository.deleteImageFile(photoToDelete.thumbnailPath!);
      }

      // 从证件中移除照片
      final updatedPhotos = List<DocumentPhoto>.from(document.photos);
      updatedPhotos.removeAt(photoIndex);

      // 重新排序剩余照片
      for (int i = 0; i < updatedPhotos.length; i++) {
        updatedPhotos[i] = updatedPhotos[i].copyWith(sortIndex: i);
      }

      // 如果删除的是主照片，将第一张照片设为主照片
      if (photoToDelete.isPrimary && updatedPhotos.isNotEmpty) {
        updatedPhotos[0] = updatedPhotos[0].copyWith(isPrimary: true);
      }

      // 更新证件
      final updatedDocument = document.copyWith(
        photos: updatedPhotos,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDocument(updatedDocument);
      return true;
    } catch (e) {
      print('删除照片失败: $e');
      return false;
    }
  }

  /// 设置主照片
  Future<bool> setPrimaryPhoto({
    required String documentId,
    required String photoId,
  }) async {
    try {
      // 获取证件
      final document = await _repository.getDocumentById(documentId);
      if (document == null) {
        throw Exception('证件不存在');
      }

      // 更新照片的主照片状态
      final updatedPhotos = document.photos.map((photo) {
        return photo.copyWith(isPrimary: photo.id == photoId);
      }).toList();

      // 更新证件
      final updatedDocument = document.copyWith(
        photos: updatedPhotos,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDocument(updatedDocument);
      return true;
    } catch (e) {
      print('设置主照片失败: $e');
      return false;
    }
  }

  /// 重新排序照片
  Future<bool> reorderPhotos({
    required String documentId,
    required List<String> photoIds,
  }) async {
    try {
      // 获取证件
      final document = await _repository.getDocumentById(documentId);
      if (document == null) {
        throw Exception('证件不存在');
      }

      // 创建照片ID到照片的映射
      final Map<String, DocumentPhoto> photoMap = {
        for (final photo in document.photos) photo.id: photo,
      };

      // 按新顺序重新排序照片
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
          updatedPhotos.add(photo.copyWith(sortIndex: updatedPhotos.length));
        }
      }

      // 更新证件
      final updatedDocument = document.copyWith(
        photos: updatedPhotos,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDocument(updatedDocument);
      return true;
    } catch (e) {
      print('重新排序照片失败: $e');
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
      // 获取证件
      final document = await _repository.getDocumentById(documentId);
      if (document == null) {
        throw Exception('证件不存在');
      }

      // 更新照片信息
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

      // 更新证件
      final updatedDocument = document.copyWith(
        photos: updatedPhotos,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDocument(updatedDocument);
      return true;
    } catch (e) {
      print('更新照片信息失败: $e');
      return false;
    }
  }

  /// 获取证件照片统计信息
  Map<String, dynamic> getPhotoStats(List<DocumentPhoto> photos) {
    final totalSize = photos.fold<int>(0, (sum, photo) => sum + photo.fileSize);
    final photoTypes = photos.map((photo) => photo.photoType).toSet();
    final primaryPhoto = photos.where((photo) => photo.isPrimary).firstOrNull;

    return {
      'totalPhotos': photos.length,
      'totalSize': totalSize,
      'photoTypes': photoTypes.toList(),
      'hasPrimaryPhoto': primaryPhoto != null,
      'primaryPhotoType': primaryPhoto?.photoType,
    };
  }
}
