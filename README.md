# 전주수목원: 코드 그린

수목원 현장에서 GPS로 구역을 발견하고, 쪽지 단서를 확인한 뒤 교육용 문제를 푸는 Flutter 앱입니다.

## 실행

```powershell
flutter pub get
flutter run
```

메인 화면의 `수목원 탐색 시작 · AR 단서 찾기`를 누르면 탐색 화면이 열립니다. 위치 권한을 허용하면 구역 반경 안에서 문제가 자동으로 열리고, 현장 테스트가 필요하면 각 구역의 `체험하기` 버튼을 사용할 수 있습니다.

## 현장 좌표 설정

실제 안내판 또는 GPS 측량 좌표는 `lib/quiz_data.dart`의 각 `StageInfo`에 있는 `latitude`, `longitude`, `discoveryRadius` 값을 현장값으로 교체합니다. 현재 좌표는 개발 테스트용 예시값입니다.

구역에 들어가면 ARCore/ARKit 기반의 AR 단서 탐색 화면이 열립니다. 휴대폰을 천천히 움직여 바닥이나 벽을 인식하고, 표시된 평면을 누르면 `assets/models/`의 쪽지 GLB 모델이 실제 공간에 고정됩니다. 3D 쪽지를 확인한 뒤 `이 AR 쪽지를 발견했습니다`와 `발견한 쪽지 열기`를 차례로 누르면 문제가 열립니다.

- Android에서는 Android 7.0(API 24) 이상, ARCore 지원 기기, Google Play AR 서비스, 카메라와 위치 권한이 필요합니다.
- iOS에서는 iOS 15 이상, ARKit 지원 기기, 카메라와 위치 권한이 필요합니다.
- 실제 AR 추적 테스트는 Android의 ARCore 디버그 추적 문제를 피하기 위해 `flutter run --profile` 또는 릴리스 빌드를 권장합니다.

## AR 쪽지 GLB 설정

기본 모델 파일을 다음 경로에 넣습니다.

```text
assets/models/clue.glb
```

`assets/models/` 폴더 전체가 `pubspec.yaml`에 등록되어 있으므로 GLB를 추가한 후 앱을 다시 빌드하면 됩니다. 스테이지마다 다른 쪽지를 사용하려면 `lib/quiz_data.dart`의 해당 `StageInfo`에서 경로와 크기를 지정합니다.

```dart
arModelAsset: 'assets/models/stage_5.glb',
arModelScale: 0.15,
```

GLB에는 텍스처를 포함하고, 가능하면 `1 단위 = 1m` 기준으로 제작하세요. 모델이 너무 크거나 작으면 `arModelScale`만 조절하면 됩니다. 파일이 없거나 경로가 잘못되면 AR 화면이 시작되기 전에 정확한 누락 경로가 표시됩니다.

## 현재 문제
1. 아이폰은 Impector로 SideStore를 사이드로딩 후 개발자 모드를 켜고 LocalDevVPN까지 킨 후에 .ipa 파일을 사이드로딩해서 설치해야 해서 불편함. 하지만 앱스토어에 올릴려면 연 12만원을 내야 할수 있음.


## APK / IPA 다운로드 방법
1. Release에 있는걸 누른다.
3. Assets를 펼치고 아이폰은 IPA, 안드로이드는 APK를 받는다.