/// 水印测试配置文件
///
/// 这个文件定义了水印测试中使用的常量和配置
class WatermarkTestConfig {
  /// 测试图片尺寸
  static const int smallImageSize = 100;
  static const int mediumImageSize = 300;
  static const int largeImageSize = 500;

  /// 性能测试时间限制（毫秒）
  static const int smallImageTimeLimit = 2000;
  static const int mediumImageTimeLimit = 3000;
  static const int largeImageTimeLimit = 5000;
  static const int batchProcessingTimeLimit = 10000;

  /// 测试水印文本
  static const List<String> testWatermarkTexts = [
    '仅限身份证使用',
    '仅限护照使用',
    '仅限驾驶证使用',
    '仅限学生证使用',
    '仅限工作证使用',
    '仅限社保卡使用',
  ];

  /// 测试透明度值
  static const List<double> testOpacities = [0.1, 0.3, 0.5, 0.7, 0.9];

  /// 测试角度值
  static const List<double> testAngles = [0.0, 15.0, 30.0, 45.0, 60.0, 90.0];

  /// 测试行列配置
  static const List<Map<String, int>> testGridConfigs = [
    {'rows': 1, 'columns': 1},
    {'rows': 2, 'columns': 2},
    {'rows': 3, 'columns': 3},
    {'rows': 4, 'columns': 2},
    {'rows': 2, 'columns': 4},
    {'rows': 6, 'columns': 4},
  ];

  /// 特殊字符测试文本
  static const List<String> specialCharacterTexts = [
    '!@#\$%^&*()_+-=[]{}|;:,.<>?',
    '测试水印 🎨 中文 English 123 !@#',
    'Unicode测试：🚀🌟💡📱',
    '特殊符号：©®™€£¥¢',
  ];

  /// 长文本测试
  static const int longTextLength = 1000;
  static const String longTextPattern = 'A';

  /// 错误测试数据
  static const List<int> corruptedImageData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
}
