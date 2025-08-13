import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/document_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/backup_provider.dart';
import 'screens/document_list_screen.dart';
import 'screens/document_detail_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/icloud_sync_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/photo_management_screen.dart';
import 'services/document_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 延迟初始化自动备份服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAutoBackup();
    });
  }

  void _initializeAutoBackup() {
    // 这里需要等待Provider初始化完成后再启动自动备份服务
    // 在实际应用中，应该在Provider初始化完成后调用
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProxyProvider<DocumentProvider, SyncProvider>(
          create: (context) => SyncProvider(DocumentService()),
          update: (context, documentProvider, previous) =>
              previous ?? SyncProvider(DocumentService()),
        ),
        ChangeNotifierProxyProvider<DocumentProvider, BackupProvider>(
          create: (context) => BackupProvider(DocumentService()),
          update: (context, documentProvider, previous) =>
              previous ?? BackupProvider(DocumentService()),
        ),
      ],
      child: MaterialApp(
        title: '马克证件',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const DocumentListScreen(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
          '/permissions': (context) => const PermissionScreen(),
          '/icloud-sync': (context) => const ICloudSyncScreen(),
          '/photo-management': (context) => PhotoManagementScreen(
            documentId: ModalRoute.of(context)!.settings.arguments as String,
          ),
        },
      ),
    );
  }
}
