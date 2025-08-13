import 'package:flutter_test/flutter_test.dart';

// 导入所有模型测试
import 'watermark_config_test.dart' as watermark_config_test;
import 'export_record_test.dart' as export_record_test;
import 'security_config_test.dart' as security_config_test;

void main() {
  group('数据模型测试套件', () {
    // 运行所有模型测试
    watermark_config_test.main();
    export_record_test.main();
    security_config_test.main();
  });
}
