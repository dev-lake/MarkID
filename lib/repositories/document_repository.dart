import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../models/models.dart';

/// 证件照片数据访问层
class DocumentRepository {
  static Database? _database;
  static const String _tableName = 'documents';

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'idseal.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        documentType TEXT NOT NULL,
        documentNumber TEXT,
        holderName TEXT,
        photos TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        tags TEXT,
        notes TEXT,
        isDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 从版本1升级到版本2：将单张照片结构改为多张照片结构
      await db.execute(
        'ALTER TABLE $_tableName ADD COLUMN photos TEXT NOT NULL DEFAULT "[]"',
      );

      // 迁移现有数据
      final List<Map<String, dynamic>> oldDocuments = await db.query(
        _tableName,
      );
      for (final oldDoc in oldDocuments) {
        // 创建新的照片对象
        final photoMap = {
          'id': '${oldDoc['id']}_photo',
          'photoType': '正面',
          'description': null,
          'originalImagePath': oldDoc['originalImagePath'],
          'thumbnailPath': oldDoc['thumbnailPath'],
          'captureTime': oldDoc['captureTime'],
          'createdAt': oldDoc['createdAt'],
          'updatedAt': oldDoc['updatedAt'],
          'isEncrypted': oldDoc['isEncrypted'],
          'encryptionKeyHash': oldDoc['encryptionKeyHash'],
          'fileSize': oldDoc['fileSize'],
          'width': oldDoc['width'],
          'height': oldDoc['height'],
          'sortIndex': 0,
          'isPrimary': true,
          'isDeleted': 0,
        };

        final photosJson = '[${photoMap.toString()}]';
        await db.update(
          _tableName,
          {'photos': photosJson},
          where: 'id = ?',
          whereArgs: [oldDoc['id']],
        );
      }
    }

    if (oldVersion < 3) {
      // 从版本2升级到版本3：删除旧字段的NOT NULL约束
      try {
        // 创建临时表
        await db.execute('''
          CREATE TABLE ${_tableName}_temp (
            id TEXT PRIMARY KEY,
            documentType TEXT NOT NULL,
            documentNumber TEXT,
            holderName TEXT,
            photos TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            tags TEXT,
            notes TEXT,
            isDeleted INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // 复制数据
        await db.execute('''
          INSERT INTO ${_tableName}_temp 
          SELECT id, documentType, documentNumber, holderName, photos, 
                 createdAt, updatedAt, tags, notes, isDeleted 
          FROM $_tableName
        ''');

        // 删除旧表
        await db.execute('DROP TABLE $_tableName');

        // 重命名新表
        await db.execute(
          'ALTER TABLE ${_tableName}_temp RENAME TO $_tableName',
        );
      } catch (e) {
        print('数据库升级失败: $e');
      }
    }
  }

  /// 添加证件照片
  Future<IdDocument> addDocument(IdDocument document) async {
    final db = await database;
    await db.insert(_tableName, document.toMap());
    return document;
  }

  /// 更新证件照片
  Future<IdDocument> updateDocument(IdDocument document) async {
    final db = await database;
    final updatedDocument = document.copyWith(updatedAt: DateTime.now());
    await db.update(
      _tableName,
      updatedDocument.toMap(),
      where: 'id = ?',
      whereArgs: [document.id],
    );
    return updatedDocument;
  }

  /// 删除证件照片（软删除）
  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isDeleted': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 永久删除证件照片
  Future<void> permanentlyDeleteDocument(String id) async {
    final db = await database;
    final document = await getDocumentById(id);
    if (document != null) {
      // 删除所有照片文件
      for (final photo in document.photos) {
        await _deleteFile(photo.originalImagePath);
        if (photo.thumbnailPath != null) {
          await _deleteFile(photo.thumbnailPath!);
        }
      }
      // 删除数据库记录
      await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    }
  }

  /// 根据ID获取证件照片
  Future<IdDocument?> getDocumentById(String id) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'id = ? AND isDeleted = 0',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return IdDocument.fromMap(maps.first);
    }
    return null;
  }

  /// 获取所有证件照片
  Future<List<IdDocument>> getAllDocuments() async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'isDeleted = 0',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => IdDocument.fromMap(map)).toList();
  }

  /// 根据类型获取证件照片
  Future<List<IdDocument>> getDocumentsByType(String documentType) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'documentType = ? AND isDeleted = 0',
      whereArgs: [documentType],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => IdDocument.fromMap(map)).toList();
  }

  /// 搜索证件照片
  Future<List<IdDocument>> searchDocuments(String query) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: '''
        (documentType LIKE ? OR holderName LIKE ? OR documentNumber LIKE ? OR notes LIKE ?) 
        AND isDeleted = 0
      ''',
      whereArgs: ['%$query%', '%$query%', '%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => IdDocument.fromMap(map)).toList();
  }

  /// 根据标签获取证件照片
  Future<List<IdDocument>> getDocumentsByTag(String tag) async {
    final db = await database;
    final maps = await db.query(
      _tableName,
      where: 'tags LIKE ? AND isDeleted = 0',
      whereArgs: ['%$tag%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => IdDocument.fromMap(map)).toList();
  }

  /// 保存照片文件
  Future<String> saveImageFile(Uint8List imageData, String fileName) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(documentsDir.path, 'images'));

    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final filePath = path.join(imagesDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(imageData);

    return filePath;
  }

  /// 生成缩略图
  Future<String?> generateThumbnail(
    String originalPath,
    String fileName,
  ) async {
    try {
      final file = File(originalPath);
      if (!await file.exists()) return null;

      final imageData = await file.readAsBytes();
      final image = img.decodeImage(imageData);
      if (image == null) return null;

      // 生成缩略图（最大200x200）
      final thumbnail = img.copyResize(
        image,
        width: 200,
        height: 200,
        interpolation: img.Interpolation.linear,
      );

      final thumbnailData = img.encodeJpg(thumbnail, quality: 80);
      final thumbnailPath = await saveImageFile(
        Uint8List.fromList(thumbnailData),
        'thumb_$fileName',
      );

      return thumbnailPath;
    } catch (e) {
      print('生成缩略图失败: $e');
      return null;
    }
  }

  /// 删除文件
  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('删除文件失败: $e');
    }
  }

  /// 删除图片文件（公共方法）
  Future<void> deleteImageFile(String filePath) async {
    await _deleteFile(filePath);
  }

  /// 获取照片统计信息
  Future<Map<String, dynamic>> getDocumentStats() async {
    final db = await database;
    final totalCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM $_tableName WHERE isDeleted = 0',
          ),
        ) ??
        0;

    final typeStats = await db.rawQuery('''
      SELECT documentType, COUNT(*) as count 
      FROM $_tableName 
      WHERE isDeleted = 0 
      GROUP BY documentType
    ''');

    // 计算总文件大小 - 需要从照片数据中计算
    int totalSize = 0;
    final documents = await getAllDocuments();
    for (final document in documents) {
      totalSize += document.totalFileSize;
    }

    return {
      'totalCount': totalCount,
      'typeStats': typeStats,
      'totalSize': totalSize,
    };
  }

  /// 批量删除证件照片
  Future<void> batchDeleteDocuments(List<String> ids) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isDeleted': 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// 批量更新标签
  Future<void> batchUpdateTags(List<String> ids, List<String> tags) async {
    final db = await database;
    final tagsString = tags.join(',');
    await db.update(
      _tableName,
      {'tags': tagsString, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 获取所有导出记录
  Future<List<ExportRecord>> getAllExportRecords() async {
    // 这里应该实现从数据库获取导出记录的逻辑
    // 暂时返回空列表
    return [];
  }

  /// 获取安全配置
  Future<SecurityConfig> getSecurityConfig() async {
    // 这里应该实现从数据库获取安全配置的逻辑
    // 暂时返回默认配置
    return SecurityConfig.defaultConfig();
  }

  /// 保存安全配置
  Future<void> saveSecurityConfig(SecurityConfig config) async {
    // 这里应该实现保存安全配置到数据库的逻辑
    // 暂时不实现
  }

  /// 获取水印配置
  Future<WatermarkConfig> getWatermarkConfig() async {
    // 这里应该实现从数据库获取水印配置的逻辑
    // 暂时返回默认配置
    return WatermarkConfig.defaultVisible();
  }

  /// 保存水印配置
  Future<void> saveWatermarkConfig(WatermarkConfig config) async {
    // 这里应该实现保存水印配置到数据库的逻辑
    // 暂时不实现
  }

  /// 恢复文档数据
  Future<void> restoreDocuments(List<IdDocument> documents) async {
    final db = await database;
    final batch = db.batch();

    for (final document in documents) {
      batch.insert(
        _tableName,
        document.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// 恢复导出记录
  Future<void> restoreExportRecords(List<ExportRecord> records) async {
    // 这里应该实现恢复导出记录到数据库的逻辑
    // 暂时不实现
  }
}
