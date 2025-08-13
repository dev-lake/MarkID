import 'package:flutter/material.dart';
import 'lib/main.dart';
import 'lib/utils/app_initializer.dart';

/// 范例数据功能演示
class SampleDataDemo extends StatelessWidget {
  const SampleDataDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '范例数据演示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  String _status = '准备中...';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _runDemo();
  }

  Future<void> _runDemo() async {
    _addLog('开始演示范例数据功能...');

    // 重置应用状态
    await AppInitializer.resetAppState();
    _addLog('已重置应用状态');

    // 检查首次启动状态
    final isFirst = await AppInitializer.isFirstLaunch();
    _addLog('首次启动检测: ${isFirst ? "是" : "否"}');

    // 检查范例数据状态
    final isSampleAdded = await AppInitializer.isSampleDataAdded();
    _addLog('范例数据状态: ${isSampleAdded ? "已添加" : "未添加"}');

    // 执行应用初始化
    _addLog('执行应用初始化...');
    await AppInitializer.initializeApp();

    // 再次检查状态
    final isFirstAfter = await AppInitializer.isFirstLaunch();
    final isSampleAddedAfter = await AppInitializer.isSampleDataAdded();

    _addLog('初始化后首次启动状态: ${isFirstAfter ? "是" : "否"}');
    _addLog('初始化后范例数据状态: ${isSampleAddedAfter ? "已添加" : "未添加"}');

    setState(() {
      _status = '演示完成';
    });

    _addLog('演示完成！');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('范例数据功能演示'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '状态: $_status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '功能说明:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('• 检测应用是否首次启动'),
                    const Text('• 自动添加身份证范例数据'),
                    const Text('• 使用SharedPreferences持久化状态'),
                    const Text('• 确保范例数据只添加一次'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '演示日志:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _runDemo(),
                    child: const Text('重新运行演示'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyApp()),
                    ),
                    child: const Text('打开主应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 运行演示
void main() {
  runApp(const SampleDataDemo());
}
