'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';

interface CartItem {
  id: number;
  name: string;
  price: number;
  quantity: number;
}

export default function CartPage() {
  const [, setRefresh] = useState(0);
  const router = useRouter();

  const getCartItems = (): CartItem[] => {
    if (typeof window === 'undefined') return [];
    const savedCart = localStorage.getItem('cart');
    try {
      return savedCart ? JSON.parse(savedCart) : [];
    } catch {
      return [];
    }
  };

  const cartItems = getCartItems();

  // [수정된 주문 로직] 백엔드 필드명(user_id, delivery_address, total_amount)과 일치시킴
  const handleOrder = async () => {
    if (cartItems.length === 0) {
      alert("장바구니가 비어 있습니다.");
      return;
    }

    const totalAmount = cartItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    
    // 백엔드 OrderRequestDto 구조에 맞춰 필드명 수정
    const orderData = {
      user_id: 1004, 
      delivery_address: "부산광역시 해운대구 센텀시티",
      total_amount: totalAmount,
      //status: "주문대기"
    };

    try {
      const response = await fetch('http://localhost:8080/api/orders', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(orderData),
      });

      if (response.ok) {
        alert("주문이 완료되었습니다!");
        localStorage.removeItem('cart'); // 주문 후 장바구니 비우기
        router.push('/delivery'); // 배달 관리 페이지로 이동
      } else {
        const errorText = await response.text();
        console.error("서버 에러:", errorText);
        alert("주문 처리에 실패했습니다. 서버 로그를 확인해주세요.");
      }
    } catch (error) {
      console.error("주문 요청 에러:", error);
      alert("서버 연결에 실패했습니다.");
    }
  };

  const handleQuantity = (id: number, delta: number) => {
    const currentCart = getCartItems();
    const updated = currentCart.map((item) =>
      item.id === id ? { ...item, quantity: Math.max(1, item.quantity + delta) } : item
    );
    localStorage.setItem('cart', JSON.stringify(updated));
    setRefresh((prev) => prev + 1);
  };

  const handleDelete = (id: number, e: React.MouseEvent) => {
    e.stopPropagation();
    const currentCart = getCartItems();
    const updated = currentCart.filter((item) => item.id !== id);
    localStorage.setItem('cart', JSON.stringify(updated));
    setRefresh((prev) => prev + 1);
  };

  return (
    <div style={{ padding: '24px' }}>
      <h1>🛒 장바구니</h1>

      {cartItems.length === 0 ? (
        <p>장바구니가 비어 있습니다.</p>
      ) : (
        <>
          {cartItems.map((item) => (
            <div key={item.id} style={{ borderBottom: '1px solid #ccc', padding: '15px 0', display: 'flex', justifyContent: 'space-between' }}>
              <span>{item.name}</span>
              <div>
                <button onClick={() => handleQuantity(item.id, -1)}>-</button>
                <span style={{ margin: '0 10px' }}>{item.quantity}</span>
                <button onClick={() => handleQuantity(item.id, 1)}>+</button>
                <button onClick={(e) => handleDelete(item.id, e)} style={{ marginLeft: '15px', color: 'red' }}>삭제</button>
              </div>
            </div>
          ))}

          <button 
            onClick={handleOrder}
            style={{ 
              marginTop: '20px', 
              padding: '12px 24px', 
              backgroundColor: '#2E6F40', 
              color: 'white', 
              border: 'none', 
              borderRadius: '8px', 
              cursor: 'pointer',
              fontSize: '16px'
            }}
          >
            주문하기
          </button>
        </>
      )}
    </div>
  );
}