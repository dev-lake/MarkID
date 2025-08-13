import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_utils.dart';

/// 权限检查页面
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Map<String, bool> _permissions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  /// 检查所有权限
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final permissions = await PermissionUtils.checkAllPermissions();
      setState(() {
        _permissions = permissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: '刷新权限状态',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPermissionList(),
    );
  }

  /// 构建权限列表
  Widget _buildPermissionList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPermissionCard(
          '相机权限',
          '用于拍摄证件照片',
          Icons.camera_alt,
          _permissions['camera'] ?? false,
          () => _requestPermission('camera'),
        ),
        const SizedBox(height: 12),
        _buildPermissionCard(
          '存储权限',
          '用于访问和保存照片文件',
          Icons.storage,
          _permissions['storage'] ?? false,
          () => _requestPermission('storage'),
        ),
        const SizedBox(height: 12),
        _buildPermissionCard(
          '照片库权限',
          '用于从相册选择照片',
          Icons.photo_library,
          _permissions['photos'] ?? false,
          () => _requestPermission('photos'),
        ),
        const SizedBox(height: 24),
        _buildInfoCard(),
      ],
    );
  }

  /// 构建权限卡片
  Widget _buildPermissionCard(
    String title,
    String description,
    IconData icon,
    bool isGranted,
    VoidCallback onRequest,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: isGranted ? Colors.green : Colors.grey,
          size: 32,
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isGranted ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            isGranted ? '已授权' : '未授权',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: isGranted ? null : onRequest,
      ),
    );
  }

  /// 构建信息卡片
  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  '权限说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• 相机权限：用于拍摄证件照片\n'
              '• 存储权限：用于保存和管理照片文件\n'
              '• 照片库权限：用于从相册选择照片\n\n'
              '如果权限被拒绝，请点击相应权限卡片重新申请，'
              '或在系统设置中手动开启权限。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 请求权限
  Future<void> _requestPermission(String permissionType) async {
    bool granted = false;

    switch (permissionType) {
      case 'camera':
        granted = await PermissionUtils.checkCameraPermission();
        break;
      case 'storage':
        granted = await PermissionUtils.checkStoragePermission();
        break;
      case 'photos':
        granted = await PermissionUtils.checkPhotosPermission();
        break;
    }

    if (granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$permissionType 权限已授权'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$permissionType 权限被拒绝'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: '去设置',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }

    // 刷新权限状态
    await _checkPermissions();
  }
}
