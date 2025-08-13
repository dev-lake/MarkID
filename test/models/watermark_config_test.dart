import 'package:flutter_test/flutter_test.dart';
import 'package:idseal/models/watermark_config.dart';

void main() {
  group('WatermarkConfig', () {
    test('应该正确创建WatermarkConfig实例', () {
      final watermark = WatermarkConfig(
        name: '公司水印',
        type: WatermarkType.visible,
        content: '仅限内部使用',
        position: WatermarkPosition.bottomRight,
        fontSize: 20.0,
        color: 0xFF000000,
        opacity: 0.8,
        rotation: -15.0,
        isEnabled: true,
        isDefault: false,
      );

      expect(watermark.name, equals('公司水印'));
      expect(watermark.type, equals(WatermarkType.visible));
      expect(watermark.content, equals('仅限内部使用'));
      expect(watermark.position, equals(WatermarkPosition.bottomRight));
      expect(watermark.fontSize, equals(20.0));
      expect(watermark.color, equals(0xFF000000));
      expect(watermark.opacity, equals(0.8));
      expect(watermark.rotation, equals(-15.0));
      expect(watermark.isEnabled, isTrue);
      expect(watermark.isDefault, isFalse);
      expect(watermark.id, isNotEmpty);
      expect(watermark.createdAt, isA<DateTime>());
      expect(watermark.updatedAt, isA<DateTime>());
    });

    test('应该使用默认值创建WatermarkConfig实例', () {
      final watermark = WatermarkConfig(
        name: '默认水印',
        type: WatermarkType.invisible,
        content: '隐藏信息',
      );

      expect(watermark.name, equals('默认水印'));
      expect(watermark.type, equals(WatermarkType.invisible));
      expect(watermark.content, equals('隐藏信息'));
      expect(watermark.position, equals(WatermarkPosition.bottomRight));
      expect(watermark.fontSize, equals(24.0));
      expect(watermark.color, isNull);
      expect(watermark.opacity, equals(0.7));
      expect(watermark.rotation, equals(0.0));
      expect(watermark.isEnabled, isTrue);
      expect(watermark.isDefault, isFalse);
    });

    test('copyWith应该正确更新字段', () {
      final original = WatermarkConfig(
        name: '原始水印',
        type: WatermarkType.visible,
        content: '原始内容',
        fontSize: 16.0,
        opacity: 0.5,
      );

      final updated = original.copyWith(
        name: '更新水印',
        content: '更新内容',
        fontSize: 24.0,
        opacity: 0.8,
        color: 0xFF0000FF,
        rotation: 45.0,
        isEnabled: false,
        isDefault: true,
      );

      expect(updated.id, equals(original.id));
      expect(updated.type, equals(original.type));
      expect(updated.position, equals(original.position));
      expect(updated.name, equals('更新水印'));
      expect(updated.content, equals('更新内容'));
      expect(updated.fontSize, equals(24.0));
      expect(updated.opacity, equals(0.8));
      expect(updated.color, equals(0xFF0000FF));
      expect(updated.rotation, equals(45.0));
      expect(updated.isEnabled, isFalse);
      expect(updated.isDefault, isTrue);
    });

    test('toMap应该正确序列化数据', () {
      final watermark = WatermarkConfig(
        name: '测试水印',
        type: WatermarkType.visible,
        content: '测试内容',
        position: WatermarkPosition.topLeft,
        fontSize: 18.0,
        color: 0xFFFF0000,
        opacity: 0.9,
        rotation: 30.0,
        isEnabled: true,
        isDefault: true,
      );

      final map = watermark.toMap();

      expect(map['name'], equals('测试水印'));
      expect(map['type'], equals(WatermarkType.visible.index));
      expect(map['content'], equals('测试内容'));
      expect(map['position'], equals(WatermarkPosition.topLeft.index));
      expect(map['fontSize'], equals(18.0));
      expect(map['color'], equals(0xFFFF0000));
      expect(map['opacity'], equals(0.9));
      expect(map['rotation'], equals(30.0));
      expect(map['isEnabled'], equals(1));
      expect(map['isDefault'], equals(1));
      expect(map['id'], isNotEmpty);
      expect(map['createdAt'], isA<int>());
      expect(map['updatedAt'], isA<int>());
    });

    test('fromMap应该正确反序列化数据', () {
      final map = {
        'id': 'test-watermark-123',
        'name': '反序列化水印',
        'type': WatermarkType.invisible.index,
        'content': '隐藏内容',
        'position': WatermarkPosition.center.index,
        'fontSize': 22.0,
        'color': 0xFF00FF00,
        'opacity': 0.6,
        'rotation': -10.0,
        'isEnabled': 1,
        'isDefault': 0,
        'createdAt': 1640995200000, // 2022-01-01 00:00:00 UTC
        'updatedAt': 1640995200000,
      };

      final watermark = WatermarkConfig.fromMap(map);

      expect(watermark.id, equals('test-watermark-123'));
      expect(watermark.name, equals('反序列化水印'));
      expect(watermark.type, equals(WatermarkType.invisible));
      expect(watermark.content, equals('隐藏内容'));
      expect(watermark.position, equals(WatermarkPosition.center));
      expect(watermark.fontSize, equals(22.0));
      expect(watermark.color, equals(0xFF00FF00));
      expect(watermark.opacity, equals(0.6));
      expect(watermark.rotation, equals(-10.0));
      expect(watermark.isEnabled, isTrue);
      expect(watermark.isDefault, isFalse);
      expect(
        watermark.createdAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
      expect(
        watermark.updatedAt,
        equals(DateTime.fromMillisecondsSinceEpoch(1640995200000)),
      );
    });

    test('fromMap应该处理默认值', () {
      final map = {
        'id': 'test-watermark-456',
        'name': '默认值水印',
        'type': WatermarkType.visible.index,
        'content': '默认内容',
        'position': WatermarkPosition.bottomRight.index,
        'isEnabled': 1,
        'isDefault': 0,
        'createdAt': 1640995200000,
        'updatedAt': 1640995200000,
      };

      final watermark = WatermarkConfig.fromMap(map);

      expect(watermark.fontSize, equals(24.0));
      expect(watermark.color, isNull);
      expect(watermark.opacity, equals(0.7));
      expect(watermark.rotation, equals(0.0));
    });

    test('defaultVisible应该创建正确的默认显性水印', () {
      final watermark = WatermarkConfig.defaultVisible();

      expect(watermark.name, equals('默认显性水印'));
      expect(watermark.type, equals(WatermarkType.visible));
      expect(watermark.content, equals('仅限内部使用'));
      expect(watermark.position, equals(WatermarkPosition.bottomRight));
      expect(watermark.fontSize, equals(20.0));
      expect(watermark.color, equals(0xFF000000));
      expect(watermark.opacity, equals(0.8));
      expect(watermark.rotation, equals(-15.0));
      expect(watermark.isEnabled, isTrue);
      expect(watermark.isDefault, isTrue);
    });

    test('defaultInvisible应该创建正确的默认暗水印', () {
      final watermark = WatermarkConfig.defaultInvisible();

      expect(watermark.name, equals('默认暗水印'));
      expect(watermark.type, equals(WatermarkType.invisible));
      expect(watermark.content, equals('{{timestamp}}'));
      expect(watermark.position, equals(WatermarkPosition.random));
      expect(watermark.fontSize, equals(12.0));
      expect(watermark.color, isNull);
      expect(watermark.opacity, equals(0.1));
      expect(watermark.rotation, equals(0.0));
      expect(watermark.isEnabled, isTrue);
      expect(watermark.isDefault, isTrue);
    });

    test('相等性比较应该正确工作', () {
      final wm1 = WatermarkConfig(
        id: 'same-id',
        name: '水印1',
        type: WatermarkType.visible,
        content: '内容1',
      );

      final wm2 = WatermarkConfig(
        id: 'same-id',
        name: '水印2', // 不同内容
        type: WatermarkType.invisible,
        content: '内容2',
      );

      final wm3 = WatermarkConfig(
        id: 'different-id',
        name: '水印1',
        type: WatermarkType.visible,
        content: '内容1',
      );

      expect(wm1, equals(wm2)); // 相同ID
      expect(wm1, isNot(equals(wm3))); // 不同ID
      expect(wm1.hashCode, equals(wm2.hashCode));
      expect(wm1.hashCode, isNot(equals(wm3.hashCode)));
    });

    test('toString应该返回有意义的字符串', () {
      final watermark = WatermarkConfig(
        name: '测试水印',
        type: WatermarkType.visible,
        content: '测试内容',
      );

      final str = watermark.toString();
      expect(str, contains('WatermarkConfig'));
      expect(str, contains('测试水印'));
      expect(str, contains('visible'));
      expect(str, contains('测试内容'));
    });

    test('WatermarkType枚举应该正确工作', () {
      expect(WatermarkType.visible.index, equals(0));
      expect(WatermarkType.invisible.index, equals(1));
      expect(WatermarkType.values.length, equals(2));
    });

    test('WatermarkPosition枚举应该正确工作', () {
      expect(WatermarkPosition.topLeft.index, equals(0));
      expect(WatermarkPosition.topRight.index, equals(1));
      expect(WatermarkPosition.bottomLeft.index, equals(2));
      expect(WatermarkPosition.bottomRight.index, equals(3));
      expect(WatermarkPosition.center.index, equals(4));
      expect(WatermarkPosition.random.index, equals(5));
      expect(WatermarkPosition.values.length, equals(6));
    });
  });
}
