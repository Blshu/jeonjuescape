// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeonju_escape/main.dart';
import 'package:jeonju_escape/quiz_data.dart';

void main() {
  testWidgets('탐색 시작 버튼이 메인 화면에 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ArboretumMainScreen()));

    expect(find.text('수목원 탐색 시작 · AR 단서 찾기'), findsOneWidget);
  });

  test('모든 스테이지의 AR 모델 설정이 유효하다', () {
    for (final stage in stages) {
      expect(stage.arModelAsset, startsWith('assets/models/'));
      expect(stage.arModelAsset.toLowerCase(), endsWith('.glb'));
      expect(stage.arModelScale, greaterThan(0));
      expect(stage.arPlacementMode, ArCluePlacementMode.randomNearby);
    }
  });
}
