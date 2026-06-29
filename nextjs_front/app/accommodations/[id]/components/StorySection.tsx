/*
 * ==================================================================================
 * [파일 정보]
 * 위치  : app/accommodations/[id]/components/StorySection.tsx
 * 역할  : 숙소 스토리 목록 섹션 (순서, 제목, 본문, 이미지)
 * 사용처 : app/accommodations/[id]/page.tsx
 * ----------------------------------------------------------------------------------
 * [연관 파일]
 * - StorySection.module.css             : 스토리 섹션 스타일
 * - app/accommodations/[id]/page.tsx    : 부모 (stories[] props 전달)
 * - Spring: StayStoryController.java    : GET /api/stay/stories/{accommodationId}
 * ----------------------------------------------------------------------------------
 * [기능 목록]
 * - orderNum 기준 오름차순 정렬
 * - 순서번호(01_, 02_ ...) + 제목 + 본문 + 이미지 표시
 * - stories 없으면 null 반환 (렌더링 안 함)
 * ==================================================================================
 */

import styles from './StorySection.module.css';
import { StayStoryDto } from '../page';

interface StorySectionProps {
  stories: StayStoryDto[];
}

export default function StorySection({ stories }: StorySectionProps) {
  if (!stories || !Array.isArray(stories) || stories.length === 0) return null;

  // orderNum 순서대로 정렬
  const sorted = [...stories].sort((a, b) => a.orderNum - b.orderNum);

  return (
    <section className={styles.section}>
      {sorted.map((story) => (
        <div key={story.id} className={styles.storyItem}>
          {/* 제목 */}
          <h2 className={styles.storyTitle}>
            <span className={styles.orderNum}>
              {String(story.orderNum).padStart(2, '0')}_
            </span>
            {story.title}
          </h2>

          {/* 본문 */}
          <p className={styles.storyContent}>{story.content}</p>

          {/* 이미지 */}
          {story.imageUrl && (
            <div className={styles.imageWrap}>
              <img
                src={`${process.env.NEXT_PUBLIC_SERVER_URL}${story.imageUrl}`}
                alt={story.title}
                className={styles.image}
              />
            </div>
          )}
        </div>
      ))}
    </section>
  );
}
