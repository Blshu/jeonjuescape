import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'quiz_data.dart';

class ArClueScreen extends StatelessWidget {
  final StageInfo stage;

  const ArClueScreen({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AR 단서 탐색 · 구역 ${stage.id}'),
        backgroundColor: Colors.black87,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ModelViewer(
              src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
              alt: 'AR 단서 모형',
              ar: true,
              autoRotate: true,
              cameraControls: true,
              backgroundColor: Colors.black,
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: _InstructionPanel(stage: stage),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.note_alt_outlined),
                label: const Text('단서를 발견했습니다 · 쪽지 열기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionPanel extends StatelessWidget {
  final StageInfo stage;

  const _InstructionPanel({required this.stage});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.threesixty, color: Colors.greenAccent),
                SizedBox(width: 8),
                Text(
                  'AR 탐색 활성화',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${stage.location} 주변을 천천히 비추며 쪽지를 찾으세요.',
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              '화면의 AR 버튼을 누른 뒤 휴대폰을 움직여 주변을 탐색합니다.',
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}