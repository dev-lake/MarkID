// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idseal/main.dart';
import 'package:idseal/providers/document_provider.dart';
import 'package:idseal/screens/document_list_screen.dart';

void main() {
  testWidgets('证件照片管理应用启动测试', (WidgetTester tester) async {
    // 构建应用
    await tester.pumpWidget(const MyApp());

    // 验证应用标题
    expect(find.text('证件照片'), findsOneWidget);

    // 验证添加按钮存在
    expect(find.text('添加证件'), findsOneWidget);

    // 验证空状态提示
    expect(find.text('暂无证件照片'), findsOneWidget);
    expect(find.text('点击右下角按钮添加证件照片'), findsOneWidget);
  });

  testWidgets('Provider基本功能测试', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 验证Provider正常工作
    final provider = tester
        .element(find.byType(DocumentListScreen))
        .read<DocumentProvider>();

    // 验证基本属性
    expect(provider.documents, isEmpty);
    expect(provider.filteredDocuments, isEmpty);
    expect(provider.searchQuery, isEmpty);
    expect(provider.selectedDocumentType, isEmpty);
    expect(provider.selectedTag, isEmpty);
  });
}
