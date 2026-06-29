/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/controller/stay_reservation_controller.dart
 * 역할  : 숙소 예약 상태 관리 (ChangeNotifier + Provider 패턴)
 * 사용처 : StayMyReservationScreen, StayReservationCalendarScreen
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_reservation_service.dart       : API 호출
 * - stay_reservation_dto.dart           : 예약 모델
 * - config/app_router.dart              : ChangeNotifierProvider 등록
 * ----------------------------------------------------------------------------------
 * [상태 목록]
 * - reservations               : 내 예약 목록
 * - accommodationReservations  : 숙소별 예약 목록 (달력 날짜 블록용)
 * - selectedStartDate / selectedEndDate : 선택된 예약 날짜 범위
 * ----------------------------------------------------------------------------------
 * [메서드 목록]
 * - loadMyReservations()              : 내 예약 목록 조회
 * - loadAccommodationReservations(id) : 숙소별 예약 목록 조회
 * - createReservation(accommodationId): 예약 생성 (선택 날짜 기반)
 * - cancelReservation(id)             : 예약 취소
 * - selectDateRange(start, end)       : 날짜 범위 선택
 * - clearDateRange()                  : 날짜 선택 초기화
 * ==================================================================================
 */

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_front/domain/dto/stay_reservation_dto.dart';
import 'package:flutter_front/domain/service/stay_reservation_service.dart';

class StayReservationController extends ChangeNotifier {
  final StayReservationService _service = StayReservationService();

  List<StayReservationDto> reservations = [];
  List<StayReservationDto> accommodationReservations = []; // 숙소별 예약 (달력 날짜 블록용)
  bool isLoading = false;
  String? errorMessage;

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  Future<void> loadMyReservations(int userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      reservations = await _service.getMyReservations(userId);
    } catch (e) {
      errorMessage = '예약 목록을 불러오지 못했습니다.';
      debugPrint('❌ [예약 컨트롤러] $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> loadAccommodationReservations(int accommodationId) async {
    try {
      accommodationReservations = await _service.getAccommodationReservations(accommodationId);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [숙소별 예약 로드] $e');
    }
  }

  Future<bool> createReservation(int accommodationId, int userId) async {
    if (selectedStartDate == null || selectedEndDate == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      final req = StayReservationRequestDto(
        accommodationId: accommodationId,
        userId: userId,
        startDate: _formatDate(selectedStartDate!),
        endDate: _formatDate(selectedEndDate!),
      );
      final result = await _service.createReservation(req);
      reservations.add(result);
      await loadAccommodationReservations(accommodationId);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final data = (e is DioException) ? e.response?.data : null;
      errorMessage = (data is Map && data['message'] != null) ? data['message'] : '예약에 실패했습니다.';
      debugPrint('❌ [예약 생성] $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelReservation(int id, int userId) async {
    try {
      await _service.cancelReservation(id, userId);
      final idx = reservations.indexWhere((r) => r.id == id);
      if (idx != -1) {
        reservations[idx] = StayReservationDto(
          id: reservations[idx].id,
          accommodationId: reservations[idx].accommodationId,
          accommodationName: reservations[idx].accommodationName,
          accommodationAddress: reservations[idx].accommodationAddress,
          startDate: reservations[idx].startDate,
          endDate: reservations[idx].endDate,
          status: 'CANCELLED',
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      final data = (e is DioException) ? e.response?.data : null;
      errorMessage = (data is Map && data['message'] != null) ? data['message'] : '예약 취소에 실패했습니다.';
      debugPrint('❌ [예약 취소] $e');
      notifyListeners();
      return false;
    }
  }

  void selectDateRange(DateTime start, DateTime end) {
    selectedStartDate = start;
    selectedEndDate = end;
    notifyListeners();
  }

  void clearDateRange() {
    selectedStartDate = null;
    selectedEndDate = null;
    notifyListeners();
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
