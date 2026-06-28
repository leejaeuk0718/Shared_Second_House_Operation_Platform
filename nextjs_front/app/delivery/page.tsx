'use client';
import { useEffect, useState } from 'react';

// 1. 백엔드에서 주는 데이터와 똑같은 구조로 인터페이스 정의
interface Order {
  order_id: number;
  user_id: number;
  delivery_address: string;
  total_amount: number;
  status: string;
}

export default function DeliveryAdminPage() {
  // 2. any 대신 Order[] 배열임을 명시
  const [orders, setOrders] = useState<Order[]>([]);

  useEffect(() => {
    fetch('http://localhost:8080/api/orders/admin')
      .then((res) => res.json())
      .then((data: Order[]) => setOrders(data)) // 3. 여기서도 데이터 타입을 명시
      .catch((err) => console.error("주문 내역 로딩 에러:", err));
  }, []);

  return (
    <div style={{ padding: '24px' }}>
      <h1>📦 배달 주문 내역</h1>
      <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '20px' }}>
        <thead>
          <tr style={{ borderBottom: '2px solid #333' }}>
            <th>주문ID</th><th>사용자ID</th><th>주소</th><th>금액</th><th>상태</th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr key={order.order_id} style={{ borderBottom: '1px solid #ccc' }}>
              <td style={{ padding: '10px' }}>{order.order_id}</td>
              <td>{order.user_id}</td>
              <td>{order.delivery_address}</td>
              <td>{order.total_amount?.toLocaleString()}원</td>
              <td>{order.status}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}