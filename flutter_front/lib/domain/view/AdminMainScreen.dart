import 'package:flutter/material.dart';
// 💡 실제 팀원분이 만들어둔 관리자 배달 내역 화면 파일 경로로 임포트해 주세요!
import 'package:flutter_front/domain/view/delivery_admin_screen.dart';

class AdminMainScreen extends StatelessWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 모드'),
        backgroundColor: const Color(0xFF2E6F40), // 세컨하우스 시그니처 초록색 적용
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '스토어 관리 메뉴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 💡 잉크웰(InkWell) 효과가 들어간 배달 주문 내역 버튼 카드
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // 클릭 시 관리자 배달 주문 내역 화면(DeliveryAdminScreen)으로 부드럽게 이동!
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeliveryAdminScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      // 아이콘 배경 서클
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E6F40).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.delivery_dining, // 오토바이/배달 모양 아이콘
                          color: Color(0xFF2E6F40),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 텍스트 영역
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '배달 주문 내역 관리',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '실시간 들어온 주문과 배달 상태를 변경합니다.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // 오른쪽 화살표 기호
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}