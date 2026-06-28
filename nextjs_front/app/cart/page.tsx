'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation'; // 페이지 이동을 위한 훅

interface CartItem {
  id: number;
  name: string;
  price: number;
  quantity: number;
}

export default function CartPage() {
  const [, setRefresh] = useState(0);
  const router = useRouter(); // 라우터 객체 생성

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

  const handleOrder = () => {
    if (cartItems.length === 0) {
      alert("장바구니가 비어 있습니다.");
      return;
    }
    
    // 주문 로직 처리 후 관리자 페이지로 이동
    alert("주문이 완료되었습니다! 관리자 페이지로 이동합니다.");
    localStorage.removeItem('cart'); // 주문 후 장바구니 비우기
    router.push('/delivery'); // 관리자 배달 주문 내역 페이지로 이동
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

          {/* 주문하기 버튼 추가 */}
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