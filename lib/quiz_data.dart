enum ArCluePlacementMode {
  /// 테스트용: AR 세션이 준비되면 사용자 전방 가까운 곳에 자동 배치합니다.
  randomNearby,

  /// 사용자가 인식된 평면을 눌렀을 때 배치합니다.
  tappedPlane,
}

class StageInfo {
  final int id;
  final String title;
  final String location;
  final String story;
  final String question;
  final List<String> options;
  final int answerIndex; // 0부터 시작
  final String digit; // 비밀번호 숫자
  final double latitude;
  final double longitude;
  final double discoveryRadius;
  final String? nextLocationClue;
  final String arModelAsset;
  final double arModelScale;
  final ArCluePlacementMode arPlacementMode;
  final bool showsPlantCore;

  StageInfo({
    required this.id,
    required this.title,
    required this.location,
    required this.story,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.digit,
    required this.latitude,
    required this.longitude,
    this.discoveryRadius = 80,
    this.nextLocationClue,
    this.arModelAsset = 'assets/models/clue.glb',
    this.arModelScale = 0.2,
    this.arPlacementMode = ArCluePlacementMode.randomNearby,
    this.showsPlantCore = false,
  }) : assert(arModelAsset.endsWith('.glb'), 'AR 모델은 GLB 파일이어야 합니다.'),
       assert(arModelScale > 0, 'AR 모델 배율은 0보다 커야 합니다.');
}

final List<StageInfo> _stageCatalog = [
  // 1번 스테이지: 칠엽수
  StageInfo(
    id: 1,
    title: "가시 껍질의 비밀",
    location: "칠엽수 숲길",
    story:
        "바닥에 떨어진 날카로운 가시 열매 사이에서 첫 번째 쪽지를 주웠다.\n'밤과 닮았지만 독이 있는 열매... 이 나무의 손바닥 모양 잎은 몇 장일까?'",
    question: "칠엽수(七葉樹)의 한 가지에 뭉쳐나는 잎의 개수는?",
    options: ["3장", "5장", "7장", "9장"],
    answerIndex: 2,
    digit: "7",
    latitude: 35.85150,
    longitude: 127.08850,
    nextLocationClue: "다음 쪽지는 곧게 뻗은 나무들이 빽빽한 숲길에 있습니다. 포도송이를 닮은 봄꽃을 찾아보세요.",
  ),

  // 2번 스테이지: 거만한 삼나무 (상혁이 오리지널 스토리!)
  StageInfo(
    id: 2,
    title: "거만한 삼나무 나뭇가지",
    location: "삼나무 숲",
    story:
        "비밀번호의 2번째 자리를 찾기 위해 하염없이 뛰다 거대한 삼나무를 발견했다.\n그런데 떨어진 나뭇가지가 스르륵 움직이더니 말을 걸었다.\n\"여기서 가장 필요하고 좋은 나무는 바로 나야! 내 퀴즈를 맞추면 원래는 안 알려주지만 2번째 자리를 알려주지.\" 잘난 척하는 게 어이가 없었다.",
    question: "포도송이를 닮아 '포도히아신스'라는 별명을 가진 봄꽃 식물은?",
    options: ["1. 무스카리", "2. 수선화", "3. 홍매화"],
    answerIndex: 0,
    digit: "1",
    latitude: 35.85185,
    longitude: 127.08880,
    nextLocationClue: "붉은 꽃잎이 봄바람에 흔들리는 동산으로 가세요. 가지 사이에 다음 쪽지가 숨어 있습니다.",
  ),

  // 3번 스테이지: 홍매화
  StageInfo(
    id: 3,
    title: "도발의 쪽지",
    location: "홍매화 동산",
    story: "붉은 매화나무 가지에 꽂힌 얄미운 쪽지:\n\"이 문제를 풀면 세 번째 비번을 주지. 하지만 넌 못 풀걸?\"",
    question: "홍매화와 같은 장미과(Prunus)에 속하는 형제 나무는 무엇일까요?",
    options: ["1. 복숭아나무", "2. 소나무", "3. 대나무"],
    answerIndex: 0,
    digit: "1",
    latitude: 35.85115,
    longitude: 127.08895,
    nextLocationClue: "연못가에서 물을 향해 솟아오른 이상한 나무뿌리를 찾으세요. 작은 스님이 길을 알려줄 것입니다.",
  ),

  // 4번 스테이지: 낙우송 연못
  StageInfo(
    id: 4,
    title: "솟아오른 기근",
    location: "낙우송 연못",
    story: "연못가를 따라 뛰어가는데 땅 위로 툭툭 솟아난 기묘한 나무뿌리들이 발을 붙잡았다. 팻말에 문제가 삐뚤빼뚤 적혀 있다.",
    question: "기도하는 스님을 닮은 낙우송의 돌출된 숨뿌리(기근)를 부르는 별명은?",
    options: ["1. 개구쟁이", "2. 꼬마 요정", "3. 꼬마 스님"],
    answerIndex: 2,
    digit: "3",
    latitude: 35.85180,
    longitude: 127.08815,
    nextLocationClue: "마지막 단서는 따뜻하고 투명한 집 안에 있습니다. 붉게 빛나는 열대 식물을 찾아 유리온실로 가세요.",
  ),

  // 5번 스테이지: 유리온실 (AR 관찰)
  StageInfo(
    id: 5,
    title: "각성의 진원지",
    location: "유리온실 (AR 관찰)",
    story:
        "네팔의 파동이 직격한 곳! 열대 식물들이 붉게 폭주하고 있다. AR 카메라로 식물의 3D 코어를 회전시켜 숨겨진 마지막 정화 번호를 읽어내야 한다.",
    question: "AR 3D 식물 코어에 새겨진 마지막 정화 숫자는?",
    options: ["1", "3", "5", "9"],
    answerIndex: 2,
    digit: "5",
    latitude: 35.85135,
    longitude: 127.08925,
    nextLocationClue: null,
    showsPlantCore: true,
  ),
];

// 실제 이동과 자동 진행 순서입니다. id는 기존 5자리 암호의 자릿수를 유지합니다.
final List<StageInfo> stages = [
  _stageCatalog[1], // 삼나무 숲
  _stageCatalog[2], // 홍매화
  _stageCatalog[4], // 유리온실 식물 코어
  _stageCatalog[0], // 칠엽수
  _stageCatalog[3], // 낙우송
];

String? nextLocationClueFor(StageInfo stage) {
  final currentIndex = stages.indexWhere(
    (candidate) => candidate.id == stage.id,
  );
  if (currentIndex < 0 || currentIndex == stages.length - 1) return null;

  return switch (stage.id) {
    2 => '붉은 꽃잎이 봄바람에 흔들리는 홍매화 동산으로 가세요.',
    3 => '따뜻하고 투명한 유리온실로 가세요. 붉게 빛나는 식물 코어가 다음 단서를 숨기고 있습니다.',
    5 => '유리온실을 나와 손바닥 모양의 잎이 펼쳐진 칠엽수 숲길로 가세요.',
    1 => '연못가에서 물을 향해 솟아오른 낙우송의 숨뿌리를 찾으세요.',
    _ => '다음 장소는 ${stages[currentIndex + 1].location}입니다.',
  };
}
