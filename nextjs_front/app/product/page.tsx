'use client';

import React from 'react';
import { useRouter } from 'next/navigation';

interface Product {
  id: number;
  name: string;
  price: number;
  image: string;
}

export default function ProductListPage() {
  const router = useRouter();

  const products: Product[] = [
    { id: 1, name: "[추천] 오션뷰 세컨하우스 1박 이용권", price: 150000, image: "ocean.png" },
    { id: 2, name: "[조식] 수제 샌드위치 & 커피 세트", price: 12000, image: "sandwich.png" },
    { id: 3, name: "[시그니처] 대나무 바베큐 플래터", price: 45000, image: "bbq.png" },
    { id: 4, name: "[가정간편식] 얼큰 차돌된장찌개", price: 18000, image: "stew.png" },
    { id: 5, name: "콜라 / 사이다 500ml 캔", price: 2500, image: "drink.png" },
  ];

  // 1. 담기 버튼 클릭 시 localStorage에 직접 저장 (setCart 사용 안 함)
  const handleAddToCart = (product: Product) => {
    const existingCart = localStorage.getItem('cart');
    const cart = existingCart ? JSON.parse(existingCart) : [];
    cart.push(product);
    localStorage.setItem('cart', JSON.stringify(cart));
    
    alert(`${product.name}이(가) 담겼습니다!`);
    // 버튼 클릭 후 새로고침 없이 동작을 원하면 페이지 이동도 가능
    // router.push('/cart');
  };

  return (
    <div style={{ padding: '24px' }}>
      {/* 장바구니 바로가기 버튼 */}
      <button 
        onClick={() => router.push('/cart')}
        style={{ padding: '10px 20px', marginBottom: '20px', cursor: 'pointer' }}
      >
        🛒 장바구니 보기
      </button>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '24px' }}>
        {products.map((product) => (
          <div key={product.id} style={{ border: '1px solid #e2e8f0', borderRadius: '16px', overflow: 'hidden', backgroundColor: '#ffffff', boxShadow: '0 4px 6px -1px rgba(0,0,0,0.1)' }}>
            <img src={`/images/${product.image}`} alt={product.name} style={{ width: '100%', height: '180px', objectFit: 'cover' }} />
            <div style={{ padding: '16px' }}>
              <h3 style={{ fontSize: '16px', marginBottom: '8px' }}>{product.name}</h3>
              <p style={{ color: '#666', marginBottom: '16px' }}>{product.price.toLocaleString()}원</p>
              
              <button 
                style={{ width: '100%', padding: '10px', backgroundColor: '#2E6F40', color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer' }}
                onClick={() => handleAddToCart(product)}
              >
                담기
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}