import 'package:flutter/foundation.dart';
import '../services/icloud_sync_service.dart';
import '../services/document_service.dart';

/// iCloud 同步状态提供者
class SyncProvider extends ChangeNotifier {
  final ICloudSyncService _syncService;

  bool _isSyncing = false;
  bool _isEnabled = true;
  String? _errorMessage;
  Map<String, dynamic>? _lastSyncStatus;
  bool _hasCloudUpdates = false;

  SyncProvider(DocumentService documentService)
    : _syncService = ICloudSyncService(documentService);

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 是否启用同步
  bool get isEnabled => _isEnabled;

  /// 错误信息
  String? get errorMessage => _errorMessage;

  /// 最后同步状态
  Map<String, dynamic>? get lastSyncStatus => _lastSyncStatus;

  /// 是否有云端更新
  bool get hasCloudUpdates => _hasCloudUpdates;

  /// 初始化
  Future<void> initialize() async {
    await loadSyncStatus();
    await checkCloudUpdates();
  }

  /// 加载同步状态
  Future<void> loadSyncStatus() async {
    try {
      _lastSyncStatus = await _syncService.getSyncStatus();
      notifyListeners();
    } catch (e) {
      _errorMessage = '加载同步状态失败: $e';
      notifyListeners();
    }
  }

  /// 检查云端更新
  Future<void> checkCloudUpdates() async {
    try {
      _hasCloudUpdates = await _syncService.hasCloudUpdates();
      notifyListeners();
    } catch (e) {
      debugPrint('检查云端更新失败: $e');
    }
  }

  /// 同步到 iCloud
  Future<void> syncToICloud() async {
    if (!_isEnabled) return;

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _syncService.syncToICloud();

      if (success) {
        await loadSyncStatus();
        await checkCloudUpdates();
      } else {
        _errorMessage = '同步到 iCloud 失败';
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _errorMessage = '同步失败: $e';
      notifyListeners();
    }
  }

  /// 从 iCloud 同步
  Future<void> syncFromICloud() async {
    if (!_isEnabled) return;

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _syncService.syncFromICloud();

      if (success) {
        await loadSyncStatus();
        await checkCloudUpdates();
      } else {
        _errorMessage = '从 iCloud 同步失败';
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _errorMessage = '同步失败: $e';
      notifyListeners();
    }
  }

  /// 双向同步
  Future<void> syncBothWays() async {
    if (!_isEnabled) return;

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      // 先同步到云端
      final toCloudSuccess = await _syncService.syncToICloud();

      // 再从云端同步
      final fromCloudSuccess = await _syncService.syncFromICloud();

      if (toCloudSuccess && fromCloudSuccess) {
        await loadSyncStatus();
        await checkCloudUpdates();
      } else {
        _errorMessage = '双向同步失败';
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _errorMessage = '同步失败: $e';
      notifyListeners();
    }
  }

  /// 强制同步
  Future<void> forceSync() async {
    if (!_isEnabled) return;

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _syncService.forceSync();

      if (success) {
        await loadSyncStatus();
        await checkCloudUpdates();
      } else {
        _errorMessage = '强制同步失败';
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      _errorMessage = '强制同步失败: $e';
      notifyListeners();
    }
  }

  /// 设置同步启用状态
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 清理同步数据
  Future<void> clearSyncData() async {
    try {
      await _syncService.clearSyncData();
      _lastSyncStatus = null;
      _hasCloudUpdates = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '清理同步数据失败: $e';
      notifyListeners();
    }
  }

  /// 获取同步统计信息
  Map<String, dynamic> getSyncStats() {
    if (_lastSyncStatus == null) {
      return {
        'lastSyncTime': null,
        'lastSyncSuccess': false,
        'isLocal': false,
        'hasError': false,
        'errorMessage': null,
      };
    }

    return {
      'lastSyncTime': _lastSyncStatus!['lastSyncTime'],
      'lastSyncSuccess': _lastSyncStatus!['success'] ?? false,
      'isLocal': _lastSyncStatus!['isLocal'] ?? false,
      'hasError': _lastSyncStatus!['error'] != null,
      'errorMessage': _lastSyncStatus!['error'],
    };
  }

  /// 格式化最后同步时间
  String getLastSyncTimeFormatted() {
    if (_lastSyncStatus == null || _lastSyncStatus!['lastSyncTime'] == null) {
      return '从未同步';
    }

    try {
      final lastSyncTime = DateTime.parse(_lastSyncStatus!['lastSyncTime']);
      final now = DateTime.now();
      final difference = now.difference(lastSyncTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} 天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} 小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} 分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '时间格式错误';
    }
  }

  /// 获取同步状态描述
  String getSyncStatusDescription() {
    if (_isSyncing) {
      return '正在同步...';
    }

    if (_lastSyncStatus == null) {
      return '未同步';
    }

    if (_lastSyncStatus!['success'] == true) {
      final isLocal = _lastSyncStatus!['isLocal'] ?? false;
      return isLocal ? '本地同步成功' : 'iCloud 同步成功';
    } else {
      return '同步失败';
    }
  }

  /// 获取同步状态图标
  String getSyncStatusIcon() {
    if (_isSyncing) {
      return '🔄';
    }

    if (_lastSyncStatus == null) {
      return '❌';
    }

    if (_lastSyncStatus!['success'] == true) {
      final isLocal = _lastSyncStatus!['isLocal'] ?? false;
      return isLocal ? '💾' : '☁️';
    } else {
      return '⚠️';
    }
  }
}
