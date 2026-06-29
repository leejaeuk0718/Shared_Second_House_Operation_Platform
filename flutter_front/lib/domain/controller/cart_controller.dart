import 'package:flutter/material.dart';
import '../dto/cart_item.dart';

class CartController with ChangeNotifier {
  final Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  // 장바구니에 담긴 아이템 총액 실시간 계산
  int get totalAmount {
    var total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // 장바구니 상품 추가 로직
  void addToCart(int productId, String name, int price) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
            (existing) => CartItem(
          productId: existing.productId,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
            () => CartItem(productId: productId, name: name, price: price),
      );
    }
    notifyListeners(); // UI에 반영 요청
  }

  // 장바구니 초기화
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}