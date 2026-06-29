'use client';
import { useEffect, useState } from 'react';

interface Order {
  order_id: number;
  user_id: number;
  delivery_address: string;
  total_amount: number;
  status: string;
}

export default function DeliveryAdminPage() {
  const [orders, setOrders] = useState<Order[]>([]);

  // 1. 서버에서 데이터를 가져오는 함수 (재사용 가능하게 정의)
  const fetchOrders = async () => {
    try {
      const res = await fetch('http://localhost:8080/api/orders/admin');
      if (!res.ok) throw new Error('서버 응답 없음');
      const data = await res.json();
      setOrders(data);
    } catch (err) {
      console.error("주문 내역 로딩 에러:", err);
    }
  };

  // 2. 컴포넌트가 처음 렌더링될 때 한 번 실행
  useEffect(() => {
    const loadData = async () => {
      await fetchOrders();
    };
    loadData();
  }, []);

  // 3. 상태 변경 함수 (성공 시 fetchOrders를 다시 불러와 화면을 갱신함)
  const updateStatus = async (orderId: number, status: string) => {
    try {
      const res = await fetch(`http://localhost:8080/api/orders/${orderId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status }),
      });
      if (res.ok) {
        // 상태 변경 성공 후 즉시 최신 데이터 반영
        await fetchOrders();
      }
    } catch (err) {
      console.error("상태 변경 에러:", err);
    }
  };

  return (
    <div style={{ padding: '24px' }}>
      <h1>📦 배달 주문 내역</h1>
      <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '20px' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #333' }}>
            <th>주문ID</th><th>사용자ID</th><th>주소</th><th>금액</th><th>상태</th><th>관리</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr key={order.order_id} style={{ borderBottom: '1px solid #ccc', textAlign: 'center' }}>
              <td style={{ padding: '10px' }}>{order.order_id}</td>
              <td>{order.user_id}</td>
              <td>{order.delivery_address}</td>
              <td>{order.total_amount?.toLocaleString()}원</td>
              <td><strong>{order.status}</strong></td>
              <td>
                <button onClick={() => updateStatus(order.order_id, "배송중")}>🚚</button>
                <button onClick={() => updateStatus(order.order_id, "배송완료")}>✅</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}