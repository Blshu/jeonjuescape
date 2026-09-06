import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'ar_clue_screen.dart';
import 'quiz_data.dart';
import 'quiz_screen.dart';

class ExplorationScreen extends StatefulWidget {
  final Set<int> discoveredStageIds;
  final ValueChanged<StageInfo> onClueDiscovered;
  final ValueChanged<StageInfo> onStageSolved;

  const ExplorationScreen({
    super.key,
    required this.discoveredStageIds,
    required this.onClueDiscovered,
    required this.onStageSolved,
  });

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen> {
  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  String _locationStatus = '위치 권한을 확인하는 중...';
  bool _isLoadingLocation = true;
  final Set<int> _arOpenedStageIds = <int>{};

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _setLocationStatus('위치 서비스를 켜면 현장 구역을 자동으로 발견합니다.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _setLocationStatus('위치 권한이 없어 체험 모드로 진행합니다.');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    _updatePosition(position);
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_updatePosition);
  }

  void _setLocationStatus(String status) {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = false;
      _locationStatus = status;
    });
  }

  void _updatePosition(Position position) {
    if (!mounted) return;
    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
      _locationStatus = '현재 위치를 기준으로 구역을 확인하고 있습니다.';
    });

    for (final stage in stages) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stage.latitude,
        stage.longitude,
      );
      if (distance <= stage.discoveryRadius) {
        _activateAr(stage);
        break;
      }
    }
  }

  Future<void> _activateAr(StageInfo stage) async {
    if (!mounted ||
        widget.discoveredStageIds.contains(stage.id) ||
        _arOpenedStageIds.contains(stage.id)) {
      return;
    }
    _arOpenedStageIds.add(stage.id);
    final clueFound = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ArClueScreen(stage: stage)),
    );
    if (!mounted) return;
    if (clueFound != true) {
      _arOpenedStageIds.remove(stage.id);
      return;
    }
    widget.onClueDiscovered(stage);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('쪽지 발견: ${stage.location}의 문제가 열렸습니다.'),
        backgroundColor: Colors.green[800],
      ),
    );
    _openStage(stage);
  }

  void _openStage(StageInfo stage) {
    if (!widget.discoveredStageIds.contains(stage.id)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
              stage: stage,
              arActivated: true,
              onSolved: (_) => widget.onStageSolved(stage),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('현장 탐색 · AR 단서'),
        backgroundColor: Colors.green[900],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLocationBanner(),
          const SizedBox(height: 16),
          const Text(
            '구역에 들어가 쪽지를 발견하세요',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            '구역에 들어가면 AR 화면이 열립니다. 휴대폰을 움직여 단서를 찾은 뒤 쪽지를 확인하세요.',
            style: TextStyle(color: Colors.grey[400], height: 1.4),
          ),
          const SizedBox(height: 16),
          ...stages.map(_buildStageCard),
        ],
      ),
    );
  }

  Widget _buildLocationBanner() {
    final positionText = _currentPosition == null
        ? ''
        : '\n${_currentPosition!.latitude.toStringAsFixed(5)}, '
            '${_currentPosition!.longitude.toStringAsFixed(5)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[950],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          _isLoadingLocation
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
              : const Icon(Icons.my_location, color: Colors.greenAccent, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$_locationStatus$positionText', style: const TextStyle(height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(StageInfo stage) {
    final isDiscovered = widget.discoveredStageIds.contains(stage.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDiscovered ? Colors.green[950] : Colors.grey[850],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isDiscovered ? Colors.green : Colors.grey[700],
          child: Icon(isDiscovered ? Icons.visibility : Icons.lock_outline),
        ),
        title: Text(stage.location),
        subtitle: Text(isDiscovered ? 'AR 단서 활성화 · 문제를 풀 수 있습니다' : '구역에 들어가면 쪽지가 나타납니다'),
        trailing: isDiscovered
            ? IconButton(
                tooltip: '문제 열기',
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _openStage(stage),
              )
            : TextButton(
                onPressed: () => _activateAr(stage),
                child: const Text('AR 체험'),
              ),
        onTap: isDiscovered ? () => _openStage(stage) : null,
      ),
    );
  }
}