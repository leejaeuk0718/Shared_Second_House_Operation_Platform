"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import styles from "./page.module.css";
import { StayAccommodationDto, StayAccommodationPriceDto } from "../page";

import { api } from "@/lib/api";
import { tokenStorage } from "@/lib/token";
import { UserResp } from "@/types/auth";
import { SubscriptionsUserResp } from "@/types/subscription";
import { MONTH_OPTIONS, TEAM_OPTIONS } from "@/app/lib/constants";
import { calcTeamPrice } from "@/app/lib/priceUtils";
import ImageSlider from "./components/ImageSlider";
import PriceTable from "./components/PriceTable";
import HouseStructure from "./components/HouseStructure";
import AmenityGrid from "./components/AmenityGrid";
import StorySection from "./components/StorySection";
import LocationMap from "./components/LocationMap";
import { TEMP_USER_ID } from "@/app/lib/auth";

export interface StayStoryDto {
  id: number;
  orderNum: number;
  title: string;
  content: string;
  imageUrl: string;
}

type SubscriptionStatus = "none" | "waiting" | "active" | "expired";

export default function AccommodationDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [accommodation, setAccommodation] =
    useState<StayAccommodationDto | null>(null);
  const [stories, setStories] = useState<StayStoryDto[]>([]);
  const [subscriptionStatus, setSubscriptionStatus] =
    useState<SubscriptionStatus>("none");
  const [loading, setLoading] = useState(true);
  const [authed, setAuthed] = useState(false);

  const [teams, setTeams] = useState(1);
  const [months, setMonths] = useState(1);

  const userId = TEMP_USER_ID;

  useEffect(() => {
    if (!id) return;

    // 숙소 + 스토리는 항상 조회 (비회원도 정상 표시)
    Promise.all([
      api.get<StayAccommodationDto>(`/api/stay/accommodations/${id}`),
      api.get<StayStoryDto[]>(`/api/stay/stories/${id}`),
    ])
      .then(([accommodationData, storiesData]) => {
        setAccommodation(accommodationData);
        setStories(storiesData);
      })
      .catch((err) => {
        console.log("숙소 데이터 조회 실패:", err);
      })
      .finally(() => setLoading(false));

    // 구독 상태는 토큰이 있을 때만 별도 조회 — 실패해도 숙소 화면에 영향 없음
    if (tokenStorage.get()) {
      setAuthed(true);
      api
        .get<SubscriptionsUserResp[]>(`/api/subscriptions/my/${userId}`)
        .then((subscriptionData) => {
          const matched = Array.isArray(subscriptionData)
            ? subscriptionData.find((s) => s.accommodationId === Number(id))
            : null;

          if (!matched) {
            setSubscriptionStatus("none");
          } else if (matched.status === "PENDING") {
            setSubscriptionStatus("waiting");
          } else if (matched.status === "ACTIVE") {
            setSubscriptionStatus("active");
          } else if (matched.status === "EXPIRED") {
            setSubscriptionStatus("expired");
          } else {
            setSubscriptionStatus("none");
          }
        })
        .catch(() => setSubscriptionStatus("none"));
    }
  }, [id]);

  if (loading) return <div className={styles.loading}>불러오는 중...</div>;
  if (!accommodation)
    return <div className={styles.loading}>숙소를 찾을 수 없습니다.</div>;

  const teamPrice = calcTeamPrice(
    accommodation.monthlyPrice,
    accommodation.prices ?? [],
    months,
    teams,
  );

  return (
    <div className={styles.container}>
      <ImageSlider
        imageUrl={accommodation.imageUrl}
        name={accommodation.name}
      />

      <div className={styles.body}>
        <div className={styles.content}>
          <h1 className={styles.title}>{accommodation.name}</h1>
          <p className={styles.description}>{accommodation.description}</p>

          <PriceTable
            monthlyPrice={accommodation.monthlyPrice}
            prices={accommodation.prices ?? []}
          />

          <LocationMap
            accommodationId={accommodation.id}
            latitude={accommodation.latitude}
            longitude={accommodation.longitude}
            address={accommodation.address}
            showMap={true}
          />

          <HouseStructure
            roomCount={accommodation.roomCount}
            bathroomCount={accommodation.bathroomCount}
            floorCount={accommodation.floorCount}
            parkingCount={accommodation.parkingCount}
            landArea={accommodation.landArea}
            buildingArea={accommodation.buildingArea}
          />

          <AmenityGrid amenities={accommodation.amenities} />

          <StorySection stories={stories} />
        </div>

        <aside className={styles.sidebar}>
          <div className={styles.sidebarInner}>
            <h2 className={styles.sidebarTitle}>{accommodation.name}</h2>

            <div className={styles.selectGroup}>
              <label className={styles.selectLabel}>같이 사용할 팀 수</label>
              <select
                className={styles.select}
                value={teams}
                onChange={(e) => setTeams(Number(e.target.value))}
              >
                {TEAM_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className={styles.selectGroup}>
              <label className={styles.selectLabel}>계약 월 수</label>
              <select
                className={styles.select}
                value={months}
                onChange={(e) => setMonths(Number(e.target.value))}
              >
                {MONTH_OPTIONS.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className={styles.priceWrap}>
              <span className={styles.priceLabel}>팀당 월세</span>
              <span className={styles.price}>
                {teamPrice > 0 ? `${teamPrice.toLocaleString()}원` : "-"}
              </span>
              <span className={styles.priceUnit}>/ 개월</span>
            </div>

            {subscriptionStatus === "none" && (
              <button
                className="btn-primary"
                onClick={() => router.push(`/subscribe/${id}`)}
              >
                구독하러가기
              </button>
            )}
            {subscriptionStatus === "waiting" && (
              <button className="btn-disabled" disabled>
                승인 대기 중
              </button>
            )}
            {subscriptionStatus === "active" && (
              <button
                className="btn-primary"
                onClick={() => router.push(`/reservations/${id}`)}
              >
                예약하기
              </button>
            )}
            {subscriptionStatus === "expired" && (
              <button
                className="btn-primary"
                onClick={() => router.push(`/subscribe/${id}`)}
              >
                재구독하기
              </button>
            )}
          </div>
        </aside>
      </div>
    </div>
  );
}
