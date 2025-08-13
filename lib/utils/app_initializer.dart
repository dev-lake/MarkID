import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';
import '../repositories/document_repository.dart';

/// 应用初始化工具类
class AppInitializer {
  static const String _firstLaunchKey = 'is_first_launch';
  static const String _sampleDataAddedKey = 'sample_data_added';

  /// 检查是否首次启动
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// 标记应用已启动
  static Future<void> markAppLaunched() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }

  /// 检查是否已添加范例数据
  static Future<bool> isSampleDataAdded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sampleDataAddedKey) ?? false;
  }

  /// 标记范例数据已添加
  static Future<void> markSampleDataAdded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sampleDataAddedKey, true);
  }

  /// 初始化应用（首次启动时添加范例数据）
  static Future<void> initializeApp() async {
    final isFirst = await isFirstLaunch();
    if (isFirst) {
      await markAppLaunched();

      // 检查是否已添加范例数据
      final sampleDataAdded = await isSampleDataAdded();
      if (!sampleDataAdded) {
        await _addSampleData();
        await markSampleDataAdded();
      }
    }
  }

  /// 添加范例数据
  static Future<void> _addSampleData() async {
    try {
      final repository = DocumentRepository();

      // 只创建身份证范例数据
      final idCardDocument = await _createSampleIdCard(repository);
      await repository.addDocument(idCardDocument);

      print('范例数据添加成功');
    } catch (e) {
      print('添加范例数据失败: $e');
    }
  }

  /// 创建身份证范例数据
  static Future<IdDocument> _createSampleIdCard(
    DocumentRepository repository,
  ) async {
    final List<DocumentPhoto> photos = [];
    final captureTime = DateTime.now().subtract(const Duration(days: 30));

    // 加载示例照片文件
    final frontImageData = await _loadAssetImage(
      'assets/assets/example-front.jpg',
    );
    final backImageData = await _loadAssetImage(
      'assets/assets/example-back.jpg',
    );

    // 保存正面照片
    final frontFileName =
        'sample_id_card_front_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final frontOriginalPath = await repository.saveImageFile(
      frontImageData,
      frontFileName,
    );
    final frontThumbnailPath = await repository.generateThumbnail(
      frontOriginalPath,
      frontFileName,
    );

    // 创建正面照片对象
    final frontPhoto = DocumentPhoto(
      photoType: '正面',
      description: '身份证正面照片',
      originalImagePath: frontOriginalPath,
      thumbnailPath: frontThumbnailPath,
      fileSize: frontImageData.length,
      width: 400,
      height: 250,
      sortIndex: 0,
      isPrimary: true,
      captureTime: captureTime,
    );
    photos.add(frontPhoto);

    // 保存反面照片
    final backFileName =
        'sample_id_card_back_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final backOriginalPath = await repository.saveImageFile(
      backImageData,
      backFileName,
    );
    final backThumbnailPath = await repository.generateThumbnail(
      backOriginalPath,
      backFileName,
    );

    // 创建反面照片对象
    final backPhoto = DocumentPhoto(
      photoType: '反面',
      description: '身份证反面照片',
      originalImagePath: backOriginalPath,
      thumbnailPath: backThumbnailPath,
      fileSize: backImageData.length,
      width: 400,
      height: 250,
      sortIndex: 1,
      isPrimary: false,
      captureTime: captureTime,
    );
    photos.add(backPhoto);

    return IdDocument(
      documentType: '身份证',
      documentNumber: '310101198610203222',
      holderName: '张大民',
      photos: photos,
      tags: ['重要证件', '身份证'],
      notes: '这是您的身份证正反面照片，请妥善保管。',
    );
  }

  /// 创建身份证骨架图
  static Uint8List createIdCardSkeletonImage() {
    // 创建带边距的身份证尺寸的图片 (400x250)
    final image = img.Image(width: 400, height: 250);

    // 设置背景色为白色（模拟照片背景）
    final backgroundColor = img.ColorRgb8(255, 255, 255);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.setPixel(x, y, backgroundColor);
      }
    }

    // 定义身份证的实际区域（添加边距）
    final margin = 20; // 边距大小
    final cardWidth = image.width - 2 * margin;
    final cardHeight = image.height - 2 * margin;
    final cardX = margin;
    final cardY = margin;

    // 设置身份证背景色为浅灰色
    final cardBackgroundColor = img.ColorRgb8(240, 240, 240);
    for (int y = cardY; y < cardY + cardHeight; y++) {
      for (int x = cardX; x < cardX + cardWidth; x++) {
        image.setPixel(x, y, cardBackgroundColor);
      }
    }

    // 绘制身份证边框
    final borderColor = img.ColorRgb8(100, 100, 100);
    final borderThickness = 2;

    // 绘制身份证外边框
    for (int i = 0; i < borderThickness; i++) {
      // 上边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + i, borderColor);
      }
      // 下边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + cardHeight - 1 - i, borderColor);
      }
      // 左边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + i, y, borderColor);
      }
      // 右边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + cardWidth - 1 - i, y, borderColor);
      }
    }

    // 绘制标题区域
    final titleBgColor = img.ColorRgb8(200, 200, 200);
    final titleHeight = 40;
    for (int y = cardY + borderThickness; y < cardY + titleHeight; y++) {
      for (
        int x = cardX + borderThickness;
        x < cardX + cardWidth - borderThickness;
        x++
      ) {
        image.setPixel(x, y, titleBgColor);
      }
    }

    // 绘制标题文字区域（用矩形表示）
    final titleTextColor = img.ColorRgb8(80, 80, 80);
    for (int y = cardY + 10; y < cardY + 30; y++) {
      for (int x = cardX + 20; x < cardX + 120; x++) {
        image.setPixel(x, y, titleTextColor);
      }
    }

    // 绘制照片区域
    final photoBgColor = img.ColorRgb8(220, 220, 220);
    for (int y = cardY + 60; y < cardY + 160; y++) {
      for (int x = cardX + 20; x < cardX + 120; x++) {
        image.setPixel(x, y, photoBgColor);
      }
    }

    // 绘制照片边框
    final photoBorderColor = img.ColorRgb8(150, 150, 150);
    for (int i = 0; i < 2; i++) {
      // 照片区域边框
      for (int x = cardX + 20 - i; x < cardX + 120 + i; x++) {
        if (x >= 0 && x < image.width) {
          if (cardY + 60 - i >= 0) {
            image.setPixel(x, cardY + 60 - i, photoBorderColor);
          }
          if (cardY + 160 + i < image.height) {
            image.setPixel(x, cardY + 160 + i, photoBorderColor);
          }
        }
      }
      for (int y = cardY + 60 - i; y < cardY + 160 + i; y++) {
        if (y >= 0 && y < image.height) {
          if (cardX + 20 - i >= 0) {
            image.setPixel(cardX + 20 - i, y, photoBorderColor);
          }
          if (cardX + 120 + i < image.width) {
            image.setPixel(cardX + 120 + i, y, photoBorderColor);
          }
        }
      }
    }

    // 绘制信息区域
    final infoBgColor = img.ColorRgb8(250, 250, 250);
    for (int y = cardY + 60; y < cardY + 200; y++) {
      for (int x = cardX + 140; x < cardX + 380; x++) {
        image.setPixel(x, y, infoBgColor);
      }
    }

    // 绘制信息行（用矩形表示）
    final infoTextColor = img.ColorRgb8(120, 120, 120);
    final lineHeight = 25;
    final startY = 80;

    // 姓名行
    for (int y = cardY + startY; y < cardY + startY + 15; y++) {
      for (int x = cardX + 160; x < cardX + 280; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 性别行
    for (
      int y = cardY + startY + lineHeight;
      y < cardY + startY + lineHeight + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 200; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 民族行
    for (
      int y = cardY + startY + lineHeight;
      y < cardY + startY + lineHeight + 15;
      y++
    ) {
      for (int x = cardX + 240; x < cardX + 320; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 出生日期行
    for (
      int y = cardY + startY + lineHeight * 2;
      y < cardY + startY + lineHeight * 2 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 320; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 住址行
    for (
      int y = cardY + startY + lineHeight * 3;
      y < cardY + startY + lineHeight * 3 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 身份证号码行
    for (
      int y = cardY + startY + lineHeight * 4;
      y < cardY + startY + lineHeight * 4 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 绘制标签文字（用小矩形表示）
    final labelColor = img.ColorRgb8(100, 100, 100);
    final labelPositions = [
      {'x': cardX + 150, 'y': cardY + startY + 5, 'w': 8, 'h': 8}, // 姓名标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight + 5,
        'w': 8,
        'h': 8,
      }, // 性别标签
      {
        'x': cardX + 230,
        'y': cardY + startY + lineHeight + 5,
        'w': 8,
        'h': 8,
      }, // 民族标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 2 + 5,
        'w': 8,
        'h': 8,
      }, // 出生标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 3 + 5,
        'w': 8,
        'h': 8,
      }, // 住址标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 4 + 5,
        'w': 8,
        'h': 8,
      }, // 号码标签
    ];

    for (final label in labelPositions) {
      for (int y = label['y']!; y < label['y']! + label['h']!; y++) {
        for (int x = label['x']!; x < label['x']! + label['w']!; x++) {
          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            image.setPixel(x, y, labelColor);
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// 创建身份证正面骨架图
  static Uint8List createIdCardFrontSkeletonImage() {
    // 创建带边距的身份证尺寸的图片 (400x250)
    final image = img.Image(width: 400, height: 250);

    // 设置背景色为白色（模拟照片背景）
    final backgroundColor = img.ColorRgb8(255, 255, 255);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.setPixel(x, y, backgroundColor);
      }
    }

    // 定义身份证的实际区域（添加边距）
    final margin = 20; // 边距大小
    final cardWidth = image.width - 2 * margin;
    final cardHeight = image.height - 2 * margin;
    final cardX = margin;
    final cardY = margin;

    // 设置身份证背景色为浅灰色
    final cardBackgroundColor = img.ColorRgb8(240, 240, 240);
    for (int y = cardY; y < cardY + cardHeight; y++) {
      for (int x = cardX; x < cardX + cardWidth; x++) {
        image.setPixel(x, y, cardBackgroundColor);
      }
    }

    // 绘制身份证边框
    final borderColor = img.ColorRgb8(100, 100, 100);
    final borderThickness = 2;

    // 绘制身份证外边框
    for (int i = 0; i < borderThickness; i++) {
      // 上边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + i, borderColor);
      }
      // 下边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + cardHeight - 1 - i, borderColor);
      }
      // 左边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + i, y, borderColor);
      }
      // 右边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + cardWidth - 1 - i, y, borderColor);
      }
    }

    // 绘制标题区域
    final titleBgColor = img.ColorRgb8(200, 200, 200);
    final titleHeight = 40;
    for (int y = cardY + borderThickness; y < cardY + titleHeight; y++) {
      for (
        int x = cardX + borderThickness;
        x < cardX + cardWidth - borderThickness;
        x++
      ) {
        image.setPixel(x, y, titleBgColor);
      }
    }

    // 绘制标题文字区域（用矩形表示）
    final titleTextColor = img.ColorRgb8(80, 80, 80);
    for (int y = cardY + 10; y < cardY + 30; y++) {
      for (int x = cardX + 20; x < cardX + 120; x++) {
        image.setPixel(x, y, titleTextColor);
      }
    }

    // 绘制照片区域
    final photoBgColor = img.ColorRgb8(220, 220, 220);
    for (int y = cardY + 60; y < cardY + 160; y++) {
      for (int x = cardX + 20; x < cardX + 120; x++) {
        image.setPixel(x, y, photoBgColor);
      }
    }

    // 绘制照片边框
    final photoBorderColor = img.ColorRgb8(150, 150, 150);
    for (int i = 0; i < 2; i++) {
      // 照片区域边框
      for (int x = cardX + 20 - i; x < cardX + 120 + i; x++) {
        if (x >= 0 && x < image.width) {
          if (cardY + 60 - i >= 0) {
            image.setPixel(x, cardY + 60 - i, photoBorderColor);
          }
          if (cardY + 160 + i < image.height) {
            image.setPixel(x, cardY + 160 + i, photoBorderColor);
          }
        }
      }
      for (int y = cardY + 60 - i; y < cardY + 160 + i; y++) {
        if (y >= 0 && y < image.height) {
          if (cardX + 20 - i >= 0) {
            image.setPixel(cardX + 20 - i, y, photoBorderColor);
          }
          if (cardX + 120 + i < image.width) {
            image.setPixel(cardX + 120 + i, y, photoBorderColor);
          }
        }
      }
    }

    // 绘制信息区域
    final infoBgColor = img.ColorRgb8(250, 250, 250);
    for (int y = cardY + 60; y < cardY + 200; y++) {
      for (int x = cardX + 140; x < cardX + 380; x++) {
        image.setPixel(x, y, infoBgColor);
      }
    }

    // 绘制信息行（用矩形表示）
    final infoTextColor = img.ColorRgb8(120, 120, 120);
    final lineHeight = 25;
    final startY = 80;

    // 姓名行
    for (int y = cardY + startY; y < cardY + startY + 15; y++) {
      for (int x = cardX + 160; x < cardX + 280; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 性别行
    for (
      int y = cardY + startY + lineHeight;
      y < cardY + startY + lineHeight + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 200; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 民族行
    for (
      int y = cardY + startY + lineHeight;
      y < cardY + startY + lineHeight + 15;
      y++
    ) {
      for (int x = cardX + 240; x < cardX + 320; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 出生日期行
    for (
      int y = cardY + startY + lineHeight * 2;
      y < cardY + startY + lineHeight * 2 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 320; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 住址行
    for (
      int y = cardY + startY + lineHeight * 3;
      y < cardY + startY + lineHeight * 3 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 身份证号码行
    for (
      int y = cardY + startY + lineHeight * 4;
      y < cardY + startY + lineHeight * 4 + 15;
      y++
    ) {
      for (int x = cardX + 160; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 绘制标签文字（用小矩形表示）
    final labelColor = img.ColorRgb8(100, 100, 100);
    final labelPositions = [
      {'x': cardX + 150, 'y': cardY + startY + 5, 'w': 8, 'h': 8}, // 姓名标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight + 5,
        'w': 8,
        'h': 8,
      }, // 性别标签
      {
        'x': cardX + 230,
        'y': cardY + startY + lineHeight + 5,
        'w': 8,
        'h': 8,
      }, // 民族标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 2 + 5,
        'w': 8,
        'h': 8,
      }, // 出生标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 3 + 5,
        'w': 8,
        'h': 8,
      }, // 住址标签
      {
        'x': cardX + 150,
        'y': cardY + startY + lineHeight * 4 + 5,
        'w': 8,
        'h': 8,
      }, // 号码标签
    ];

    for (final label in labelPositions) {
      for (int y = label['y']!; y < label['y']! + label['h']!; y++) {
        for (int x = label['x']!; x < label['x']! + label['w']!; x++) {
          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            image.setPixel(x, y, labelColor);
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// 创建身份证反面骨架图
  static Uint8List createIdCardBackSkeletonImage() {
    // 创建带边距的身份证尺寸的图片 (400x250)
    final image = img.Image(width: 400, height: 250);

    // 设置背景色为白色（模拟照片背景）
    final backgroundColor = img.ColorRgb8(255, 255, 255);
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        image.setPixel(x, y, backgroundColor);
      }
    }

    // 定义身份证的实际区域（添加边距）
    final margin = 20; // 边距大小
    final cardWidth = image.width - 2 * margin;
    final cardHeight = image.height - 2 * margin;
    final cardX = margin;
    final cardY = margin;

    // 设置身份证背景色为浅灰色
    final cardBackgroundColor = img.ColorRgb8(240, 240, 240);
    for (int y = cardY; y < cardY + cardHeight; y++) {
      for (int x = cardX; x < cardX + cardWidth; x++) {
        image.setPixel(x, y, cardBackgroundColor);
      }
    }

    // 绘制身份证边框
    final borderColor = img.ColorRgb8(100, 100, 100);
    final borderThickness = 2;

    // 绘制身份证外边框
    for (int i = 0; i < borderThickness; i++) {
      // 上边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + i, borderColor);
      }
      // 下边框
      for (int x = cardX + i; x < cardX + cardWidth - i; x++) {
        image.setPixel(x, cardY + cardHeight - 1 - i, borderColor);
      }
      // 左边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + i, y, borderColor);
      }
      // 右边框
      for (int y = cardY + i; y < cardY + cardHeight - i; y++) {
        image.setPixel(cardX + cardWidth - 1 - i, y, borderColor);
      }
    }

    // 绘制标题区域
    final titleBgColor = img.ColorRgb8(200, 200, 200);
    final titleHeight = 40;
    for (int y = cardY + borderThickness; y < cardY + titleHeight; y++) {
      for (
        int x = cardX + borderThickness;
        x < cardX + cardWidth - borderThickness;
        x++
      ) {
        image.setPixel(x, y, titleBgColor);
      }
    }

    // 绘制标题文字区域（用矩形表示）
    final titleTextColor = img.ColorRgb8(80, 80, 80);
    for (int y = cardY + 10; y < cardY + 30; y++) {
      for (int x = cardX + 20; x < cardX + 120; x++) {
        image.setPixel(x, y, titleTextColor);
      }
    }

    // 绘制信息区域（反面主要是文字信息）
    final infoBgColor = img.ColorRgb8(250, 250, 250);
    for (int y = cardY + 60; y < cardY + 200; y++) {
      for (int x = cardX + 20; x < cardX + 380; x++) {
        image.setPixel(x, y, infoBgColor);
      }
    }

    // 绘制反面信息行（用矩形表示）
    final infoTextColor = img.ColorRgb8(120, 120, 120);
    final lineHeight = 25;
    final startY = 80;

    // 签发机关行
    for (int y = cardY + startY; y < cardY + startY + 15; y++) {
      for (int x = cardX + 40; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 有效期限行
    for (
      int y = cardY + startY + lineHeight;
      y < cardY + startY + lineHeight + 15;
      y++
    ) {
      for (int x = cardX + 40; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 签发日期行
    for (
      int y = cardY + startY + lineHeight * 2;
      y < cardY + startY + lineHeight * 2 + 15;
      y++
    ) {
      for (int x = cardX + 40; x < cardX + 360; x++) {
        image.setPixel(x, y, infoTextColor);
      }
    }

    // 绘制标签文字（用小矩形表示）
    final labelColor = img.ColorRgb8(100, 100, 100);
    final labelPositions = [
      {'x': cardX + 30, 'y': cardY + startY + 5, 'w': 8, 'h': 8}, // 签发机关标签
      {
        'x': cardX + 30,
        'y': cardY + startY + lineHeight + 5,
        'w': 8,
        'h': 8,
      }, // 有效期限标签
      {
        'x': cardX + 30,
        'y': cardY + startY + lineHeight * 2 + 5,
        'w': 8,
        'h': 8,
      }, // 签发日期标签
    ];

    for (final label in labelPositions) {
      for (int y = label['y']!; y < label['y']! + label['h']!; y++) {
        for (int x = label['x']!; x < label['x']! + label['w']!; x++) {
          if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
            image.setPixel(x, y, labelColor);
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// 重置应用状态（用于测试）
  static Future<void> resetAppState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstLaunchKey);
    await prefs.remove(_sampleDataAddedKey);
  }

  /// 加载资源图片文件
  static Future<Uint8List> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (e) {
      print('加载资源图片失败: $e');
      // 如果加载失败，返回一个默认的图片数据
      return createIdCardFrontSkeletonImage();
    }
  }
}
