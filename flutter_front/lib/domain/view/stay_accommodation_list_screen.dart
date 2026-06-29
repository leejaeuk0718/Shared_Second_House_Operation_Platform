/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : lib/domain/view/stay_accommodation_list_screen.dart
 * 역할  : 숙소 목록 화면 (검색 + 무한 스크롤)
 * 사용처 : app_router.dart 에서 라우팅
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - stay_accommodation_controller.dart   : 상태 및 데이터 (Provider)
 * - stay_accommodation_detail_screen.dart : 카드 탭 시 이동
 * - stay_constants.dart                  : kMonthOptionValues, monthOptionLabel
 * - Spring: StayAccommodationController  : GET /stay/accommodations
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 가격 계산기 (팀수 / 개월수 선택)
 * - 숙소 이름 검색 + X 버튼 초기화
 * - 무한 스크롤 (ScrollController → 하단 200px 전 자동 다음 3개 로드)
 * - 추가 로딩 중 하단 CircularProgressIndicator 표시
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * initState → loadAccommodationsPaged(page=0) → 첫 3개 로드
 * → ScrollController._onScroll() → 하단 감지 → loadAccommodationsPaged(page+1)
 * → 검색 입력 → _search() → loadAccommodationsPaged(newKeyword, page=0) → 목록 교체
 * → X 버튼 → _clearSearch() → 전체 목록 복원
 * ==================================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/common/constants/app_colors.dart';
import 'package:flutter_front/common/constants/stay_constants.dart';
import 'package:flutter_front/common/widget/app_base_layout.dart';
import 'package:flutter_front/common/widget/bottom_sheet_selector.dart';
import 'package:flutter_front/domain/controller/stay_accommodation_controller.dart';
import 'package:flutter_front/domain/dto/stay_accommodation_dto.dart';
import 'package:flutter_front/domain/view/stay_accommodation_detail_screen.dart';
import 'package:flutter_front/util/price_calculator.dart';

class StayAccommodationListScreen extends StatefulWidget {
  final int? initialId;
  const StayAccommodationListScreen({super.key, this.initialId});

  @override
  State<StayAccommodationListScreen> createState() => _StayAccommodationListScreenState();
}

class _StayAccommodationListScreenState extends State<StayAccommodationListScreen> {
  int _months = 1;
  int _teams = 1;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StayAccommodationController>().loadAccommodationsPaged();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final ctrl = context.read<StayAccommodationController>();
      if (ctrl.hasMore && !ctrl.isLoadingMore) {
        ctrl.loadAccommodationsPaged(page: ctrl.currentPage + 1);
      }
    }
  }

  void _search() {
    context.read<StayAccommodationController>().loadAccommodationsPaged(
      newKeyword: _searchController.text.trim(),
      page: 0,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<StayAccommodationController>().loadAccommodationsPaged(
      newKeyword: '',
      page: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<StayAccommodationController>();

    return AppBaseLayout(
      title: '숙소 목록',
      body: Column(
        children: [
          _buildPriceCalculator(),
          _buildSearchBar(),
          Expanded(
            child: ctrl.isLoadingPaged
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ctrl.pagedAccommodations.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다.'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: ctrl.pagedAccommodations.length + (ctrl.isLoadingMore ? 1 : 0),
                        itemBuilder: (_, index) {
                          if (index == ctrl.pagedAccommodations.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            );
                          }
                          return _buildAccommodationCard(ctrl.pagedAccommodations[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: '숙소 이름으로 검색',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _search(),
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.close, size: 18, color: AppColors.textHint),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 42,
            child: ElevatedButton(
              onPressed: _search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
              ),
              child: const Text('검색', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCalculator() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('가격 계산기', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: BottomSheetSelector(
                  label: '팀수',
                  value: _teams,
                  options: List.generate(12, (i) => i + 1),
                  displayText: (v) => '$v팀',
                  onSelected: (v) => setState(() => _teams = v),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BottomSheetSelector(
                  label: '개월수',
                  value: _months,
                  options: kMonthOptionValues,
                  displayText: monthOptionLabel,
                  onSelected: (v) => setState(() => _months = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccommodationCard(StayAccommodationDto item) {
    final teamPrice = PriceCalculator.calculateTeamPrice(monthlyPrice: item.monthlyPrice, months: _months, teams: _teams, prices: item.prices);
    final discountRate = PriceCalculator.getDiscountRate(months: _months, prices: item.prices);
    final isAvailable = item.status == 'AVAILABLE';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StayAccommodationDetailScreen(accommodationId: item.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: item.firstImageUrl != null
                  ? Image.network(item.firstImageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (context, err, _) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.primaryLight : AppColors.border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAvailable ? '예약가능' : '점검중',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAvailable ? AppColors.success : AppColors.disabledText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('월 ${_fmt(teamPrice)}원', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      const Text('/ 팀당', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                      const Spacer(),
                      if (discountRate > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(6)),
                          child: Text('${(discountRate * 100).toInt()}% 할인', style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('기준: ${monthOptionLabel(_months)} · $_teams팀 기준가', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (item.roomCount != null) _specChip('방 ${item.roomCount}개'),
                      if (item.bathroomCount != null) _specChip('화장실 ${item.bathroomCount}개'),
                      if (item.parkingCount != null) _specChip('주차 ${item.parkingCount}대'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    height: 180, color: AppColors.border,
    child: const Center(child: Icon(Icons.home_outlined, size: 48, color: AppColors.textHint)),
  );

  Widget _specChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: AppColors.primaryBg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.primary)),
  );

  String _fmt(int price) => price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
