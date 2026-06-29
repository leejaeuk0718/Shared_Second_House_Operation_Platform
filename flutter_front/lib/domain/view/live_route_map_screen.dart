import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:flutter_front/domain/controller/route_controller.dart';

/// 🗺️ 내 이동경로 화면
/// 시작/정지 버튼으로 추적을 제어하고, 수집되는 좌표를 Polyline으로 실시간 표시.
/// 백그라운드(화면 꺼짐/앱 내림)에서도 포그라운드 서비스가 위치를 계속 수집한다.
class LiveRouteMapScreen extends StatefulWidget {
  const LiveRouteMapScreen({super.key});

  @override
  State<LiveRouteMapScreen> createState() => _LiveRouteMapScreenState();
}

class _LiveRouteMapScreenState extends State<LiveRouteMapScreen> {
  static const Color primary = Color(0xFF245B10); // 앱 시그니처 초록
  // 초기 카메라(현재 위치를 못 잡았을 때의 임시 중심 — 부산 시청 부근)
  static const LatLng _fallbackCenter = LatLng(35.1799, 129.0756);

  GoogleMapController? _mapController;
  LatLng? _lastCameraTarget;

  @override
  void initState() {
    super.initState();
    // 진입 시 현재 위치로 카메라 이동 시도
    WidgetsBinding.instance.addPostFrameCallback((_) => _moveToCurrentLocation());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final target = LatLng(pos.latitude, pos.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      // 위치를 못 잡으면 초기 중심 유지
    }
  }

  Set<Polyline> _buildPolylines(List<LatLng> points) {
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: const PolylineId('my_route'),
        points: points,
        color: primary,
        width: 6,
      ),
    };
  }

  Set<Marker> _buildMarkers(LatLng? last) {
    if (last == null) return {};
    return {
      Marker(
        markerId: const MarkerId('current'),
        position: last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '현재 위치'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RouteController>();

    // 추적 중 새 좌표가 들어오면 카메라를 마지막 위치로 따라가게 함
    final last = controller.lastPoint;
    if (last != null && last != _lastCameraTarget) {
      _lastCameraTarget = last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.animateCamera(CameraUpdate.newLatLng(last));
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내 이동경로',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _fallbackCenter,
              zoom: 15,
            ),
            polylines: _buildPolylines(controller.points),
            markers: _buildMarkers(controller.lastPoint),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _mapController = c,
          ),

          // 에러 메시지 배너
          if (controller.error != null)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

          // 현재 위치로 이동 버튼
          Positioned(
            right: 12,
            bottom: 96,
            child: FloatingActionButton(
              heroTag: 'recenter',
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: primary,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 추적 상태 표시
          if (controller.isTracking)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.fiber_manual_record,
                        color: Colors.redAccent, size: 14),
                    SizedBox(width: 6),
                    Text('기록 중',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),

      // 시작/정지 버튼
      floatingActionButton: _trackingButton(context, controller),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _trackingButton(BuildContext context, RouteController controller) {
    final tracking = controller.isTracking;
    return FloatingActionButton.extended(
      heroTag: 'tracking',
      backgroundColor: tracking ? Colors.red : primary,
      foregroundColor: Colors.white,
      onPressed: controller.isBusy
          ? null
          : () async {
              if (tracking) {
                await controller.stopTracking();
              } else {
                await controller.startTracking();
              }
            },
      icon: controller.isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Icon(tracking ? Icons.stop : Icons.play_arrow),
      label: Text(tracking ? '추적 정지' : '추적 시작'),
    );
  }
}