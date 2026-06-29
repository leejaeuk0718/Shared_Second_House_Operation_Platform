// 백엔드 Spring Boot의 OrderRequest DTO 스키마와 1:1 대응하는 클래스
class OrderRequest {
  final int userId;
  final String deliveryAddress;
  final int totalAmount;
  final List<CartItemPayload> items;

  OrderRequest({
    required this.userId,
    required this.deliveryAddress,
    required this.totalAmount,
    required this.items,
  });

  // 서버에 JSON 데이터로 변환해 보내기 위한 맵핑 함수
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deliveryAddress': deliveryAddress,
      'totalAmount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CartItemPayload {
  final int productId;
  final int quantity;
  final int price;

  CartItemPayload({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}