import 'package:flutter/material.dart';

class DeliveryAdminDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onDelete;
  final Function(String newStatus) onStatusChange; // 💡 상태 변경을 부모 리스트에 알릴 콜백 추가

  const DeliveryAdminDetailScreen({
    super.key,
    required this.order,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<DeliveryAdminDetailScreen> createState() => _DeliveryAdminDetailScreenState();
}

class _DeliveryAdminDetailScreenState extends State<DeliveryAdminDetailScreen> {
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    // 현재 주문의 배송 상태 초기화
    _currentStatus = widget.order['status'] ?? '배송 준비 중';
  }

  // 배송 상태 업데이트 함수
  void _updateStatus(String status) {
    setState(() {
      _currentStatus = status;
    });
    widget.onStatusChange(status); // 부모 화면(리스트)의 데이터도 함께 변경

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('배송 상태가 [$status](으)로 변경되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.order['orderId']} 상세 내역'),
        backgroundColor: const Color(0xFF2E6F40),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주문 정보 카드
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주문번호: ${widget.order['orderId']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 24),

                    // 💡 실시간으로 변하는 상태 텍스트 색상 분기 처리
                    Row(
                      children: [
                        const Text('배송 상태: ', style: TextStyle(fontSize: 16)),
                        Text(
                          _currentStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _currentStatus == '배송완료'
                                ? Colors.grey
                                : (_currentStatus == '배송 중' ? Colors.blueAccent : Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('총 결제금액: ${widget.order['totalAmount']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    const SizedBox(height: 8),
                    const Text('배송지: 부산광역시 세컨하우스 지정 숙소', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text('배송 상태 관리', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // 💡 1. 배송하기 버튼 (배송 준비 중일 때만 활성화)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _currentStatus == '배송 준비 중' ? () => _updateStatus('배송 중') : null,
                icon: const Icon(Icons.local_shipping),
                label: const Text('배송하기 (배송 중 변경)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6F40),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 💡 2. 배송완료 버튼 (배송 중일 때만 활성화)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _currentStatus == '배송 중' ? () => _updateStatus('배송완료') : null,
                icon: const Icon(Icons.done_all),
                label: const Text('배송완료 처리', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const Spacer(),

            // 주문 삭제(취소) 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(context),
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                label: const Text('주문 내역 삭제하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 삭제 확인 팝업창
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('주문 삭제'),
        content: const Text('이 주문 내역을 완전히 삭제하시겠습니까?\n(이 작업은 되돌릴 수 없습니다.)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDelete();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.order['orderId']} 주문이 삭제되었습니다.')),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}