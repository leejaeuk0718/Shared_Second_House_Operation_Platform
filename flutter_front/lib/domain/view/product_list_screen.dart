import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/service/cart_provider.dart'; // main.dart와 같은 선상에 있는 cart_provider 참조
import 'package:flutter_front/domain/view/cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // 실제 API 연동 또는 내부 변환에 맞춰 확장자를 .png로 동기화한 상품 데이터
  final List<Map<String, dynamic>> products = [
    {"id": 1, "name": "[추천] 오션뷰 세컨하우스 1박 이용권", "price": 150000, "img": "assets/images/ocean.png"},
    {"id": 2, "name": "[조식] 수제 샌드위치 & 커피 세트", "price": 12000, "img": "assets/images/sandwich.png"},
    {"id": 3, "name": "[시그니처] 대나무 바베큐 플래터", "price": 45000, "img": "assets/images/bbq.png"},
    {"id": 4, "name": "[가정간편식] 얼큰 차돌된장찌개", "price": 18000, "img": "assets/images/stew.png"},
    {"id": 5, "name": "콜라 / 사이다 500ml캔", "price": 2500, "img": "assets/images/drink.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('세컨 하우스 스토어'),
        backgroundColor: const Color(0xFF2E6F40),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket, color: Colors.white),
            onPressed: () {
              // 장바구니 아이콘 클릭 시 CartScreen 화면으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  product['img'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60, height: 60, color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${product['price']}원'),
              trailing: IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: Color(0xFF2E6F40)),
                onPressed: () {
                  // 장바구니 담기 버튼 클릭 시 CartProvider의 상태 변경 호출
                  Provider.of<CartProvider>(context, listen: false).addToCart(product);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product['name']}이(가) 장바구니에 담겼습니다.'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}