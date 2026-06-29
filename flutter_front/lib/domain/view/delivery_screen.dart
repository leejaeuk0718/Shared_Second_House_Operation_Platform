import 'package:flutter/material.dart';
import 'package:flutter_front/domain/view/product_list_screen.dart';
import 'package:flutter_front/domain/view/cart_screen.dart';
// 💡 관리자 배달 주문 내역 화면 임포트 추가
import 'package:flutter_front/domain/view/delivery_admin_screen.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '배달 서비스 홈',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E6F40),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(23.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '원하시는 서비스를 선택하세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),

              // 1. 상품 리스트 버튼
              _buildMenuButton(
                context,
                icon: Icons.store,
                label: '상품 리스트 (쇼핑하기)',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // 2. 장바구니 버튼
              _buildMenuButton(
                context,
                icon: Icons.shopping_cart,
                label: '내 장바구니 확인',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // ⚙️ 3. [신규 추가] 관리자 배달 주문 내역 관리 버튼
              _buildMenuButton(
                context,
                icon: Icons.delivery_dining, // 오토바이 모양 배달 아이콘
                label: '관리자 배달 주문 내역',
                color: const Color(0xFF2E6F40), // 세컨하우스 메인 딥그린 테마 색상 맞춤
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DeliveryAdminScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 기존에 이쁘게 작성해두신 버튼 가로채기 공통 빌더 템플릿 그대로 사용
  Widget _buildMenuButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}