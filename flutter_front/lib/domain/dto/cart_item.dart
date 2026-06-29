// 장바구니 안에서 개별 상품 정보를 유지하기 위한 모델 객체
class CartItem {
  final int productId;
  final String name;
  final int price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}