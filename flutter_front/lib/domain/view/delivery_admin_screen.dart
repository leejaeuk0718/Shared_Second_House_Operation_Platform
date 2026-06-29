import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryAdminScreen extends StatefulWidget {
  const DeliveryAdminScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryAdminScreen> createState() => _DeliveryAdminScreenState();
}

class _DeliveryAdminScreenState extends State<DeliveryAdminScreen> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:8080/api/orders/admin'));
      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(utf8.decode(response.bodyBytes));
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("에러 발생: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> updateStatus(int orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:8080/api/orders/$orderId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      if (response.statusCode == 200) fetchOrders();
    } catch (e) {
      debugPrint("상태 변경 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 배송/주문 관리')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text('주문번호: SH-2026-${order['order_id']}'),
              subtitle: Text('상태: ${order['status']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: Icon(Icons.local_shipping, color: Colors.blue),
                      onPressed: () => updateStatus(order['order_id'], "배송중")),
                  IconButton(icon: Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => updateStatus(order['order_id'], "배송완료")),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('주문 상세 정보'),
                    content: Text('주소: ${order['delivery_address']}\n금액: ${order['total_amount']}원'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('닫기'))],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}