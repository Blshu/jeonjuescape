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
    expect(find.text('지도 보기'), findsOneWidget);
  });

  test('스테이지가 요청한 동선 순서로 배치된다', () {
    expect(
      stages.map((stage) => stage.location),
      orderedEquals(['삼나무 숲', '홍매화 동산', '유리온실 (AR 관찰)', '칠엽수 숲길', '낙우송 연못']),
    );
    expect(stages.where((stage) => stage.showsPlantCore).single.id, 5);
    expect(nextLocationClueFor(stages.last), isNull);
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
