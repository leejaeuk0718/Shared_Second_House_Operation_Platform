import 'package:flutter/material.dart';

class CartProvider with ChangeNotifier {
  // 장바구니 데이터
  final List<Map<String, dynamic>> _cartItems = [];
  // 주문 관리 데이터
  final List<Map<String, dynamic>> _adminOrders = [];

  // 외부에서 접근 가능한 Getter
  List<Map<String, dynamic>> get cartItems => _cartItems;
  List<Map<String, dynamic>> get adminOrders => _adminOrders;

  // 1. 장바구니 추가
  void addToCart(Map<String, dynamic> product) {
    int index = _cartItems.indexWhere((item) => item['productId'] == product['id']);
    if (index >= 0) {
      _cartItems[index]['quantity'] += 1;
    } else {
      _cartItems.add({
        "productId": product['id'],
        "name": product['name'],
        "price": product['price'],
        "quantity": 1,
        "img": product['img']
      });
    }
    notifyListeners();
  }

  // 2. 장바구니 삭제
  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item['productId'] == productId);
    notifyListeners();
  }

  // 3. 수량 증가
  void incrementQuantity(int productId) {
    int index = _cartItems.indexWhere((item) => item['productId'] == productId);
    if (index >= 0) {
      _cartItems[index]['quantity'] += 1;
      notifyListeners();
    }
  }

  // 4. 수량 감소
  void decrementQuantity(int productId) {
    int index = _cartItems.indexWhere((item) => item['productId'] == productId);
    if (index >= 0 && _cartItems[index]['quantity'] > 1) {
      _cartItems[index]['quantity'] -= 1;
      notifyListeners();
    }
  }

  // 5. 장바구니 전체 비우기 (에러 해결용)
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // 6. 주문 처리 (에러 해결용)
  void addOrderFromCart(int totalAmount) {
    String newOrderId = "SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}";
    _adminOrders.add({
      "orderId": newOrderId,
      "status": "배송 준비 중",
      "totalAmount": "$totalAmount원",
    });
    notifyListeners();
  }
}