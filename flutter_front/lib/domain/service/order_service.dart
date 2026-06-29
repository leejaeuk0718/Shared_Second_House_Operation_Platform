import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/order_request.dart';

class OrderService {
  // 에뮬레이터 테스트 환경 주소 (본인의 실제 백엔드 IP포트로 수정 가능)
  final String _baseUrl = 'http://10.0.2.2:8080/api/orders';

  // 백엔드 데이터베이스(sh_order, sh_order_item)에 주문 데이터를 밀어 넣는 함수
  Future<bool> sendOrder(OrderRequest orderRequest) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderRequest.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('OrderService 통신 에러 발생: $e');
      return false;
    }
  }
}