# AR 쪽지 GLB 모델

기본 AR 쪽지 모델은 아래 경로에 넣습니다.

```text
assets/models/clue.glb
```

모든 스테이지는 기본적으로 이 파일을 사용합니다. 스테이지마다 다른 모델이나 크기를 사용하려면 `lib/quiz_data.dart`의 `StageInfo`에 `arModelAsset`과 `arModelScale`을 지정합니다.

Example:

```dart
arModelAsset: 'assets/models/stage_5.glb',
arModelScale: 0.15,
```

텍스처가 포함된 binary glTF 2.0(`.glb`) 파일을 사용하세요. 모델 원점은 쪽지 중심 또는 바닥에 가깝게 두고, 가능하면 실제 단위(1 단위 = 1m)를 사용하세요. 파일을 추가한 뒤에는 앱을 다시 빌드해야 에셋 번들에 포함됩니다.
