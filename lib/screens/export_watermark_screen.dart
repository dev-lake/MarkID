import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../models/models.dart';
import '../providers/document_provider.dart';
import '../services/export_service.dart';
import '../services/watermark.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportWatermarkScreen extends StatefulWidget {
  final String documentId;

  const ExportWatermarkScreen({super.key, required this.documentId});

  @override
  State<ExportWatermarkScreen> createState() => _ExportWatermarkScreenState();
}

class _ExportWatermarkScreenState extends State<ExportWatermarkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _watermarkTextController = TextEditingController();

  IdDocument? _document;
  WatermarkConfig _watermarkConfig = WatermarkConfig.defaultVisible();
  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;

  // 新增：水印方式选择
  WatermarkMethod _selectedWatermarkMethod = WatermarkMethod.type1;

  // 新增：网格配置变量
  int _gridRows = 4;
  int _gridColumns = 2;

  // 新增：处理后图片相关状态
  Uint8List? _processedImageData;
  bool _isGeneratingPreview = false;
  Timer? _previewDebounceTimer;

  // 新增：当前选中的照片索引
  int _selectedPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDocument()
        .then((_) => _initializeWatermarkText())
        .then((_) => _generatePreview());
  }

  @override
  void dispose() {
    _watermarkTextController.dispose();
    _previewDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final provider = context.read<DocumentProvider>();
      final document = provider.getDocumentById(widget.documentId);

      if (document != null) {
        setState(() {
          _document = document;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '未找到证件信息';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载证件信息失败: $e';
        _isLoading = false;
      });
    }
  }

  void _initializeWatermarkText() {
    if (_document != null) {
      final watermarkText = ExportService.generateWatermarkText(
        document: _document!,
        template: _watermarkConfig.content,
      );
      _watermarkTextController.text = watermarkText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('导出水印照片'),
      actions: [
        if (!_isLoading && _document != null && !_isExporting)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'single') {
                _exportImage(exportAll: false);
              } else if (value == 'all') {
                _exportImage(exportAll: true);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'single',
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8),
                    Text('导出主照片'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.photo_library),
                    SizedBox(width: 8),
                    Text('导出所有照片 (${_document?.photos.length ?? 0}张)'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('导出'), Icon(Icons.arrow_drop_down)],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadDocument, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_document == null) {
      return const Center(child: Text('证件不存在'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 10),
            _buildWatermarkTextSection(),
            const SizedBox(height: 10),
            _buildWatermarkMethodSection(),
            const SizedBox(height: 100), // 底部留白
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(Icons.compare, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('图片对比预览', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (_document != null && _document!.photos.length > 1)
                  DropdownButton<int>(
                    value: _selectedPhotoIndex,
                    items: _document!.photos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final photo = entry.value;
                      return DropdownMenuItem(
                        value: index,
                        child: Text('${photo.photoType} (${index + 1})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPhotoIndex = value;
                          _processedImageData = null; // 清除预览
                        });
                        _generatePreview();
                      }
                    },
                  ),
                // if (!_isGeneratingPreview)
                //   TextButton.icon(
                //     onPressed: _generatePreview,
                //     icon: const Icon(Icons.refresh),
                //     label: const Text('生成预览'),
                //   ),
              ],
            ),
            const SizedBox(height: 16),
            // 图片对比区域
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 原图预览（小图）
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.photo,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '原图',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _buildImageWidget(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 水印预览（大图）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 14,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '水印效果预览',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildProcessedImageWidget(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (_document!.photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text('暂无照片', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final selectedPhoto = _document!.photos[_selectedPhotoIndex];
    final imagePath = selectedPhoto.originalImagePath;
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('图片加载失败', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildProcessedImageWidget() {
    if (_isGeneratingPreview) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('正在生成预览...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (_processedImageData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('点击"生成预览"查看水印效果', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Image.memory(
      _processedImageData!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('预览生成失败', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  void _schedulePreviewUpdate() {
    _previewDebounceTimer?.cancel();
    _previewDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_processedImageData != null) {
        _generatePreview();
      }
    });
  }

  Future<void> _generatePreview() async {
    if (_document == null || _watermarkTextController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先输入水印文本')));
      return;
    }

    try {
      setState(() {
        _isGeneratingPreview = true;
      });

      // 读取原始图片文件
      if (_document!.photos.isEmpty) {
        throw Exception('证件没有照片');
      }
      final selectedPhoto = _document!.photos[_selectedPhotoIndex];
      final File originalFile = File(selectedPhoto.originalImagePath);
      final Uint8List originalImageData = await originalFile.readAsBytes();

      // 根据选择的方式添加水印
      Uint8List processedImageData;

      switch (_selectedWatermarkMethod) {
        case WatermarkMethod.type1:
          processedImageData = await Watermark.imageAddWaterMarkType1(
            originalImageData,
            _watermarkTextController.text,
          );
          break;
        case WatermarkMethod.type2:
          final result = await Watermark.imageAddWaterMarkType2(
            originalImageData,
            _watermarkTextController.text,
            rows: _gridRows,
            columns: _gridColumns,
            angle: _watermarkConfig.rotation,
            opacity: _watermarkConfig.opacity,
          );
          if (result == null) {
            throw Exception('水印处理失败');
          }
          processedImageData = result;
          break;
      }

      setState(() {
        _processedImageData = processedImageData;
        _isGeneratingPreview = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingPreview = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('预览生成失败: $e')));
      }
    }
  }

  Widget _buildWatermarkMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('水印方式', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildWatermarkMethodSelector(),
            // const SizedBox(height: 12),
            // _buildWatermarkMethodDescription(),
          ],
        ),
      ),
    );
  }

  Widget _buildWatermarkMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<WatermarkMethod>(
          segments: const [
            ButtonSegment(
              value: WatermarkMethod.type1,
              label: Text('透明覆盖'),
              icon: Icon(Icons.water_drop),
            ),
            ButtonSegment(
              value: WatermarkMethod.type2,
              label: Text('彩虹覆盖'),
              icon: Icon(Icons.grid_on),
            ),
          ],
          selected: {_selectedWatermarkMethod},
          onSelectionChanged: (Set<WatermarkMethod> selection) {
            setState(() {
              _selectedWatermarkMethod = selection.first;
            });
            // 自动更新预览
            _schedulePreviewUpdate();
          },
        ),
      ],
    );
  }

  Widget _buildWatermarkMethodDescription() {
    String description = '';
    String features = '';

    switch (_selectedWatermarkMethod) {
      case WatermarkMethod.type1:
        description = '重复水印覆盖整个图片';
        features = '• 水印文本重复覆盖\n• 固定旋转角度\n• 适合防伪标识';
        break;
      case WatermarkMethod.type2:
        description = '网格分布水印';
        features = '• 网格状分布水印\n• 可调节行列数\n• 支持颜色渐变\n• 适合版权保护';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            features,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkConfigSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('水印配置', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            _buildWatermarkTypeSelector(),
            const SizedBox(height: 16),
            if (_selectedWatermarkMethod == WatermarkMethod.type2) ...[
              _buildGridConfigSection(),
              const SizedBox(height: 16),
            ],
            _buildWatermarkPositionSelector(),
            const SizedBox(height: 16),
            _buildFontSizeSlider(),
            const SizedBox(height: 16),
            _buildOpacitySlider(),
            if (_selectedWatermarkMethod == WatermarkMethod.type2) ...[
              const SizedBox(height: 16),
              _buildRotationSlider(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('网格配置', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('行数'),
                  Slider(
                    value: _gridRows.toDouble(),
                    min: 2,
                    max: 8,
                    divisions: 6,
                    label: '$_gridRows',
                    onChanged: (value) {
                      setState(() {
                        _gridRows = value.toInt();
                      });
                      // 自动更新预览
                      _schedulePreviewUpdate();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('列数'),
                  Slider(
                    value: _gridColumns.toDouble(),
                    min: 2,
                    max: 6,
                    divisions: 4,
                    label: '$_gridColumns',
                    onChanged: (value) {
                      setState(() {
                        _gridColumns = value.toInt();
                      });
                      // 自动更新预览
                      _schedulePreviewUpdate();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWatermarkTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('水印类型', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        SegmentedButton<WatermarkType>(
          segments: const [
            ButtonSegment(
              value: WatermarkType.visible,
              label: Text('显性水印'),
              icon: Icon(Icons.visibility),
            ),
            ButtonSegment(
              value: WatermarkType.invisible,
              label: Text('隐性水印'),
              icon: Icon(Icons.visibility_off),
            ),
          ],
          selected: {_watermarkConfig.type},
          onSelectionChanged: (Set<WatermarkType> selection) {
            setState(() {
              _watermarkConfig = _watermarkConfig.copyWith(
                type: selection.first,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildWatermarkPositionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('水印位置', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<WatermarkPosition>(
          value: _watermarkConfig.position,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: WatermarkPosition.values.map((position) {
            return DropdownMenuItem(
              value: position,
              child: Text(_getPositionText(position)),
            );
          }).toList(),
          onChanged: (WatermarkPosition? position) {
            if (position != null) {
              setState(() {
                _watermarkConfig = _watermarkConfig.copyWith(
                  position: position,
                );
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('字体大小', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('${_watermarkConfig.fontSize.toInt()}px'),
          ],
        ),
        Slider(
          value: _watermarkConfig.fontSize,
          min: 12.0,
          max: 48.0,
          divisions: 36,
          label: '${_watermarkConfig.fontSize.toInt()}px',
          onChanged: (double value) {
            setState(() {
              _watermarkConfig = _watermarkConfig.copyWith(fontSize: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildOpacitySlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('透明度', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('${(_watermarkConfig.opacity * 100).toInt()}%'),
          ],
        ),
        Slider(
          value: _watermarkConfig.opacity,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: '${(_watermarkConfig.opacity * 100).toInt()}%',
          onChanged: (double value) {
            setState(() {
              _watermarkConfig = _watermarkConfig.copyWith(opacity: value);
            });
            // 自动更新预览
            _schedulePreviewUpdate();
          },
        ),
      ],
    );
  }

  Widget _buildRotationSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('旋转角度', style: TextStyle(fontWeight: FontWeight.w500)),
            Text('${_watermarkConfig.rotation.toInt()}°'),
          ],
        ),
        Slider(
          value: _watermarkConfig.rotation,
          min: -90.0,
          max: 90.0,
          divisions: 18,
          label: '${_watermarkConfig.rotation.toInt()}°',
          onChanged: (double value) {
            setState(() {
              _watermarkConfig = _watermarkConfig.copyWith(rotation: value);
            });
            // 自动更新预览
            _schedulePreviewUpdate();
          },
        ),
      ],
    );
  }

  Widget _buildWatermarkTextSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_fields, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('水印文本', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: _generateWatermarkText,
                  child: const Text('生成'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _watermarkTextController,
              decoration: const InputDecoration(
                labelText: '水印文本',
                hintText: '请输入水印文本',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入水印文本';
                }
                return null;
              },
              onChanged: (value) {
                // 自动更新预览
                _schedulePreviewUpdate();
              },
            ),
            const SizedBox(height: 8),
            Text(
              '支持占位符: {{documentType}}, {{holderName}}, {{documentNumber}}, {{timestamp}}, {{date}}, {{time}}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text('导出选项', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('保存到相册'),
              subtitle: const Text('将水印照片保存到设备相册'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: 实现保存到相册选项
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('导出后分享'),
              subtitle: const Text('导出完成后自动打开分享菜单'),
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: 实现分享选项
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPositionText(WatermarkPosition position) {
    switch (position) {
      case WatermarkPosition.topLeft:
        return '左上角';
      case WatermarkPosition.topRight:
        return '右上角';
      case WatermarkPosition.bottomLeft:
        return '左下角';
      case WatermarkPosition.bottomRight:
        return '右下角';
      case WatermarkPosition.center:
        return '中心';
      case WatermarkPosition.random:
        return '随机位置';
    }
  }

  void _generateWatermarkText() {
    if (_document != null) {
      final watermarkText = ExportService.generateWatermarkText(
        document: _document!,
        template: _watermarkConfig.content,
      );
      setState(() {
        _watermarkTextController.text = watermarkText;
      });
      // 自动更新预览
      _schedulePreviewUpdate();
    }
  }

  Future<void> _exportImage({bool exportAll = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!ExportService.validateExportConfig(
      watermarkConfig: _watermarkConfig,
      watermarkText: _watermarkTextController.text,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('水印配置无效')));
      return;
    }

    try {
      setState(() {
        _isExporting = true;
      });

      if (exportAll) {
        // 导出所有照片
        final exportRecords = await ExportService.exportAllWatermarkedImages(
          document: _document!,
          watermarkConfig: _watermarkConfig,
          watermarkText: _watermarkTextController.text,
          watermarkMethod: _selectedWatermarkMethod,
          gridRows: _gridRows,
          gridColumns: _gridColumns,
        );

        // 请求权限
        await Permission.photos.request();

        // 保存所有照片到相册
        int successCount = 0;
        for (final record in exportRecords) {
          if (record.status == ExportStatus.success) {
            final result = await ImageGallerySaver.saveFile(record.exportPath);
            if (result['isSuccess'] == true) {
              successCount++;
            }
          }
        }

        if (mounted) {
          Navigator.of(context).pop(exportRecords);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('已保存 $successCount 张照片到相册')));
        }
      } else {
        // 导出单张照片
        final exportRecord = await ExportService.exportWatermarkedImage(
          document: _document!,
          watermarkConfig: _watermarkConfig,
          watermarkText: _watermarkTextController.text,
          watermarkMethod: _selectedWatermarkMethod,
          gridRows: _gridRows,
          gridColumns: _gridColumns,
          photoIndex: _selectedPhotoIndex,
        );

        // 请求权限
        await Permission.photos.request();

        // 保存到相册
        final result = await ImageGallerySaver.saveFile(
          exportRecord.exportPath,
        );
        if (result['isSuccess'] == true) {
          // 保存成功
          if (mounted) {
            Navigator.of(context).pop(exportRecord);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已保存到相册: ${exportRecord.fileName}')),
            );
          }
        } else {
          // 保存失败
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('保存到相册失败')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
