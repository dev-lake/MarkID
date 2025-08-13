import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/backup_provider.dart';
import '../utils/permission_utils.dart';
import 'permission_screen.dart';
import 'icloud_sync_screen.dart';
import 'backup_settings_screen.dart';

/// 统一设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  /// 格式化备份时间
  String _formatBackupTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
            tooltip: '刷新状态',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSettingsList(),
    );
  }

  /// 构建设置列表
  Widget _buildSettingsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('权限管理'),
        _buildPermissionSection(),
        const SizedBox(height: 24),
        _buildSectionHeader('数据同步'),
        _buildSyncSection(),
        const SizedBox(height: 24),
        _buildSectionHeader('安全设置'),
        _buildSecuritySection(),
        const SizedBox(height: 24),
        _buildSectionHeader('应用信息'),
        _buildAppInfoSection(),
      ],
    );
  }

  /// 构建分区标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 构建权限管理部分
  Widget _buildPermissionSection() {
    final allGranted = _permissions.values.every((granted) => granted);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.security,
              color: allGranted ? Colors.green : Colors.orange,
            ),
            title: const Text('应用权限'),
            subtitle: Text(allGranted ? '所有权限已授权' : '部分权限未授权'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: allGranted ? Colors.green : Colors.orange,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                allGranted ? '正常' : '需处理',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _navigateToPermissionScreen(),
          ),
          if (!allGranted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '未授权权限：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._buildPermissionStatusList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建权限状态列表
  List<Widget> _buildPermissionStatusList() {
    final List<Widget> widgets = [];

    if (!(_permissions['camera'] ?? false)) {
      widgets.add(_buildPermissionStatusItem('相机权限', Icons.camera_alt));
    }
    if (!(_permissions['storage'] ?? false)) {
      widgets.add(_buildPermissionStatusItem('存储权限', Icons.storage));
    }
    if (!(_permissions['photos'] ?? false)) {
      widgets.add(_buildPermissionStatusItem('照片库权限', Icons.photo_library));
    }

    return widgets;
  }

  /// 构建权限状态项
  Widget _buildPermissionStatusItem(String permission, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(
            permission,
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
        ],
      ),
    );
  }

  /// 构建同步部分
  Widget _buildSyncSection() {
    return Card(
      child: Column(
        children: [
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              final syncStatus = syncProvider.getSyncStatusDescription();
              final isSyncing = syncProvider.isSyncing;

              return ListTile(
                leading: Icon(
                  Icons.cloud_sync,
                  color: isSyncing ? Colors.blue : Colors.green,
                ),
                title: const Text('iCloud 同步'),
                subtitle: Text(isSyncing ? '同步中...' : syncStatus),
                trailing: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: isSyncing ? null : () => _navigateToSyncScreen(),
              );
            },
          ),
          const Divider(height: 1),
          // Consumer<BackupProvider>(
          //   builder: (context, backupProvider, child) {
          //     final backupStats = backupProvider.getBackupStats();
          //     final lastBackup = backupStats['lastBackup'];

          //     return ListTile(
          //       leading: const Icon(Icons.backup),
          //       title: const Text('备份设置'),
          //       subtitle: Text(
          //         lastBackup != null
          //             ? '上次备份：${_formatBackupTime(lastBackup.timestamp)}'
          //             : '未进行备份',
          //       ),
          //       trailing: const Icon(Icons.chevron_right),
          //       onTap: () => _navigateToBackupScreen(),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  /// 构建安全设置部分
  Widget _buildSecuritySection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('生物识别'),
            subtitle: const Text('指纹、面容 ID 解锁'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showSecuritySettings(),
          ),
          // const Divider(height: 1),
          // ListTile(
          //   leading: const Icon(Icons.lock),
          //   title: const Text('加密设置'),
          //   subtitle: const Text('数据加密配置'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => _showEncryptionSettings(),
          // ),
          // const Divider(height: 1),
          // ListTile(
          //   leading: const Icon(Icons.water_drop),
          //   title: const Text('水印设置'),
          //   subtitle: const Text('导出水印配置'),
          //   trailing: const Icon(Icons.chevron_right),
          //   onTap: () => _showWatermarkSettings(),
          // ),
        ],
      ),
    );
  }

  /// 构建应用信息部分
  Widget _buildAppInfoSection() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于应用'),
            subtitle: const Text('版本信息、使用说明'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutApp(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('隐私政策'),
            subtitle: const Text('数据使用说明'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPrivacyPolicy(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助与反馈'),
            subtitle: const Text('常见问题、联系支持'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHelpAndFeedback(),
          ),
        ],
      ),
    );
  }

  /// 导航到权限管理页面
  void _navigateToPermissionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PermissionScreen()),
    ).then((_) => _checkPermissions());
  }

  /// 导航到同步设置页面
  void _navigateToSyncScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ICloudSyncScreen()),
    );
  }

  /// 导航到备份设置页面
  void _navigateToBackupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackupSettingsScreen()),
    );
  }

  /// 显示安全设置
  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生物识别设置'),
        content: const Text('生物识别功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示加密设置
  void _showEncryptionSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加密设置'),
        content: const Text('数据加密配置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示水印设置
  void _showWatermarkSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('水印设置'),
        content: const Text('水印配置功能正在开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于应用
  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 MarkID'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text('一款安全的证件照片管理应用'),
            SizedBox(height: 8),
            Text('• 本地加密存储\n• 水印保护\n• iCloud 同步\n• 生物识别解锁'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示隐私政策
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Text(
            'MarkID 隐私政策\n\n'
            '1. 数据存储：所有照片数据仅存储在您的设备本地\n'
            '2. 加密保护：使用 AES 加密保护您的数据\n'
            '3. 云端同步：可选择使用 iCloud 进行数据同步\n'
            '4. 权限使用：仅使用必要的相机、存储和照片库权限\n'
            '5. 数据收集：我们不会收集您的个人信息\n\n'
            '更多详细信息请访问我们的官方网站。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示帮助与反馈
  void _showHelpAndFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('帮助与反馈'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('常见问题：'),
            SizedBox(height: 8),
            Text('• 如何导入照片？\n• 如何设置水印？\n• 如何同步数据？\n• 如何备份数据？'),
            SizedBox(height: 16),
            Text('联系我们：'),
            SizedBox(height: 8),
            Text('support@markid.app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
