import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/backup_provider.dart';
import '../models/backup_config.dart';
import '../models/backup_record.dart';

/// 备份设置界面
class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  late BackupConfig _config;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = context.read<BackupProvider>().config;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iCloud 备份设置'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Consumer<BackupProvider>(
        builder: (context, backupProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackupStatusCard(backupProvider),
                const SizedBox(height: 16),
                _buildGeneralSettingsCard(backupProvider),
                const SizedBox(height: 16),
                _buildBackupContentCard(backupProvider),
                const SizedBox(height: 16),
                _buildAdvancedSettingsCard(backupProvider),
                const SizedBox(height: 32),
                _buildActionButtons(backupProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 备份状态卡片
  Widget _buildBackupStatusCard(BackupProvider backupProvider) {
    final stats = backupProvider.getBackupStats();
    final lastBackup = stats['lastBackup'] as BackupRecord?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  '备份状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总备份次数',
                    '${stats['totalBackups']}',
                    Icons.backup,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '成功次数',
                    '${stats['successfulBackups']}',
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '成功率',
                    '${stats['successRate']}%',
                    Icons.analytics,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (lastBackup != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '最后备份: ${_formatDateTime(lastBackup.backupTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.storage, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '备份大小: ${lastBackup.sizeFormatted}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 统计项
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 通用设置卡片
  Widget _buildGeneralSettingsCard(BackupProvider backupProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通用设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('启用自动备份'),
              subtitle: const Text('定期自动备份数据到iCloud'),
              value: _config.enabled,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(enabled: value);
                });
              },
            ),
            if (_config.enabled) ...[
              ListTile(
                title: const Text('备份频率'),
                subtitle: Text('每 ${_config.frequencyHours} 小时'),
                trailing: DropdownButton<int>(
                  value: _config.frequencyHours,
                  items: [6, 12, 24, 48, 72].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours 小时'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _config = _config.copyWith(frequencyHours: value);
                      });
                    }
                  },
                ),
              ),
              SwitchListTile(
                title: const Text('仅在WiFi下备份'),
                subtitle: const Text('避免消耗移动数据'),
                value: _config.backupOnlyOnWifi,
                onChanged: (value) {
                  setState(() {
                    _config = _config.copyWith(backupOnlyOnWifi: value);
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 备份内容卡片
  Widget _buildBackupContentCard(BackupProvider backupProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '备份内容',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('证件数据'),
              subtitle: const Text('备份所有证件照片信息'),
              value: _config.backupDocuments,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(backupDocuments: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('导出记录'),
              subtitle: const Text('备份导出历史记录'),
              value: _config.backupExportRecords,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(backupExportRecords: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('安全配置'),
              subtitle: const Text('备份安全设置和认证配置'),
              value: _config.backupSecurityConfig,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(backupSecurityConfig: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('水印配置'),
              subtitle: const Text('备份水印设置'),
              value: _config.backupWatermarkConfig,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(backupWatermarkConfig: value);
                });
              },
            ),
            SwitchListTile(
              title: const Text('加密密钥'),
              subtitle: const Text('备份加密密钥（谨慎启用）'),
              value: _config.backupEncryptionKeys,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(backupEncryptionKeys: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 高级设置卡片
  Widget _buildAdvancedSettingsCard(BackupProvider backupProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '高级设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('备份大小限制'),
              subtitle: Text('最大 ${_config.maxBackupSizeMB}MB'),
              trailing: DropdownButton<int>(
                value: _config.maxBackupSizeMB,
                items: [50, 100, 200, 500].map((mb) {
                  return DropdownMenuItem(value: mb, child: Text('${mb}MB'));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _config = _config.copyWith(maxBackupSizeMB: value);
                    });
                  }
                },
              ),
            ),
            SwitchListTile(
              title: const Text('压缩备份数据'),
              subtitle: const Text('减少备份文件大小'),
              value: _config.compressBackup,
              onChanged: (value) {
                setState(() {
                  _config = _config.copyWith(compressBackup: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 操作按钮
  Widget _buildActionButtons(BackupProvider backupProvider) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _saveConfig(backupProvider),
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _performManualBackup(backupProvider),
            icon: const Icon(Icons.backup),
            label: const Text('立即备份'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _showBackupHistory(backupProvider),
            icon: const Icon(Icons.history),
            label: const Text('备份历史'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 保存配置
  Future<void> _saveConfig(BackupProvider backupProvider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await backupProvider.saveBackupConfig(_config);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置已保存')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 执行手动备份
  Future<void> _performManualBackup(BackupProvider backupProvider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await backupProvider.performManualBackup();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份完成')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('备份失败: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 显示备份历史
  void _showBackupHistory(BackupProvider backupProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BackupHistoryScreen()),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 备份历史界面
class BackupHistoryScreen extends StatelessWidget {
  const BackupHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('备份历史')),
      body: Consumer<BackupProvider>(
        builder: (context, backupProvider, child) {
          final records = backupProvider.records;

          if (records.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '暂无备份记录',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getStatusIcon(record.status),
                  title: Text(
                    '${record.type == BackupType.automatic ? '自动' : '手动'}备份',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatDateTime(record.backupTime)),
                      Text('大小: ${record.sizeFormatted}'),
                      if (record.durationMs != null)
                        Text('耗时: ${record.durationFormatted}'),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(
                      context,
                      backupProvider,
                      record,
                      value,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'restore',
                        child: Row(
                          children: [
                            Icon(Icons.restore),
                            SizedBox(width: 8),
                            Text('恢复'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 获取状态图标
  Widget _getStatusIcon(BackupStatus status) {
    switch (status) {
      case BackupStatus.success:
        return const Icon(Icons.check_circle, color: Colors.green);
      case BackupStatus.failed:
        return const Icon(Icons.error, color: Colors.red);
      case BackupStatus.inProgress:
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case BackupStatus.cancelled:
        return const Icon(Icons.cancel, color: Colors.grey);
    }
    return const Icon(Icons.info, color: Colors.grey); // Default icon
  }

  /// 处理菜单操作
  void _handleMenuAction(
    BuildContext context,
    BackupProvider backupProvider,
    BackupRecord record,
    String action,
  ) {
    switch (action) {
      case 'restore':
        _showRestoreDialog(context, backupProvider, record);
        break;
      case 'delete':
        _showDeleteDialog(context, backupProvider, record);
        break;
    }
  }

  /// 显示恢复确认对话框
  void _showRestoreDialog(
    BuildContext context,
    BackupProvider backupProvider,
    BackupRecord record,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: Text(
          '确定要恢复 ${_formatDateTime(record.backupTime)} 的备份吗？\n当前数据将被覆盖。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _restoreBackup(context, backupProvider, record);
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteDialog(
    BuildContext context,
    BackupProvider backupProvider,
    BackupRecord record,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Text('确定要删除 ${_formatDateTime(record.backupTime)} 的备份吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBackup(context, backupProvider, record);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 恢复备份
  Future<void> _restoreBackup(
    BuildContext context,
    BackupProvider backupProvider,
    BackupRecord record,
  ) async {
    final success = await backupProvider.restoreFromBackup(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '恢复成功' : '恢复失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// 删除备份
  Future<void> _deleteBackup(
    BuildContext context,
    BackupProvider backupProvider,
    BackupRecord record,
  ) async {
    await backupProvider.deleteBackupRecord(record.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('备份已删除')));
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
