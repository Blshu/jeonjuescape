import 'dart:async';
import 'dart:math' as math;

import 'package:ar_flutter_plugin_plus/ar_flutter_plugin_plus.dart';
import 'package:ar_flutter_plugin_plus/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_plus/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_plus/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_plus/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_plus/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_plus/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_plus/models/ar_node.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

import 'quiz_data.dart';

class ArClueScreen extends StatefulWidget {
  final StageInfo stage;

  const ArClueScreen({super.key, required this.stage});

  @override
  State<ArClueScreen> createState() => _ArClueScreenState();
}

class _ArClueScreenState extends State<ArClueScreen> {
  ARSessionManager? _arSessionManager;
  ARObjectManager? _arObjectManager;
  ARAnchorManager? _arAnchorManager;
  ARPlaneAnchor? _clueAnchor;
  ARNode? _clueNode;
  final math.Random _random = math.Random();

  Key _arViewKey = UniqueKey();
  int _placementAttempt = 0;
  bool _isCheckingAsset = true;
  bool _modelAssetReady = false;
  bool _arReady = false;
  bool _isPlacing = false;
  bool _modelPlaced = false;
  bool _clueFound = false;
  String? _assetError;
  String? _arError;
  String _statusMessage = 'AR 쪽지 모델을 확인하는 중입니다.';

  bool get _supportsArPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _usesRandomNearbyPlacement =>
      widget.stage.arPlacementMode == ArCluePlacementMode.randomNearby;

  @override
  void initState() {
    super.initState();
    unawaited(_validateModelAsset());
  }

  Future<void> _validateModelAsset() async {
    if (mounted) {
      setState(() {
        _isCheckingAsset = true;
        _assetError = null;
        _modelAssetReady = false;
      });
    }

    final modelPath = widget.stage.arModelAsset;
    try {
      if (!modelPath.toLowerCase().endsWith('.glb')) {
        throw const FormatException('AR 모델은 GLB 형식이어야 합니다.');
      }
      if (!widget.stage.arModelScale.isFinite ||
          widget.stage.arModelScale <= 0) {
        throw const FormatException('AR 모델 배율은 0보다 커야 합니다.');
      }

      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!assetManifest.listAssets().contains(modelPath)) {
        throw FlutterError('등록된 에셋에서 $modelPath 파일을 찾을 수 없습니다.');
      }

      if (!mounted) return;
      setState(() {
        _isCheckingAsset = false;
        _modelAssetReady = true;
        _statusMessage = _usesRandomNearbyPlacement
            ? '카메라를 켜고 사용자 근처에 쪽지를 준비하고 있습니다.'
            : '휴대폰을 천천히 움직여 바닥이나 벽을 인식해 주세요.';
      });
    } on FormatException catch (error) {
      _setAssetError(error.message);
    } catch (_) {
      _setAssetError('`$modelPath` 파일을 찾을 수 없습니다. 파일을 추가한 뒤 앱을 다시 빌드해 주세요.');
    }
  }

  void _setAssetError(String message) {
    if (!mounted) return;
    setState(() {
      _isCheckingAsset = false;
      _modelAssetReady = false;
      _assetError = message;
    });
  }

  void _onARViewCreated(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
    ARAnchorManager anchorManager,
    ARLocationManager locationManager,
  ) {
    _arSessionManager = sessionManager;
    _arObjectManager = objectManager;
    _arAnchorManager = anchorManager;

    sessionManager.onPlaneOrPointTap = _onPlaneOrPointTapped;
    sessionManager.onTrackingStateChanged = _onTrackingStateChanged;
    objectManager.onNodeTap = _onNodeTapped;

    unawaited(_initializeArSession(sessionManager, objectManager));
  }

  Future<void> _initializeArSession(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    try {
      await sessionManager.onInitialize(
        showAnimatedGuide: !_usesRandomNearbyPlacement,
        autoHideCoachingOverlay: true,
        showFeaturePoints: false,
        showPlanes: !_usesRandomNearbyPlacement,
        showWorldOrigin: false,
        handleTaps: !_usesRandomNearbyPlacement,
        handlePans: false,
        handleRotation: false,
        lightIntensityMultiplier: 1.2,
      );
      objectManager.onInitialize(iosScaleFactor: 1, androidScaleFactor: 1);

      if (!mounted || sessionManager != _arSessionManager) return;
      setState(() {
        _arReady = true;
        _statusMessage = _usesRandomNearbyPlacement
            ? '사용자 근처의 무작위 위치에 AR 쪽지를 놓는 중입니다.'
            : '평면이 표시되면 쪽지를 놓을 위치를 한 번 눌러 주세요.';
      });

      if (_usesRandomNearbyPlacement) {
        unawaited(_placeRandomClueNearUser(sessionManager, objectManager));
      }
    } catch (error) {
      if (!mounted || sessionManager != _arSessionManager) return;
      _setArError(_messageForArError(error));
    }
  }

  Future<void> _placeRandomClueNearUser(
    ARSessionManager sessionManager,
    ARObjectManager objectManager,
  ) async {
    if (!_arReady || _modelPlaced) return;

    final attempt = ++_placementAttempt;
    if (mounted) {
      setState(() {
        _isPlacing = true;
        _statusMessage = '사용자 근처의 무작위 위치에 AR 쪽지를 놓는 중입니다.';
      });
    }

    // ARKit/ARCore가 첫 카메라 자세를 제공할 때까지 잠시 기다립니다.
    // 평면 앵커를 거치지 않아 iOS에서도 바닥 터치 없이 배치할 수 있습니다.
    for (var retry = 0; retry < 20; retry++) {
      if (!mounted ||
          attempt != _placementAttempt ||
          sessionManager != _arSessionManager ||
          objectManager != _arObjectManager) {
        return;
      }

      final cameraPose = await sessionManager.getCameraPose();
      if (cameraPose == null) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        continue;
      }

      ARNode? node;
      try {
        final angle = (_random.nextDouble() - 0.5) * (math.pi / 3);
        final distance = 1.1 + (_random.nextDouble() * 0.7);
        final verticalOffset = -(0.3 + (_random.nextDouble() * 0.25));
        final localOffset = vector.Matrix4.translationValues(
          math.sin(angle) * distance,
          verticalOffset,
          -math.cos(angle) * distance,
        );
        final worldTransform = cameraPose * localOffset;

        node = ARNode(
          type: NodeType.localGLB,
          uri: widget.stage.arModelAsset,
          transformation: worldTransform,
          scale: vector.Vector3.all(widget.stage.arModelScale),
        );
        final nodeAdded = await objectManager.addNode(node) ?? false;
        if (!nodeAdded) {
          throw StateError('GLB 모델을 공간에 배치하지 못했습니다.');
        }

        if (!mounted || attempt != _placementAttempt) {
          objectManager.removeNode(node);
          return;
        }
        setState(() {
          _clueNode = node;
          _isPlacing = false;
          _modelPlaced = true;
          _statusMessage = '앞쪽 가까운 곳에 나타난 3D 쪽지를 찾아보세요.';
        });
        return;
      } catch (_) {
        if (node != null) objectManager.removeNode(node);
        if (!mounted || attempt != _placementAttempt) return;
        setState(() {
          _isPlacing = false;
          _statusMessage = '쪽지를 불러오지 못했습니다. 아래 버튼으로 다시 배치해 주세요.';
        });
        return;
      }
    }

    if (!mounted || attempt != _placementAttempt) return;
    setState(() {
      _isPlacing = false;
      _statusMessage = 'AR 위치를 확인하지 못했습니다. 휴대폰을 천천히 움직인 뒤 다시 시도해 주세요.';
    });
  }

  String _messageForArError(Object error) {
    final message = error is PlatformException
        ? '${error.code} ${error.message ?? ''}'.toLowerCase()
        : error.toString().toLowerCase();

    if (message.contains('not installed')) {
      return 'Google Play AR 서비스를 설치한 뒤 다시 시도해 주세요.';
    }
    if (message.contains('too old')) {
      return 'Google Play AR 서비스를 최신 버전으로 업데이트해 주세요.';
    }
    if (message.contains('not compatible') || message.contains('unsupported')) {
      return '이 기기는 ARCore 또는 ARKit을 지원하지 않습니다.';
    }
    return 'AR 세션을 시작하지 못했습니다. 카메라 권한과 기기의 AR 지원 여부를 확인해 주세요.';
  }

  void _setArError(String message) {
    if (!mounted) return;
    _placementAttempt++;
    _arSessionManager?.dispose();
    _arSessionManager = null;
    _arObjectManager = null;
    _arAnchorManager = null;
    setState(() {
      _arReady = false;
      _isPlacing = false;
      _arError = message;
    });
  }

  void _onTrackingStateChanged(String state, String reason) {
    if (!mounted || _modelPlaced || _isPlacing) return;

    final nextMessage = switch ((state, reason)) {
      ('TRACKING', _) =>
        _usesRandomNearbyPlacement
            ? 'AR 공간을 확인했습니다. 쪽지를 불러올 준비가 되었습니다.'
            : '평면이 표시되면 쪽지를 놓을 위치를 한 번 눌러 주세요.',
      ('PAUSED', 'EXCESSIVE_MOTION') => '휴대폰을 조금 더 천천히 움직여 주세요.',
      ('PAUSED', 'INSUFFICIENT_LIGHT') => '주변을 밝게 한 뒤 다시 비춰 주세요.',
      ('PAUSED', 'INSUFFICIENT_FEATURES') => '무늬나 모서리가 보이는 바닥 또는 벽을 비춰 주세요.',
      ('PAUSED', 'CAMERA_UNAVAILABLE') => '다른 앱에서 카메라를 사용 중인지 확인해 주세요.',
      ('PAUSED', _) => '공간을 인식하는 중입니다. 휴대폰을 천천히 움직여 주세요.',
      _ => _statusMessage,
    };

    if (nextMessage != _statusMessage) {
      setState(() => _statusMessage = nextMessage);
    }
  }

  Future<void> _onPlaneOrPointTapped(
    List<ARHitTestResult> hitTestResults,
  ) async {
    if (_usesRandomNearbyPlacement || !_arReady || _isPlacing || _modelPlaced) {
      return;
    }

    ARHitTestResult? planeHit;
    for (final hit in hitTestResults) {
      if (hit.type == ARHitTestResultType.plane) {
        planeHit = hit;
        break;
      }
    }

    if (planeHit == null) {
      if (mounted) {
        setState(() {
          _statusMessage = '아직 평면이 인식되지 않았습니다. 다른 방향을 천천히 비춰 주세요.';
        });
      }
      return;
    }

    final anchorManager = _arAnchorManager;
    final objectManager = _arObjectManager;
    if (anchorManager == null || objectManager == null) return;

    setState(() {
      _isPlacing = true;
      _statusMessage = 'AR 쪽지를 불러오는 중입니다...';
    });

    final anchor = ARPlaneAnchor(transformation: planeHit.worldTransform);
    ARNode? node;
    try {
      final anchorAdded = await anchorManager.addAnchor(anchor) ?? false;
      if (!anchorAdded) {
        throw StateError('평면 앵커를 만들지 못했습니다.');
      }

      final scale = widget.stage.arModelScale;
      node = ARNode(
        type: NodeType.localGLB,
        uri: widget.stage.arModelAsset,
        scale: vector.Vector3.all(scale),
        position: vector.Vector3.zero(),
      );
      final nodeAdded =
          await objectManager.addNode(node, planeAnchor: anchor) ?? false;
      if (!nodeAdded) {
        anchorManager.removeAnchor(anchor);
        throw StateError('GLB 모델을 공간에 배치하지 못했습니다.');
      }

      if (!mounted) return;
      setState(() {
        _clueAnchor = anchor;
        _clueNode = node;
        _isPlacing = false;
        _modelPlaced = true;
        _statusMessage = '공간에 나타난 3D 쪽지를 확인한 뒤 발견 버튼을 눌러 주세요.';
      });
    } catch (_) {
      if (node != null) objectManager.removeNode(node);
      anchorManager.removeAnchor(anchor);
      if (!mounted) return;
      setState(() {
        _isPlacing = false;
        _statusMessage = '쪽지를 배치하지 못했습니다. GLB 파일과 모델 크기를 확인한 뒤 다시 눌러 주세요.';
      });
    }
  }

  void _onNodeTapped(List<String> nodeNames) {
    final clueNode = _clueNode;
    if (clueNode != null && nodeNames.contains(clueNode.name)) {
      _markClueFound();
    }
  }

  void _markClueFound() {
    if (!mounted || !_modelPlaced || _clueFound) return;
    setState(() {
      _clueFound = true;
      _statusMessage = 'AR 쪽지를 발견했습니다. 이제 문제를 열 수 있습니다.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AR 쪽지를 발견했습니다!'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _resetPlacement() {
    _placementAttempt++;
    final node = _clueNode;
    final anchor = _clueAnchor;
    if (node != null) _arObjectManager?.removeNode(node);
    if (anchor != null) _arAnchorManager?.removeAnchor(anchor);

    setState(() {
      _clueNode = null;
      _clueAnchor = null;
      _modelPlaced = false;
      _clueFound = false;
      _isPlacing = false;
      _statusMessage = _usesRandomNearbyPlacement
          ? '사용자 근처의 새 무작위 위치를 찾고 있습니다.'
          : '평면이 표시되면 새로 놓을 위치를 한 번 눌러 주세요.';
    });

    final sessionManager = _arSessionManager;
    final objectManager = _arObjectManager;
    if (_usesRandomNearbyPlacement &&
        sessionManager != null &&
        objectManager != null) {
      unawaited(_placeRandomClueNearUser(sessionManager, objectManager));
    }
  }

  void _retryAr() {
    _placementAttempt++;
    _arSessionManager?.dispose();
    setState(() {
      _arSessionManager = null;
      _arObjectManager = null;
      _arAnchorManager = null;
      _clueAnchor = null;
      _clueNode = null;
      _arReady = false;
      _isPlacing = false;
      _modelPlaced = false;
      _clueFound = false;
      _arError = null;
      _arViewKey = UniqueKey();
      _statusMessage = 'AR 공간을 다시 준비하는 중입니다.';
    });
  }

  @override
  void dispose() {
    _placementAttempt++;
    _arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AR 단서 탐색 · 구역 ${widget.stage.id}'),
        backgroundColor: Colors.black87,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_supportsArPlatform) {
      return const _ArMessageView(
        icon: Icons.phone_android,
        title: '모바일 기기가 필요합니다',
        message:
            '실제 AR 단서 찾기는 ARCore 지원 Android 또는 ARKit 지원 iPhone에서 사용할 수 있습니다.',
      );
    }

    if (_isCheckingAsset) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 16),
            Text('AR 쪽지 모델을 확인하는 중...'),
          ],
        ),
      );
    }

    if (_assetError != null || !_modelAssetReady) {
      return _ArMessageView(
        icon: Icons.view_in_ar_outlined,
        title: 'GLB 모델을 확인해 주세요',
        message: _assetError ?? 'AR 쪽지 모델을 사용할 수 없습니다.',
        detail: '현재 설정: ${widget.stage.arModelAsset}',
        primaryLabel: '다시 확인',
        onPrimary: _validateModelAsset,
      );
    }

    if (_arError != null) {
      return _ArMessageView(
        icon: Icons.signal_wifi_statusbar_connected_no_internet_4,
        title: 'AR을 시작할 수 없습니다',
        message: _arError!,
        primaryLabel: '다시 시도',
        onPrimary: _retryAr,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ARView(
          key: _arViewKey,
          onARViewCreated: _onARViewCreated,
          planeDetectionConfig: _usesRandomNearbyPlacement
              ? PlaneDetectionConfig.none
              : PlaneDetectionConfig.horizontalAndVertical,
          permissionPromptDescription: 'AR 쪽지를 찾으려면 카메라 권한이 필요합니다.',
          permissionPromptButtonText: '카메라 권한 허용',
          permissionPromptParentalRestriction: '이 기기에서는 카메라 사용이 제한되어 있습니다.',
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _ArStatusPanel(
            stage: widget.stage,
            message: _statusMessage,
            arReady: _arReady,
            isPlacing: _isPlacing,
            modelPlaced: _modelPlaced,
            clueFound: _clueFound,
          ),
        ),
        if (_isPlacing)
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
          ),
        if (_modelPlaced && !_clueFound)
          Positioned(
            left: 20,
            right: 20,
            bottom: 88,
            child: SafeArea(
              top: false,
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _resetPlacement,
                  icon: const Icon(Icons.refresh),
                  label: const Text('쪽지 다시 배치'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: SafeArea(
            top: false,
            child: ElevatedButton.icon(
              onPressed: !_modelPlaced
                  ? _usesRandomNearbyPlacement && _arReady && !_isPlacing
                        ? _resetPlacement
                        : null
                  : _clueFound
                  ? () => Navigator.pop(context, true)
                  : _markClueFound,
              icon: Icon(
                !_modelPlaced
                    ? Icons.refresh
                    : _clueFound
                    ? Icons.note_alt_outlined
                    : Icons.touch_app,
              ),
              label: Text(
                !_modelPlaced
                    ? _usesRandomNearbyPlacement
                          ? _isPlacing
                                ? '사용자 근처에 AR 쪽지를 배치하는 중...'
                                : 'AR 쪽지 다시 불러오기'
                          : '평면을 눌러 AR 쪽지를 배치하세요'
                    : _clueFound
                    ? '발견한 쪽지 열기'
                    : '이 AR 쪽지를 발견했습니다',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.black54,
                disabledForegroundColor: Colors.white70,
                minimumSize: const Size.fromHeight(54),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArStatusPanel extends StatelessWidget {
  final StageInfo stage;
  final String message;
  final bool arReady;
  final bool isPlacing;
  final bool modelPlaced;
  final bool clueFound;

  const _ArStatusPanel({
    required this.stage,
    required this.message,
    required this.arReady,
    required this.isPlacing,
    required this.modelPlaced,
    required this.clueFound,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, title, color) = switch ((
      arReady,
      isPlacing,
      modelPlaced,
      clueFound,
    )) {
      (_, _, _, true) => (Icons.check_circle, 'AR 단서 발견 완료', Colors.amber),
      (_, _, true, false) => (
        Icons.markunread_mailbox,
        '3D 쪽지 발견',
        Colors.greenAccent,
      ),
      (_, true, _, _) => (Icons.downloading, '3D 쪽지 배치 중', Colors.greenAccent),
      (true, _, _, _) => (
        Icons.travel_explore,
        'AR 단서 탐색 중',
        Colors.greenAccent,
      ),
      _ => (Icons.view_in_ar, 'AR 공간 준비 중', Colors.white70),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$title · ${stage.location}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ArMessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? detail;
  final String? primaryLabel;
  final FutureOr<void> Function()? onPrimary;

  const _ArMessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.detail,
    this.primaryLabel,
    this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: Colors.greenAccent),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.5),
            ),
            if (detail != null) ...[
              const SizedBox(height: 10),
              SelectableText(
                detail!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: onPrimary,
                icon: const Icon(Icons.refresh),
                label: Text(primaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
