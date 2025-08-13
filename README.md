# 马克证件 (MarkID)

一款离线运行的证件照片管理应用，支持本地加密存储、水印添加和生物识别解锁。

## 功能特性

### 🔐 安全特性
- **本地加密存储**: 使用AES加密算法保护照片数据
- **生物识别解锁**: 支持指纹、人脸识别
- **PIN码验证**: 多重身份验证机制
- **操作日志**: 记录所有敏感操作

### 📸 照片管理
- **多种导入方式**: 相机拍照、相册选择
- **智能分类**: 按证件类型、标签自动分类
- **缩略图生成**: 自动生成高质量缩略图
- **批量操作**: 支持批量删除、标签管理

### 🔍 搜索过滤
- **智能搜索**: 支持证件类型、姓名、号码、备注搜索
- **多维度过滤**: 按证件类型、标签、时间过滤
- **搜索建议**: 智能搜索建议和历史记录

### 💧 水印功能
- **显性水印**: 可见的文字水印（用途、时间等）
- **暗水印**: 不可见的水印（时间戳、设备ID）
- **自定义配置**: 水印位置、样式、内容可配置

### 📊 数据统计
- **存储统计**: 照片数量、总大小统计
- **类型分布**: 各类证件数量统计
- **导出记录**: 完整的导出历史记录

## 技术架构

### 分层架构
```
UI层 (Screens/Widgets)
    ↓
状态管理层 (Providers)
    ↓
业务逻辑层 (Services)
    ↓
数据访问层 (Repositories)
    ↓
数据模型层 (Models)
```

### 核心组件

#### 数据模型 (Models)
- `IdDocument`: 证件照片数据模型
- `WatermarkConfig`: 水印配置模型
- `ExportRecord`: 导出记录模型
- `SecurityConfig`: 安全配置模型

#### 数据访问层 (Repositories)
- `DocumentRepository`: 证件照片数据访问
- 支持SQLite本地存储
- 文件系统管理
- 缩略图生成

#### 业务逻辑层 (Services)
- `DocumentService`: 证件照片业务逻辑
- 照片处理、压缩
- 文件管理
- 数据验证

#### 状态管理层 (Providers)
- `DocumentProvider`: 证件照片状态管理
- 响应式UI更新
- 数据过滤和搜索
- 错误处理

#### UI组件 (Widgets)
- `DocumentCard`: 证件照片卡片
- `SearchBarWidget`: 搜索栏组件
- `FilterDrawer`: 过滤抽屉组件

#### 页面 (Screens)
- `DocumentListScreen`: 证件照片列表页面
- `DocumentDetailScreen`: 证件照片详情页面
- `DocumentEditScreen`: 证件照片编辑页面
- `PermissionScreen`: 权限管理页面

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── models.dart          # 模型导出
│   ├── id_document.dart     # 证件照片模型
│   ├── watermark_config.dart # 水印配置模型
│   ├── export_record.dart   # 导出记录模型
│   └── security_config.dart # 安全配置模型
├── repositories/            # 数据访问层
│   └── document_repository.dart
├── services/               # 业务逻辑层
│   └── document_service.dart
├── providers/              # 状态管理
│   └── document_provider.dart
├── screens/                # 页面
│   ├── document_list_screen.dart
│   ├── document_detail_screen.dart
│   ├── document_edit_screen.dart
│   └── permission_screen.dart
└── widgets/                # UI组件
    ├── document_card.dart
    ├── search_bar_widget.dart
    └── filter_drawer.dart
```

## 安装和运行

### 环境要求
- Flutter 3.0+
- Dart 3.0+
- iOS 12.0+ / Android 5.0+

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd idseal
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
flutter run
```

### 依赖包

```yaml
dependencies:
  # UUID生成
  uuid: ^4.5.1
  
  # 本地存储
  sqflite: ^2.3.3+1
  path: ^1.9.0
  
  # 加密相关
  crypto: ^3.0.3
  encrypt: ^5.0.3
  
  # 图片处理
  image: ^4.1.7
  image_picker: ^1.0.7
  
  # 生物识别
  local_auth: ^2.2.0
  
  # 文件操作
  path_provider: ^2.1.4
  
  # 状态管理
  provider: ^6.1.2
```

## 使用说明

### 添加证件照片
1. 点击右下角"添加证件"按钮
2. 填写证件信息（类型、号码、持有人等）
3. 选择拍照或从相册选择
4. 系统自动生成缩略图并保存

### 查看证件详情
1. 点击证件照片卡片进入详情页面
2. 查看完整的证件信息和照片
3. 查看加密状态和安全信息
4. 使用底部操作按钮进行分享或导出

### 编辑证件信息
1. 在详情页面点击编辑按钮
2. 修改证件类型、持有人、号码等信息
3. 添加或删除标签
4. 编辑备注信息
5. 保存更改

### 搜索和过滤
1. 点击搜索图标进行搜索
2. 点击过滤图标打开过滤面板
3. 按证件类型、标签进行过滤
4. 查看统计信息

### 批量操作
1. 长按证件照片进入选择模式
2. 选择多个证件照片
3. 进行批量删除或标签管理

## 开发计划

### 已完成 ✅
- [x] 核心数据模型设计
- [x] 数据库设计和实现
- [x] 照片上传和管理功能
- [x] 搜索和过滤功能
- [x] 基础UI界面
- [x] 状态管理架构
- [x] 单元测试
- [x] 证件详情页面
- [x] 证件编辑功能

### 进行中 🚧
- [ ] 加密存储功能
- [ ] 水印添加功能
- [ ] 生物识别解锁
- [ ] 导出功能

### 计划中 📋
- [ ] 云同步功能
- [ ] 高级搜索
- [ ] 数据备份恢复
- [ ] 多语言支持
- [ ] 主题定制

## 测试

运行所有测试：
```bash
flutter test
```

运行特定测试：
```bash
flutter test test/models/
flutter test test/widget_test.dart
```

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

MIT License

## 联系方式

如有问题或建议，请通过以下方式联系：
- 提交Issue
- 发送邮件

---

**注意**: 本应用处理敏感的个人证件信息，请确保在安全的环境中使用，并遵守相关的隐私保护法规。
