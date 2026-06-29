import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/service/cart_provider.dart';
import 'package:http/http.dart' as http; // 서버 통신용
import 'dart:convert';
import 'package:flutter_front/view/delivery_admin_screen.dart';

import 'delivery_admin_screen.dart'; // 관리자 페이지 import

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  // 주문 전송 함수
  Future<void> _placeOrder(BuildContext context, int totalAmount, List items) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': 1004, // 로그인된 사용자 ID 가정
          'delivery_address': '부산광역시 수영구 광안동 123-45', // 사용자 주소 가정
          'total_amount': totalAmount,
          'items': items.map((item) => {
            'product_id': item['productId'],
            'quantity': item['quantity'],
            'price': item['price']
          }).toList(),
        }),
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주문이 접수되었습니다!')));

          // 관리자 페이지로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DeliveryAdminScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("주문 전송 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('장바구니', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF2E6F40)
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.cartItems;

          int totalAmount = cartItems.fold<int>(0, (sum, item) {
            int price = (item['price'] as num?)?.toInt() ?? 0;
            int qty = (item['quantity'] as num?)?.toInt() ?? 0;
            return sum + (price * qty);
          });

          if (cartItems.isEmpty) {
            return const Center(child: Text('장바구니가 비어 있습니다.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['name'] ?? '상품명 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${item['price'] ?? 0}원'),
                                ],
                              ),
                            ),
                            // 수량 감소 (기존 로직 유지)
                            IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => cartProvider.decrementQuantity(item['productId'])
                            ),
                            Text('${item['quantity'] ?? 0}'),
                            // 수량 증가 (기존 로직 유지)
                            IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => cartProvider.incrementQuantity(item['productId'])
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => cartProvider.removeFromCart(item['productId']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('총 결제 금액: $totalAmount원',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6F40)),
                  onPressed: () async {
                    // 1. 서버로 주문 데이터 전송
                    await _placeOrder(context, totalAmount, cartItems);

                    // 2. 로컬 장바구니 초기화
                    cartProvider.clearCart();
                  },
                  child: const Text('주문하기', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}