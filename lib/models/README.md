# 证件照片管理应用 - 数据模型

本文档描述了证件照片管理应用的核心数据结构。

## 数据模型概览

### 1. IdDocument - 证件照片模型
证件照片的核心数据模型，包含以下主要属性：

- **基本信息**: 证件类型、证件号码、持有人姓名
- **文件信息**: 原始照片路径、缩略图路径、文件大小、尺寸
- **安全信息**: 加密状态、加密密钥哈希
- **元数据**: 拍摄时间、创建时间、标签、备注
- **软删除**: 支持软删除功能

### 2. WatermarkConfig - 水印配置模型
水印配置数据模型，支持显性水印和暗水印：

- **水印类型**: 显性水印（可见文字）、暗水印（隐藏信息）
- **位置控制**: 支持多个预设位置和随机位置
- **样式配置**: 字体大小、颜色、透明度、旋转角度
- **默认配置**: 提供默认的显性和暗水印配置

### 3. ExportRecord - 导出记录模型
记录每次导出的详细信息：

- **导出信息**: 文件路径、文件名、文件大小、导出时间
- **水印信息**: 应用的水印配置、水印内容详情
- **设备信息**: 导出设备信息、用途、备注
- **状态跟踪**: 导出状态（导出中、成功、失败、取消）
- **错误处理**: 导出失败时的错误信息

### 4. SecurityConfig - 安全配置模型
应用的安全配置设置：

- **认证方式**: PIN码、生物识别（指纹、人脸、虹膜）
- **安全策略**: 自动锁定、应用锁定、导出验证
- **加密配置**: 加密算法、密钥派生函数、迭代次数
- **操作日志**: 是否启用操作日志记录

## 数据关系

```
IdDocument (证件照片)
    ↓ (1:N)
ExportRecord (导出记录)
    ↓ (N:M)
WatermarkConfig (水印配置)

SecurityConfig (安全配置) - 全局配置
```

## 使用示例

### 创建证件照片
```dart
final document = IdDocument(
  documentType: '身份证',
  documentNumber: '123456789012345678',
  holderName: '张三',
  originalImagePath: '/path/to/image.jpg',
  fileSize: 1024000,
  width: 1920,
  height: 1080,
  tags: ['重要', '个人'],
);
```

### 创建水印配置
```dart
final watermark = WatermarkConfig(
  name: '公司水印',
  type: WatermarkType.visible,
  content: '仅限内部使用',
  position: WatermarkPosition.bottomRight,
  fontSize: 20.0,
  color: 0xFF000000,
  opacity: 0.8,
  rotation: -15.0,
);
```

### 创建安全配置
```dart
final security = SecurityConfig(
  isAuthEnabled: true,
  authMethod: AuthMethod.pinOrBiometric,
  supportedBiometrics: [BiometricType.fingerprint, BiometricType.face],
  autoLockEnabled: true,
  autoLockTimeout: 5,
  exportVerificationEnabled: true,
);
```

## 数据库存储

所有模型都支持 `toMap()` 和 `fromMap()` 方法，方便与 SQLite 数据库进行交互。数据以加密形式存储在本地，确保安全性。

## 扩展性

这些数据模型设计具有良好的扩展性，可以根据需要添加新的字段和功能，而不影响现有数据的兼容性。 