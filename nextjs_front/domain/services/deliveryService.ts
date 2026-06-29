import { ShDeliveryData } from '../models/delivery';

class DeliveryService {
  private baseUrl = 'http://localhost:8080/api/orders'; // 백엔드 서버 주소

  // 백엔드로부터 전체 주문/배달 리스트를 받아오는 함수
  async getAdminOrders(): Promise<ShDeliveryData[]> {
    const response = await fetch(`${this.baseUrl}/admin`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      cache: 'no-store', // 실시간 데이터 조회를 위해 캐시 방지
    });

    if (!response.ok) {
      throw new Error('백엔드 데이터베이스로부터 배달 내역을 가져오지 못했습니다.');
    }

    return response.json();
  }
}

export const deliveryService = new DeliveryService();