import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// 权限检查工具类
class PermissionUtils {
  /// 检查相机权限
  static Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) {
        debugPrint('相机权限已授权');
        return true;
      }

      if (status.isDenied) {
        debugPrint('相机权限已拒绝');
        final result = await Permission.camera.request();
        debugPrint('相机权限请求结果: ${result.isGranted}');
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置页面
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      print('检查相机权限失败: $e');
      return false;
    }
  }

  /// 检查存储权限
  static Future<bool> checkStoragePermission() async {
    try {
      final status = await Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置页面
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      print('检查存储权限失败: $e');
      return false;
    }
  }

  /// 检查照片库权限（iOS）
  static Future<bool> checkPhotosPermission() async {
    try {
      final status = await Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置页面
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      print('检查照片库权限失败: $e');
      return false;
    }
  }

  /// 获取权限状态描述
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '已拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '有限权限';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授权';
      default:
        return '未知状态';
    }
  }

  /// 检查所有必要权限
  static Future<Map<String, bool>> checkAllPermissions() async {
    final results = <String, bool>{};

    results['camera'] = await checkCameraPermission();
    results['storage'] = await checkStoragePermission();
    results['photos'] = await checkPhotosPermission();

    return results;
  }
}
