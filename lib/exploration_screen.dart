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
  final StageInfo? initialStage;

  const ExplorationScreen({
    super.key,
    required this.discoveredStageIds,
    required this.onClueDiscovered,
    required this.onStageSolved,
    this.initialStage,
  });

  @override
  State<ExplorationScreen> createState() => _ExplorationScreenState();
}

class _ExplorationScreenState extends State<ExplorationScreen>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  Position? _currentPosition;
  String _locationStatus = '위치 권한을 확인하는 중...';
  bool _isLoadingLocation = true;
  int _locationAttempt = 0;
  bool _isStageFlowActive = false;
  final Set<int> _arOpenedStageIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeLocationTracking());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialStage = widget.initialStage;
      if (initialStage != null) {
        _beginStageFlow(initialStage);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationAttempt++;
    _positionSubscription?.cancel();
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listenForLocationServiceChanges();
      unawaited(_startLocationTracking(requestPermission: false));
    }
  }

  Future<void> _initializeLocationTracking() async {
    await _startLocationTracking();
    if (!mounted) return;
    _listenForLocationServiceChanges();
  }

  void _listenForLocationServiceChanges() {
    if (_serviceStatusSubscription != null) return;
    try {
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen(
        (status) => unawaited(_handleLocationServiceStatus(status)),
        onError: (Object error) {
          final subscription = _serviceStatusSubscription;
          _serviceStatusSubscription = null;
          if (subscription != null) {
            unawaited(subscription.cancel());
          }
          _handleLocationError(
            error,
            fallbackMessage: '위치 서비스 상태를 확인하지 못했습니다. 새로고침 버튼으로 다시 시도해 주세요.',
          );
        },
        onDone: () {
          _serviceStatusSubscription = null;
          _setLocationStatus(
            '위치 서비스 상태 감시가 중단됐습니다. 새로고침 버튼으로 다시 연결해 주세요.',
            clearPosition: true,
          );
        },
      );
    } catch (error) {
      _handleLocationError(
        error,
        fallbackMessage: '위치 서비스 상태 감시를 시작하지 못했습니다. 새로고침 버튼으로 다시 시도해 주세요.',
      );
    }
  }

  Future<void> _handleLocationServiceStatus(ServiceStatus status) async {
    if (!mounted) return;
    if (status == ServiceStatus.disabled) {
      _locationAttempt++;
      await _stopPositionTracking();
      _setLocationStatus(
        '위치 서비스가 꺼졌습니다. 기기 설정에서 GPS를 켜면 자동으로 다시 연결합니다.',
        clearPosition: true,
      );
      return;
    }
    await _startLocationTracking(requestPermission: false);
  }

  Future<void> _startLocationTracking({bool requestPermission = true}) async {
    final attempt = ++_locationAttempt;
    _setLocationStatus(
      '현재 위치를 확인하는 중...',
      isLoading: true,
      clearPosition: true,
    );
    await _stopPositionTracking();
    if (!mounted || attempt != _locationAttempt) return;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted || attempt != _locationAttempt) return;
      if (!serviceEnabled) {
        _setLocationStatus(
          '위치 서비스가 꺼져 있습니다. 기기 설정에서 GPS를 켜면 현장 구역을 다시 탐색합니다.',
          clearPosition: true,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (!mounted || attempt != _locationAttempt) return;
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted || attempt != _locationAttempt) return;
      if (permission == LocationPermission.deniedForever) {
        _setLocationStatus(
          '위치 권한이 차단됐습니다. 기기 설정에서 이 앱의 위치 권한을 허용해 주세요.',
          clearPosition: true,
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _setLocationStatus(
          '위치 권한이 없어 체험 모드로 진행합니다. 권한을 허용한 뒤 새로고침을 눌러 주세요.',
          clearPosition: true,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted || attempt != _locationAttempt) return;
      _updatePosition(position);

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            (nextPosition) {
              if (attempt == _locationAttempt) {
                _updatePosition(nextPosition);
              }
            },
            onError: (Object error) {
              if (attempt == _locationAttempt) {
                _handleLocationError(
                  error,
                  fallbackMessage: 'GPS 위치 업데이트가 중단됐습니다. 잠시 후 새로고침을 눌러 주세요.',
                );
              }
            },
            onDone: () {
              if (attempt != _locationAttempt) return;
              _positionSubscription = null;
              _setLocationStatus(
                'GPS 위치 업데이트 연결이 종료됐습니다. 새로고침을 눌러 다시 연결해 주세요.',
                clearPosition: true,
              );
            },
          );
    } on TimeoutException catch (error) {
      if (attempt == _locationAttempt) {
        _handleLocationError(error);
      }
    } on LocationServiceDisabledException catch (error) {
      if (attempt == _locationAttempt) {
        _handleLocationError(error);
      }
    } on PermissionDeniedException catch (error) {
      if (attempt == _locationAttempt) {
        _handleLocationError(error);
      }
    } catch (error) {
      if (attempt == _locationAttempt) {
        _handleLocationError(
          error,
          fallbackMessage: 'GPS에서 위치를 가져오지 못했습니다. 신호 상태를 확인한 뒤 새로고침을 눌러 주세요.',
        );
      }
    }
  }

  Future<void> _stopPositionTracking() async {
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
  }

  void _handleLocationError(Object error, {String? fallbackMessage}) {
    final message = switch (error) {
      TimeoutException() =>
        'GPS 응답이 지연되고 있습니다. 하늘이 보이는 곳으로 이동한 뒤 새로고침을 눌러 주세요.',
      LocationServiceDisabledException() =>
        '위치 서비스가 중단됐습니다. 기기 설정에서 GPS를 켜면 자동으로 다시 연결합니다.',
      PermissionDeniedException() =>
        '위치 권한이 거부되었습니다. 기기 설정에서 이 앱의 위치 권한을 확인해 주세요.',
      _ => fallbackMessage ?? '위치를 확인하는 중 오류가 발생했습니다. 새로고침을 눌러 다시 시도해 주세요.',
    };
    _setLocationStatus(message, clearPosition: true);
  }

  void _setLocationStatus(
    String status, {
    bool isLoading = false,
    bool clearPosition = false,
  }) {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = isLoading;
      _locationStatus = status;
      if (clearPosition) {
        _currentPosition = null;
      }
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
        _beginStageFlow(stage);
        break;
      }
    }
  }

  Future<void> _beginStageFlow(StageInfo stage) async {
    if (!mounted || _isStageFlowActive) return;
    _isStageFlowActive = true;
    try {
      await _openStageOrAr(stage);
    } finally {
      _isStageFlowActive = false;
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
    await _openStage(stage);
  }

  Future<void> _openStageOrAr(StageInfo stage) async {
    if (widget.discoveredStageIds.contains(stage.id)) {
      await _openStage(stage);
    } else {
      await _activateAr(stage);
    }
  }

  Future<void> _openStage(StageInfo stage) async {
    if (!widget.discoveredStageIds.contains(stage.id)) return;
    final solved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          stage: stage,
          arActivated: true,
          onSolved: (_) => widget.onStageSolved(stage),
        ),
      ),
    );
    if (!mounted || solved != true) return;

    final stageIndex = stages.indexWhere(
      (candidate) => candidate.id == stage.id,
    );
    final isLastStage = stageIndex < 0 || stageIndex == stages.length - 1;
    if (isLastStage) {
      Navigator.pop(context, true);
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _openStageOrAr(stages[stageIndex + 1]);
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
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                )
              : const Icon(
                  Icons.my_location,
                  color: Colors.greenAccent,
                  size: 26,
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_locationStatus$positionText',
              style: const TextStyle(height: 1.4),
            ),
          ),
          if (!_isLoadingLocation && _currentPosition == null)
            IconButton(
              tooltip: '위치 다시 확인',
              color: Colors.greenAccent,
              onPressed: () {
                _listenForLocationServiceChanges();
                unawaited(_startLocationTracking());
              },
              icon: const Icon(Icons.refresh),
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
        subtitle: Text(
          isDiscovered ? 'AR 단서 활성화 · 문제를 풀 수 있습니다' : '구역에 들어가면 쪽지가 나타납니다',
        ),
        trailing: isDiscovered
            ? IconButton(
                tooltip: '문제 열기',
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () => _beginStageFlow(stage),
              )
            : TextButton(
                onPressed: () => _beginStageFlow(stage),
                child: const Text('AR 체험'),
              ),
        onTap: isDiscovered ? () => _beginStageFlow(stage) : null,
      ),
    );
  }
}
