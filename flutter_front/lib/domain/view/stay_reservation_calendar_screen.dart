/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/view/stay_reservation_calendar_screen.dart
 * 역할  : 숙소 예약 달력 화면 (날짜 범위 선택 → 예약 생성)
 * 사용처 : StayAccommodationDetailScreen 에서 "예약하기" 버튼 탭 시 push
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_reservation_controller.dart   : 예약 생성 / 날짜 선택 상태 (Provider)
 * - table_calendar 패키지              : 달력 UI
 * - Spring: StayReservationController  : POST /stay/reservations
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 달력에서 날짜 범위(시작일 ~ 종료일) 선택
 * - 구독 기간 내로 선택 범위 제한 (subscriptionStartDate ~ subscriptionEndDate)
 * - 기존 예약된 날짜 블록 표시 (선택 불가)
 * - 선택 완료 후 예약 생성 요청
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/common/widget/app_base_layout.dart';
import 'package:flutter_front/features/auth/provider/auth_provider.dart';
import 'package:flutter_front/domain/controller/stay_reservation_controller.dart';

class StayReservationCalendarScreen extends StatefulWidget {
  final int accommodationId;
  final String accommodationName;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  const StayReservationCalendarScreen({
    super.key,
    required this.accommodationId,
    required this.accommodationName,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
  });

  @override
  State<StayReservationCalendarScreen> createState() => _StayReservationCalendarScreenState();
}

class _StayReservationCalendarScreenState extends State<StayReservationCalendarScreen> with WidgetsBindingObserver {

  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _focusedDay;

  DateTime get _calendarFirstDay {
    final today = _normalize(DateTime.now());
    if (widget.subscriptionStartDate != null) {
      final subStart = _normalize(widget.subscriptionStartDate!);
      return subStart.isAfter(today) ? subStart : today;
    }
    return today;
  }

  DateTime get _calendarLastDay {
    if (widget.subscriptionEndDate != null) {
      return _normalize(widget.subscriptionEndDate!);
    }
    return DateTime.now().add(const Duration(days: 365));
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _focusedDay = _calendarFirstDay;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StayReservationController>().loadAccommodationReservations(widget.accommodationId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<StayReservationController>().loadAccommodationReservations(widget.accommodationId);
    }
  }

  bool _isDayEnabled(DateTime day, StayReservationController ctrl) {
    final d = _normalize(day);

    // 구독 기간 밖
    if (d.isBefore(_calendarFirstDay) || d.isAfter(_calendarLastDay)) return false;

    // 이미 예약된 날짜 블록 (CANCELLED 제외)
    for (final r in ctrl.accommodationReservations) {
      if (r.status == 'CANCELLED') continue;
      if (r.startDate.isEmpty || r.endDate.isEmpty) continue;
      try {
        final rStart = _normalize(DateTime.parse(r.startDate));
        final rEnd = _normalize(DateTime.parse(r.endDate));
        if (!d.isBefore(rStart) && !d.isAfter(rEnd)) return false;
      } catch (_) {
        continue;
      }
    }

    // 시작일 선택 후 종료일 미선택 상태: 다음 예약 시작일 이후는 선택 불가
    if (_rangeStart != null && _rangeEnd == null) {
      final start = _normalize(_rangeStart!);
      DateTime? nextBookedStart;
      for (final r in ctrl.accommodationReservations) {
        if (r.status == 'CANCELLED') continue;
        if (r.startDate.isEmpty) continue;
        try {
          final rStart = _normalize(DateTime.parse(r.startDate));
          if (rStart.isAfter(start)) {
            if (nextBookedStart == null || rStart.isBefore(nextBookedStart)) {
              nextBookedStart = rStart;
            }
          }
        } catch (_) {
          continue;
        }
      }
      if (nextBookedStart != null && !d.isBefore(nextBookedStart)) return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StayReservationController>();

    return AppBaseLayout(
      title: widget.accommodationName,
      actions: _rangeStart != null
          ? [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: '초기화',
                onPressed: () => setState(() {
                  _rangeStart = null;
                  _rangeEnd = null;
                }),
              ),
            ]
          : null,
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('예약 날짜를 선택해주세요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          if (widget.subscriptionStartDate != null && widget.subscriptionEndDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    '구독 기간: ${_fmtDate(widget.subscriptionStartDate!)} ~ ${_fmtDate(widget.subscriptionEndDate!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: _calendarFirstDay,
                lastDay: _calendarLastDay,
                focusedDay: _focusedDay,
                locale: 'ko_KR',
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                rangeSelectionMode: RangeSelectionMode.toggledOn,
                enabledDayPredicate: (day) => _isDayEnabled(day, ctrl),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                calendarStyle: CalendarStyle(
                  rangeHighlightColor: AppColors.primary.withValues(alpha: 0.12),
                  rangeStartDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  rangeEndDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  disabledTextStyle: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    decoration: TextDecoration.lineThrough,
                  ),
                  outsideDaysVisible: false,
                ),
                onRangeSelected: (start, end, focusedDay) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
            ),
          ),

          if (_rangeStart != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('선택 기간', style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${_fmtDate(_rangeStart!)} ~ ${_rangeEnd != null ? _fmtDate(_rangeEnd!) : '종료일 선택'}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    if (_rangeStart != null && _rangeEnd != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '총 ${_rangeEnd!.difference(_rangeStart!).inDays}박',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const Spacer(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_rangeStart != null && _rangeEnd != null && !ctrl.isLoading)
                      ? () => _handleReservation(ctrl)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: ctrl.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('예약 확정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReservation(StayReservationController ctrl) async {
    ctrl.selectDateRange(_rangeStart!, _rangeEnd!);
    final success = await ctrl.createReservation(widget.accommodationId, context.read<AuthProvider>().userId!);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약이 완료되었습니다!'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.errorMessage ?? '예약에 실패했습니다.'), backgroundColor: AppColors.danger),
      );
    }
  }

  String _fmtDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}
