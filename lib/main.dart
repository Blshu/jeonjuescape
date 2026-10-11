import 'package:flutter/material.dart';
import 'quiz_data.dart';
import 'quiz_screen.dart';
import 'exploration_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121814),
        primaryColor: Colors.greenAccent,
      ),
      home: const ArboretumMainScreen(),
    ),
  );
}

class ArboretumMainScreen extends StatefulWidget {
  const ArboretumMainScreen({super.key});

  @override
  State<ArboretumMainScreen> createState() => _ArboretumMainScreenState();
}

class _ArboretumMainScreenState extends State<ArboretumMainScreen> {
  static const String _mapAssetPath = 'assets/images/arboretum_map.png';

  // 5자리 비밀번호 정답: 7 1 1 3 5
  final List<String> targetPin = ["7", "1", "1", "3", "5"];
  // 플레이어가 해금한 숫자 저장 리스트
  List<String?> unlockedDigits = [null, null, null, null, null];
  final Set<int> discoveredStageIds = <int>{};

  void _onClueDiscovered(StageInfo stage) {
    setState(() => discoveredStageIds.add(stage.id));
  }

  void _onStageCleared(int stageIndex, String digit) {
    setState(() {
      unlockedDigits[stageIndex] = digit;
    });

    // 5자리 모두 해금되었는지 체크
    if (!unlockedDigits.contains(null)) {
      Future.delayed(Duration(milliseconds: 300), () => _showEndingDialog());
    }
  }

  void _openExploration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExplorationScreen(
          discoveredStageIds: discoveredStageIds,
          onClueDiscovered: _onClueDiscovered,
          onStageSolved: (stage) => _onStageCleared(stage.id - 1, stage.digit),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showMap() {
    final screenSize = MediaQuery.sizeOf(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.grey[900],
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '수목원 지도',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Image.asset(
                      _mapAssetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 56,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '지도 사진을 찾을 수 없습니다.',
                              style: TextStyle(fontSize: 17),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _mapAssetPath,
                              style: const TextStyle(color: Colors.greenAccent),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '위 경로에 지도 사진을 넣고 앱을 다시 빌드해 주세요.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          "🚨 비상 정화 시스템 가동 성공!",
          style: TextStyle(color: Colors.greenAccent),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "암호 [ 7 1 1 3 5 ] 가 정확히 입력되었습니다.\n"
                "수목원 정문이 열리며 식물들의 폭주가 가라앉습니다!\n\n"
                "스피커 너머 흑막의 당황한 목소리:\n"
                "\"말도 안 돼... 내 계산대로라면 전주수목원 사람들은 영원히 갇혔어야 했는데...!\"\n",
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              Divider(color: Colors.grey[700]),
              SizedBox(height: 8),
              Center(
                child: Text(
                  "🍀 식물지식인 제작",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  "앱 개발 / AR 연동 / 시나리오 - 이상혁\n"
                  "문제 아이디어 제공 및 문제 제작 - 원지호, 권도하, 김윤조\n"
                  "총괄 기획 - 선생님",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Colors.white70,
                  ),
                ),
              ),
              Center(
                child: Text(
                  "출처",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
              // 세상에서 가장 중요한 출처
              Center(
                child: Text(
                  "Scroll by Jakob Hippe [CC-BY] via Poly Pizza",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("탈출 성공", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🌿 전주수목원 : 코드 그린"),
        backgroundColor: Colors.green[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          // 상단 스토리 & 비밀번호 현황 보드
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "⚠️ 식물 코어 폭주 중! 5개의 암호를 해독해 탈출하라.",
                  style: TextStyle(fontSize: 13, color: Colors.orangeAccent),
                ),
                SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final digit = unlockedDigits[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      width: 48,
                      height: 58,
                      decoration: BoxDecoration(
                        color: digit != null
                            ? Colors.green[900]
                            : Colors.black45,
                        border: Border.all(
                          color: digit != null
                              ? Colors.greenAccent
                              : Colors.grey[700]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit ?? "?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: digit != null
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openExploration,
                icon: Icon(Icons.explore),
                label: Text("수목원 탐색 시작 · AR 단서 찾기"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _showMap,
                icon: Icon(Icons.map_outlined),
                label: Text("지도 보기"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.greenAccent,
                  side: BorderSide(color: Colors.greenAccent),
                ),
              ),
            ),
          ),

          // 수목원 탐색 구역 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                final stage = stages[index];
                final isCleared = unlockedDigits[stage.id - 1] != null;
                final isDiscovered = discoveredStageIds.contains(stage.id);

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  color: isCleared ? Colors.green[950] : Colors.grey[850],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCleared
                          ? Colors.greenAccent
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isCleared
                          ? Colors.green
                          : isDiscovered
                          ? Colors.orange[800]
                          : Colors.grey[700],
                      child: isCleared
                          ? Icon(Icons.check, color: Colors.white)
                          : Text(
                              "${index + 1}",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                    title: Text(
                      stage.location,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      stage.title,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    trailing: Icon(
                      isDiscovered ? Icons.lock_open : Icons.lock_outline,
                      size: 18,
                      color: isDiscovered ? Colors.greenAccent : Colors.grey,
                    ),
                    onTap: () {
                      if (!isDiscovered) {
                        _openExploration();
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            stage: stage,
                            arActivated: true,
                            onSolved: (digit) =>
                                _onStageCleared(stage.id - 1, digit),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
