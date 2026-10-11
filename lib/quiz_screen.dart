import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'quiz_data.dart';

class QuizScreen extends StatefulWidget {
  final StageInfo stage;
  final Function(String digit) onSolved;
  final bool arActivated;

  const QuizScreen({
    super.key,
    required this.stage,
    required this.onSolved,
    this.arActivated = false,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final nextLocationClue = nextLocationClueFor(widget.stage);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stage.location),
        backgroundColor: Colors.green[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.arActivated && widget.stage.showsPlantCore)
              Container(
                height: 250,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black45,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const ModelViewer(
                    src:
                        'https://modelviewer.dev/shared-assets/models/Astronaut.glb', // 테스트용 3D 샘플
                    alt: "AR 식물 코어 모델",
                    ar: true,
                    autoRotate: true,
                    cameraControls: true,
                  ),
                ),
              ),

            // 스테이지 타이틀
            Text(
              widget.stage.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 12),

            // 스토리 상황 지문 박스
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Text(
                widget.stage.story,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 문제 텍스트
            Text(
              "Q. ${widget.stage.question}",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // 객관식 보기 리스트
            ...List.generate(widget.stage.options.length, (idx) {
              final isSelected = selectedIndex == idx;
              return Card(
                color: isSelected ? Colors.green[800] : Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.greenAccent : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    widget.stage.options[idx],
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedIndex = idx;
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 24),

            // 정답 제출 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: selectedIndex == null
                    ? null
                    : () {
                        if (selectedIndex == widget.stage.answerIndex) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                "🎯 단서 해독 성공!",
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "정답입니다!\n획득한 탈출 암호 숫자: [ ${widget.stage.digit} ]",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    nextLocationClue == null
                                        ? "모든 장소의 단서를 찾았습니다. 이제 최종 암호를 확인하세요!"
                                        : "다음 장소 단서\n$nextLocationClue",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.orangeAccent,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    widget.onSolved(widget.stage.digit);
                                    Navigator.pop(dialogContext);
                                    Navigator.pop(context, true);
                                  },
                                  child: Text(
                                    nextLocationClue == null
                                        ? "탈출 결과 보기"
                                        : "다음 스테이지",
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⚠️ 틀렸습니다! 단서를 다시 읽어보세요."),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: const Text(
                  "정답 확인",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
