import 'package:flutter/material.dart';
import 'lib/models/models.dart';

/// 演示多照片功能的示例数据
class MultiPhotoDemo {
  /// 创建一个包含多张照片的证件示例
  static IdDocument createMultiPhotoDocument() {
    final photos = [
      DocumentPhoto(
        photoType: '正面',
        description: '身份证正面照片',
        originalImagePath: '/path/to/front.jpg',
        thumbnailPath: '/path/to/front_thumb.jpg',
        fileSize: 1024000,
        width: 1920,
        height: 1080,
        sortIndex: 0,
        isPrimary: true,
      ),
      DocumentPhoto(
        photoType: '反面',
        description: '身份证反面照片',
        originalImagePath: '/path/to/back.jpg',
        thumbnailPath: '/path/to/back_thumb.jpg',
        fileSize: 980000,
        width: 1920,
        height: 1080,
        sortIndex: 1,
        isPrimary: false,
      ),
      DocumentPhoto(
        photoType: '内页',
        description: '护照内页照片',
        originalImagePath: '/path/to/inside.jpg',
        thumbnailPath: '/path/to/inside_thumb.jpg',
        fileSize: 1200000,
        width: 1920,
        height: 1080,
        sortIndex: 2,
        isPrimary: false,
      ),
    ];

    return IdDocument(
      documentType: '身份证',
      documentNumber: '123456789012345678',
      holderName: '张三',
      photos: photos,
      tags: ['身份证', '重要', '个人证件'],
      notes: '包含正反面和内页的完整身份证照片',
    );
  }

  /// 创建一个护照多页示例
  static IdDocument createPassportDocument() {
    final photos = [
      DocumentPhoto(
        photoType: '封面',
        description: '护照封面',
        originalImagePath: '/path/to/passport_cover.jpg',
        thumbnailPath: '/path/to/passport_cover_thumb.jpg',
        fileSize: 850000,
        width: 1920,
        height: 1080,
        sortIndex: 0,
        isPrimary: true,
      ),
      DocumentPhoto(
        photoType: '第一页',
        description: '护照第一页（个人信息页）',
        originalImagePath: '/path/to/passport_page1.jpg',
        thumbnailPath: '/path/to/passport_page1_thumb.jpg',
        fileSize: 1100000,
        width: 1920,
        height: 1080,
        sortIndex: 1,
        isPrimary: false,
      ),
      DocumentPhoto(
        photoType: '第二页',
        description: '护照第二页（签证页）',
        originalImagePath: '/path/to/passport_page2.jpg',
        thumbnailPath: '/path/to/passport_page2_thumb.jpg',
        fileSize: 950000,
        width: 1920,
        height: 1080,
        sortIndex: 2,
        isPrimary: false,
      ),
      DocumentPhoto(
        photoType: '第三页',
        description: '护照第三页（备注页）',
        originalImagePath: '/path/to/passport_page3.jpg',
        thumbnailPath: '/path/to/passport_page3_thumb.jpg',
        fileSize: 880000,
        width: 1920,
        height: 1080,
        sortIndex: 3,
        isPrimary: false,
      ),
    ];

    return IdDocument(
      documentType: '护照',
      documentNumber: 'E12345678',
      holderName: '李四',
      photos: photos,
      tags: ['护照', '国际旅行', '重要'],
      notes: '包含封面和多个内页的完整护照照片',
    );
  }

  /// 创建一个驾驶证示例
  static IdDocument createDriverLicenseDocument() {
    final photos = [
      DocumentPhoto(
        photoType: '正面',
        description: '驾驶证正面',
        originalImagePath: '/path/to/license_front.jpg',
        thumbnailPath: '/path/to/license_front_thumb.jpg',
        fileSize: 920000,
        width: 1920,
        height: 1080,
        sortIndex: 0,
        isPrimary: true,
      ),
      DocumentPhoto(
        photoType: '反面',
        description: '驾驶证反面',
        originalImagePath: '/path/to/license_back.jpg',
        thumbnailPath: '/path/to/license_back_thumb.jpg',
        fileSize: 890000,
        width: 1920,
        height: 1080,
        sortIndex: 1,
        isPrimary: false,
      ),
    ];

    return IdDocument(
      documentType: '驾驶证',
      documentNumber: '1234567890123456',
      holderName: '王五',
      photos: photos,
      tags: ['驾驶证', '驾驶', '交通'],
      notes: '驾驶证正反面照片',
    );
  }

  /// 获取所有演示文档
  static List<IdDocument> getAllDemoDocuments() {
    return [
      createMultiPhotoDocument(),
      createPassportDocument(),
      createDriverLicenseDocument(),
    ];
  }

  /// 演示照片统计功能
  static void demonstratePhotoStats() {
    final documents = getAllDemoDocuments();

    print('=== 多照片功能演示 ===');

    for (final document in documents) {
      print('\n证件类型: ${document.documentType}');
      print('持有人: ${document.holderName}');
      print('照片数量: ${document.photos.length}张');
      print('总文件大小: ${document.fileSizeFormatted}');
      print('主照片: ${document.primaryPhoto?.photoTypeDisplay ?? '无'}');

      print('照片列表:');
      for (final photo in document.sortedPhotos) {
        print('  - ${photo.photoTypeDisplay}: ${photo.fileSizeFormatted}');
        if (photo.isPrimary) {
          print('    (主照片)');
        }
      }
    }
  }
}

/// 演示多照片功能的Widget
class MultiPhotoDemoWidget extends StatelessWidget {
  const MultiPhotoDemoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final documents = MultiPhotoDemo.getAllDemoDocuments();

    return Scaffold(
      appBar: AppBar(title: const Text('多照片功能演示')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final document = documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              document.documentType,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              document.holderName ?? '未知',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${document.photos.length}张',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('文件大小: ${document.fileSizeFormatted}'),
                  if (document.primaryPhoto != null)
                    Text('主照片: ${document.primaryPhoto!.photoTypeDisplay}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: document.photos.map((photo) {
                      return Chip(
                        label: Text(photo.photoTypeDisplay),
                        backgroundColor: photo.isPrimary
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          fontSize: 10,
                          color: photo.isPrimary
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
