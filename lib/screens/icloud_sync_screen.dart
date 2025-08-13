import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

/// iCloud 同步设置界面
class ICloudSyncScreen extends StatefulWidget {
  const ICloudSyncScreen({super.key});

  @override
  State<ICloudSyncScreen> createState() => _ICloudSyncScreenState();
}

class _ICloudSyncScreenState extends State<ICloudSyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iCloud 同步'),
        actions: [
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              if (syncProvider.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SyncProvider>(
        builder: (context, syncProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSyncStatusCard(syncProvider),
                const SizedBox(height: 16),
                _buildSyncOptionsCard(syncProvider),
                const SizedBox(height: 16),
                _buildSyncActionsCard(syncProvider),
                const SizedBox(height: 16),
                _buildSyncInfoCard(syncProvider),
                const SizedBox(height: 32),
                _buildActionButtons(syncProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 同步状态卡片
  Widget _buildSyncStatusCard(SyncProvider syncProvider) {
    final stats = syncProvider.getSyncStats();
    final statusIcon = syncProvider.getSyncStatusIcon();
    final statusDescription = syncProvider.getSyncStatusDescription();
    final lastSyncTime = syncProvider.getLastSyncTimeFormatted();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  statusIcon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '同步状态',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        statusDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text(
                  '最后同步: $lastSyncTime',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (syncProvider.hasCloudUpdates) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.cloud_download,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    '云端有更新可用',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
            if (stats['hasError'] == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.error, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '错误: ${stats['errorMessage'] ?? '未知错误'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 同步选项卡片
  Widget _buildSyncOptionsCard(SyncProvider syncProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '同步选项',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用 iCloud 同步'),
              subtitle: const Text('自动同步数据到 iCloud'),
              value: syncProvider.isEnabled,
              onChanged: (value) {
                syncProvider.setEnabled(value);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('同步内容'),
              subtitle: const Text('证件数据、导出记录、配置信息'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showSyncContentDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 同步操作卡片
  Widget _buildSyncActionsCard(SyncProvider syncProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '同步操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('上传到 iCloud'),
              subtitle: const Text('将本地数据同步到云端'),
              onTap: syncProvider.isSyncing
                  ? null
                  : () {
                      syncProvider.syncToICloud();
                    },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('从 iCloud 下载'),
              subtitle: const Text('从云端同步数据到本地'),
              onTap: syncProvider.isSyncing
                  ? null
                  : () {
                      syncProvider.syncFromICloud();
                    },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('双向同步'),
              subtitle: const Text('上传并下载最新数据'),
              onTap: syncProvider.isSyncing
                  ? null
                  : () {
                      syncProvider.syncBothWays();
                    },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('强制同步'),
              subtitle: const Text('忽略时间戳强制同步'),
              onTap: syncProvider.isSyncing
                  ? null
                  : () {
                      syncProvider.forceSync();
                    },
            ),
          ],
        ),
      ),
    );
  }

  /// 同步信息卡片
  Widget _buildSyncInfoCard(SyncProvider syncProvider) {
    final stats = syncProvider.getSyncStats();
    final isLocal = stats['isLocal'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '同步信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isLocal ? Icons.storage : Icons.cloud,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLocal ? '本地同步' : 'iCloud 同步',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isLocal ? '数据存储在本地，仅作为备份' : '数据存储在 iCloud，支持多设备同步',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '同步内容说明:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildSyncContentItem('📄 证件数据', '所有证件照片的基本信息'),
            _buildSyncContentItem('📋 导出记录', '导出操作的历史记录'),
            _buildSyncContentItem('🔒 安全配置', '生物识别、PIN码等设置'),
            _buildSyncContentItem('💧 水印配置', '水印样式和内容设置'),
          ],
        ),
      ),
    );
  }

  /// 同步内容项
  Widget _buildSyncContentItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons(SyncProvider syncProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: syncProvider.isSyncing
                ? null
                : () {
                    syncProvider.syncBothWays();
                  },
            icon: const Icon(Icons.sync),
            label: const Text('立即同步'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: syncProvider.isSyncing
                ? null
                : () {
                    _showClearDataDialog(syncProvider);
                  },
            icon: const Icon(Icons.delete_forever),
            label: const Text('清理同步数据'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示同步内容对话框
  void _showSyncContentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('同步内容'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前同步以下内容:'),
            SizedBox(height: 16),
            Text('📄 证件数据'),
            Text('   - 证件类型、号码、持有人信息'),
            Text('   - 拍摄时间、标签、备注'),
            SizedBox(height: 8),
            Text('📋 导出记录'),
            Text('   - 导出时间、文件信息'),
            Text('   - 水印配置、设备信息'),
            SizedBox(height: 8),
            Text('🔒 安全配置'),
            Text('   - 生物识别设置'),
            Text('   - PIN码、自动锁定配置'),
            SizedBox(height: 8),
            Text('💧 水印配置'),
            Text('   - 显性水印设置'),
            Text('   - 暗水印配置'),
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

  /// 显示清理数据对话框
  void _showClearDataDialog(SyncProvider syncProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清理同步数据'),
        content: const Text(
          '确定要清理所有同步数据吗？\n\n'
          '这将删除:\n'
          '• iCloud 中的同步文件\n'
          '• 本地同步备份\n'
          '• 同步状态记录\n\n'
          '此操作不可撤销！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await syncProvider.clearSyncData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('同步数据已清理')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清理'),
          ),
        ],
      ),
    );
  }
}
