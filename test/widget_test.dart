// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeonju_escape/main.dart';

void main() {
  testWidgets('탐색 시작 버튼이 메인 화면에 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ArboretumMainScreen()));

    expect(find.text('수목원 탐색 시작 · AR 단서 찾기'), findsOneWidget);
  });
}
