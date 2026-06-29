'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import styles from './page.module.css';
import { StayAccommodationDto } from './accommodations/page';

export default function Home() {
  const router = useRouter();
  const [accommodations, setAccommodations] = useState<StayAccommodationDto[]>(
    []
  );
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${process.env.NEXT_PUBLIC_SERVER_URL}/api/stay/accommodations`)
      .then((r) => r.json())
      .then((data) => {
        console.log('[Home] 숙소 목록:', data);
        setAccommodations(data.content ?? []);
      })
      .catch((err) => console.log('[Home] 데이터 조회 실패:', err))
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className={styles.container}>
      {/* 숙소 목록 섹션 */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>우리가 머물 집</h2>
        <p className={styles.sectionDesc}>지금부터 하나씩 살펴봐요</p>

        {loading ? (
          <div className={styles.loading}>불러오는 중...</div>
        ) : (
          <div className={styles.grid}>
            {accommodations.slice(0, 3).map((accommodation) => (
              <div
                key={accommodation.id}
                className={styles.card}
                onClick={() =>
                  router.push(`/accommodations/${accommodation.id}`)
                }
              >
                {/* 이미지 */}
                <div className={styles.imageWrap}>
                  {accommodation.imageUrl ? (
                    <img
                      src={`${process.env.NEXT_PUBLIC_SERVER_URL}${accommodation.imageUrl.split(',')[0].trim()}`}
                      alt={accommodation.name}
                      className={styles.image}
                    />
                  ) : (
                    <div className={styles.imagePlaceholder}>이미지 없음</div>
                  )}
                  {/* 이미지 위 지역명 오버레이 */}
                  <div className={styles.overlay}>
                    <span className={styles.region}>
                      {accommodation.address.split(' ').slice(0, 2).join(' ')}
                    </span>
                  </div>
                </div>

                {/* 숙소 정보 */}
                <div className={styles.info}>
                  <h3 className={styles.name}>{accommodation.name}</h3>
                  {/* amenities 앞 3개 해시태그로 표시 */}
                  <div className={styles.tags}>
                    {accommodation.amenities
                      ?.split(',')
                      .slice(0, 3)
                      .map((tag, i) => (
                        <span key={i} className={styles.tag}>
                          #{tag.trim()}
                        </span>
                      ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* 숙소 목록 더 보기 버튼 */}
        <div className={styles.moreWrap}>
          <button
            className="btn-outline"
            onClick={() => router.push('/accommodations')}
          >
            숙소 목록 더 보러가기
          </button>
        </div>
      </section>
    </div>
  );
}