import 'dart:io';
import 'package:flutter/foundation.dart';

/// 图片调试工具类
class ImageDebugUtils {
  /// 检查图片文件是否存在并可访问
  static Future<Map<String, dynamic>> debugImageFile(String imagePath) async {
    final result = <String, dynamic>{
      'path': imagePath,
      'exists': false,
      'readable': false,
      'size': 0,
      'error': null,
    };

    try {
      final file = File(imagePath);

      // 检查文件是否存在
      result['exists'] = await file.exists();

      if (result['exists']) {
        // 检查文件是否可读
        try {
          final stat = await file.stat();
          result['size'] = stat.size;
          result['readable'] = true;

          // 尝试读取文件头来验证是否为有效图片
          final bytes = await file.openRead(0, 8).first;
          result['isValidImage'] = _isValidImageHeader(bytes);
        } catch (e) {
          result['error'] = '文件读取失败: $e';
        }
      } else {
        result['error'] = '文件不存在';
      }
    } catch (e) {
      result['error'] = '路径解析失败: $e';
    }

    if (kDebugMode) {
      print('图片调试信息: $result');
    }

    return result;
  }

  /// 检查是否为有效的图片文件头
  static bool _isValidImageHeader(List<int> bytes) {
    if (bytes.length < 8) return false;

    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return true;

    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47)
      return true;

    // GIF
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;

    // WebP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50)
      return true;

    return false;
  }

  /// 获取图片文件的人类可读信息
  static String getImageFileInfo(Map<String, dynamic> debugInfo) {
    final path = debugInfo['path'] as String;
    final exists = debugInfo['exists'] as bool;
    final size = debugInfo['size'] as int;
    final error = debugInfo['error'] as String?;

    if (!exists) {
      return '文件不存在: $path';
    }

    if (error != null) {
      return '文件错误: $error';
    }

    final sizeStr = _formatFileSize(size);
    final isValid = debugInfo['isValidImage'] as bool? ?? false;

    return '文件存在: $path\n大小: $sizeStr\n有效图片: ${isValid ? "是" : "否"}';
  }

  /// 获取图片文件对象
  static Future<File?> getImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('获取图片文件失败: $e');
      }
      return null;
    }
  }

  /// 格式化文件大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 检查网络图片URL是否有效
  static bool isValidNetworkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 获取图片类型
  static String getImageType(String imagePath) {
    if (imagePath.startsWith('http')) {
      return '网络图片';
    } else {
      final extension = imagePath.split('.').last.toLowerCase();
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return 'JPEG图片';
        case 'png':
          return 'PNG图片';
        case 'gif':
          return 'GIF图片';
        case 'webp':
          return 'WebP图片';
        default:
          return '未知格式';
      }
    }
  }
}
