import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_front/domain/dto/route_dto.dart';
import 'package:flutter_front/domain/service/route_service.dart';

/// flutter_foreground_task가 별도 isolate에서 호출하는 진입점.
/// 반드시 최상위 함수 + vm:entry-point 여야 한다.
@pragma('vm:entry-point')
void startLocationTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// 🗺️ 백그라운드(포그라운드 서비스) isolate에서 도는 위치 추적 핸들러
///
/// - geolocator 위치 스트림을 구독해 좌표를 받는다.
/// - 받은 좌표는 ① UI isolate로 실시간 전달(sendDataToMain)하고
///   ② 버퍼에 쌓아 일정 개수/주기마다 백엔드로 묶어 전송한다.
///
/// sessionId / baseUrl은 UI isolate가 서비스 시작 전에
/// FlutterForegroundTask.saveData로 저장해 둔 값을 읽어 온다.
class LocationTaskHandler extends TaskHandler {
  // 버퍼가 이 개수에 도달하면 즉시 백엔드 전송 (주기 전송과 별개)
  static const int _flushThreshold = 10;

  int? _sessionId;
  RouteService? _service;
  StreamSubscription<Position>? _positionSub;
  final List<RoutePointData> _buffer = [];
  bool _flushing = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sessionId = await FlutterForegroundTask.getData<int>(key: 'sessionId');
    final baseUrl = await FlutterForegroundTask.getData<String>(key: 'baseUrl');
    // 이 isolate엔 DioClient(토큰 인터셉터)가 없으므로 UI isolate가 넘겨준 토큰을 직접 사용
    final accessToken =
        await FlutterForegroundTask.getData<String>(key: 'accessToken');

    if (_sessionId == null || baseUrl == null) {
      debugPrint('❌ [추적 isolate] sessionId/baseUrl 누락 — 추적 시작 불가');
      return;
    }
    _service = RouteService(baseUrl, accessToken: accessToken);
    debugPrint('🟢 [추적 isolate] 시작 sessionId=$_sessionId');

    // 50m 이상 이동할 때만 좌표 1개 기록 (GPS 잔떨림으로 인한 불필요한 점 방지)
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
  }

  void _onPosition(Position pos) {
    final point = RoutePointData(
      lat: pos.latitude,
      lng: pos.longitude,
      recordedAt: DateTime.now(),
    );
    _buffer.add(point);

    // UI isolate로 실시간 전달 (폴리라인 즉시 그리기용)
    FlutterForegroundTask.sendDataToMain({
      'lat': point.lat,
      'lng': point.lng,
    });

    if (_buffer.length >= _flushThreshold) {
      _flush();
    }
  }

  /// 버퍼에 쌓인 좌표를 백엔드로 묶어 전송
  Future<void> _flush() async {
    if (_flushing) return; // 중복 전송 방지
    final service = _service;
    final sessionId = _sessionId;
    if (service == null || sessionId == null || _buffer.isEmpty) return;

    _flushing = true;
    final batch = List<RoutePointData>.from(_buffer);
    _buffer.clear();
    try {
      await service.addPoints(sessionId, batch);
      debugPrint('🟢 [추적 isolate] ${batch.length}건 전송 완료');
    } catch (e) {
      // 실패 시 좌표를 버리지 않고 버퍼 앞쪽에 되돌려 다음 기회에 재시도
      _buffer.insertAll(0, batch);
      debugPrint('🔴 [추적 isolate] 전송 실패 — 재시도 대기: $e');
    } finally {
      _flushing = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 주기적으로 남은 버퍼 비우기 (이동을 멈춰 임계치에 못 미쳐도 전송되도록)
    _flush();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _positionSub?.cancel();
    await _flush(); // 남은 좌표 마지막 전송
    debugPrint('⏹️ [추적 isolate] 종료');
  }
}