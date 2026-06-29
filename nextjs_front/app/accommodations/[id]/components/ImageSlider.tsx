/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/ImageSlider.tsx
 * 역할  : 숙소 상세 페이지 상단 이미지 슬라이더
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - ImageSlider.module.css              : 슬라이더 스타일
 * - app/accommodations/[id]/page.tsx    : 부모 (imageUrl, name props 전달)
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - 쉼표 구분 imageUrl → 이미지 배열로 파싱
 * - 3초마다 자동 슬라이드 (이미지 2개 이상일 때)
 * - 이전/다음 버튼으로 수동 이동
 * - 하단 인디케이터 점으로 현재 위치 표시 및 직접 이동
 * - 이미지 없을 때 플레이스홀더 표시
 * ----------------------------------------------------------------------------------
 * [파일 흐름과 순서]
 * imageUrl props 수신 → 쉼표 split → images 배열 생성
 * → useEffect 자동 슬라이드 타이머 등록 → 이미지 렌더링
 * → 이전/다음 버튼 클릭 → setCurrent 업데이트
 * ==================================================================================
 */

'use client';

import { useState, useEffect } from 'react';
import styles from './ImageSlider.module.css';

interface ImageSliderProps {
  imageUrl: string;
  name: string;
}

export default function ImageSlider({ imageUrl, name }: ImageSliderProps) {
  const images = imageUrl
  ? imageUrl.split(',').map((url) => `${process.env.NEXT_PUBLIC_SERVER_URL}${url.trim()}`)
  : [];
  const [current, setCurrent] = useState(0);

  // 자동 슬라이드 (3초)
  useEffect(() => {
    if (images.length <= 1) return;
    const timer = setInterval(() => {
      setCurrent((prev) => (prev + 1) % images.length);
    }, 3000);
    return () => clearInterval(timer);
  }, [images.length]);

  // 이미지 없을 때
  if (images.length === 0) {
    return (
      <div className={styles.placeholder}>
        <span>이미지 없음</span>
      </div>
    );
  }

  const goPrev = () => setCurrent((prev) => (prev - 1 + images.length) % images.length);
  const goNext = () => setCurrent((prev) => (prev + 1) % images.length);

  return (
    <div className={styles.slider}>
      {/* 이미지 */}
      <img
        src={images[current]}
        alt={`${name} ${current + 1}`}
        className={styles.image}
      />

      {/* 이전/다음 버튼 */}
      {images.length > 1 && (
        <>
          <button className={`${styles.arrow} ${styles.arrowLeft}`} onClick={goPrev}>
            ‹
          </button>
          <button className={`${styles.arrow} ${styles.arrowRight}`} onClick={goNext}>
            ›
          </button>

          {/* 인디케이터 점 */}
          <div className={styles.dots}>
            {images.map((_, i) => (
              <button
                key={i}
                className={`${styles.dot} ${i === current ? styles.dotActive : ''}`}
                onClick={() => setCurrent(i)}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
}