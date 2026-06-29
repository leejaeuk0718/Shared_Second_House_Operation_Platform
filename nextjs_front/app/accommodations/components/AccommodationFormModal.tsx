"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { tokenStorage } from "@/lib/token";
import { StayAccommodationDto } from "../page";

interface StoryRow {
  id?: number; // 기존 스토리면 id 있음, 새로 추가한 행이면 undefined
  orderNum: string;
  title: string;
  content: string;
  imageFile: File | null;
  existingImageUrl?: string;
}

interface StayStoryResp {
  id: number;
  accommodationId: number;
  orderNum: number;
  title: string;
  content: string;
  imageUrl: string;
}

interface Props {
  mode: "create" | "edit";
  initialData?: StayAccommodationDto;
  onClose: () => void;
  onSuccess: () => void;
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080";

export default function AccommodationFormModal({
  mode,
  initialData,
  onClose,
  onSuccess,
}: Props) {
  const [name, setName] = useState(initialData?.name ?? "");
  const [address, setAddress] = useState(initialData?.address ?? "");
  const [description, setDescription] = useState(
    initialData?.description ?? "",
  );
  const [monthlyPrice, setMonthlyPrice] = useState(
    initialData?.monthlyPrice != null ? String(initialData.monthlyPrice) : "",
  );
  const [status, setStatus] = useState<"AVAILABLE" | "MAINTENANCE">(
    initialData?.status ?? "AVAILABLE",
  );

  const [roomCount, setRoomCount] = useState(
    initialData?.roomCount != null ? String(initialData.roomCount) : "",
  );
  const [bathroomCount, setBathroomCount] = useState(
    initialData?.bathroomCount != null ? String(initialData.bathroomCount) : "",
  );
  const [floorCount, setFloorCount] = useState(
    initialData?.floorCount != null ? String(initialData.floorCount) : "",
  );
  const [parkingCount, setParkingCount] = useState(
    initialData?.parkingCount != null ? String(initialData.parkingCount) : "",
  );
  const [landArea, setLandArea] = useState(
    initialData?.landArea != null ? String(initialData.landArea) : "",
  );
  const [buildingArea, setBuildingArea] = useState(
    initialData?.buildingArea != null ? String(initialData.buildingArea) : "",
  );
  const [latitude, setLatitude] = useState(
    initialData?.latitude != null ? String(initialData.latitude) : "",
  );
  const [longitude, setLongitude] = useState(
    initialData?.longitude != null ? String(initialData.longitude) : "",
  );
  const [amenities, setAmenities] = useState(initialData?.amenities ?? "");

  const [imageFiles, setImageFiles] = useState<File[]>([]);
  const [stories, setStories] = useState<StoryRow[]>([]);
  const [loadingStories, setLoadingStories] = useState(mode === "edit");

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState("");

  // 수정 모드면 기존 스토리 목록을 불러옴
  useEffect(() => {
    if (mode !== "edit" || !initialData) return;

    api
      .get<StayStoryResp[]>(`/api/stay/stories/${initialData.id}`)
      .then((list) => {
        setStories(
          list.map((s) => ({
            id: s.id,
            orderNum: String(s.orderNum),
            title: s.title,
            content: s.content,
            imageFile: null,
            existingImageUrl: s.imageUrl,
          })),
        );
      })
      .catch((err) => console.log("스토리 목록 조회 실패:", err))
      .finally(() => setLoadingStories(false));
  }, [mode, initialData]);

  const addStoryRow = () => {
    setStories((prev) => [
      ...prev,
      {
        orderNum: String(prev.length + 1),
        title: "",
        content: "",
        imageFile: null,
      },
    ]);
  };

  const removeStoryRow = (index: number) => {
    setStories((prev) => prev.filter((_, i) => i !== index));
  };

  const updateStoryRow = (
    index: number,
    field: "orderNum" | "title" | "content",
    value: string,
  ) => {
    setStories((prev) =>
      prev.map((row, i) => (i === index ? { ...row, [field]: value } : row)),
    );
  };

  const updateStoryImage = (index: number, file: File | null) => {
    setStories((prev) =>
      prev.map((row, i) => (i === index ? { ...row, imageFile: file } : row)),
    );
  };

  const buildPayload = () => ({
    name,
    address,
    description,
    imageUrl: initialData?.imageUrl ?? "",
    amenities,
    monthlyPrice: monthlyPrice ? Number(monthlyPrice) : null,
    roomCount: roomCount ? Number(roomCount) : null,
    bathroomCount: bathroomCount ? Number(bathroomCount) : null,
    floorCount: floorCount ? Number(floorCount) : null,
    parkingCount: parkingCount ? Number(parkingCount) : null,
    landArea: landArea ? Number(landArea) : null,
    buildingArea: buildingArea ? Number(buildingArea) : null,
    latitude: latitude ? Number(latitude) : null,
    longitude: longitude ? Number(longitude) : null,
    status,
  });

  const uploadAccommodationImages = async (accommodationId: number) => {
    if (imageFiles.length === 0) return;
    const formData = new FormData();
    imageFiles.forEach((file) => formData.append("files", file));
    const token = tokenStorage.get();
    await fetch(
      `${API_BASE}/api/stay/accommodations/${accommodationId}/images`,
      {
        method: "POST",
        headers: token ? { Authorization: `Bearer ${token}` } : {},
        body: formData,
      },
    );
  };

  const uploadStoryImage = async (storyId: number, file: File) => {
    const formData = new FormData();
    formData.append("file", file);
    const token = tokenStorage.get();
    await fetch(`${API_BASE}/api/stay/stories/${storyId}/images`, {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData,
    });
  };

  const saveStories = async (accommodationId: number) => {
    for (const story of stories) {
      if (!story.title.trim()) continue; // 빈 행은 건너뜀

      if (story.id) {
        // 기존 스토리 수정
        await api.put(`/api/stay/stories/${story.id}`, {
          accommodationId,
          orderNum: Number(story.orderNum),
          title: story.title,
          content: story.content,
          imageUrl: story.existingImageUrl ?? "",
        });
        if (story.imageFile) {
          await uploadStoryImage(story.id, story.imageFile);
        }
      } else {
        // 새 스토리 등록
        const created = await api.post<StayStoryResp>("/api/stay/stories", {
          accommodationId,
          orderNum: Number(story.orderNum),
          title: story.title,
          content: story.content,
          imageUrl: "",
        });
        if (story.imageFile) {
          await uploadStoryImage(created.id, story.imageFile);
        }
      }
    }
  };

  const handleSubmit = async () => {
    if (!name.trim() || !address.trim()) {
      setError("숙소명과 주소는 필수예요.");
      return;
    }

    setSubmitting(true);
    setError("");

    try {
      let accommodationId: number;

      if (mode === "create") {
        const created = await api.post<StayAccommodationDto>(
          "/api/stay/accommodations",
          buildPayload(),
        );
        accommodationId = created.id;
      } else {
        const updated = await api.put<StayAccommodationDto>(
          `/api/stay/accommodations/${initialData!.id}`,
          buildPayload(),
        );
        accommodationId = updated.id;
      }

      await uploadAccommodationImages(accommodationId);
      await saveStories(accommodationId);

      onSuccess();
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "처리에 실패했습니다.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,0.45)",
        display: "flex",
        alignItems: "flex-start",
        justifyContent: "center",
        padding: "24px 0",
        zIndex: 50,
        overflowY: "auto",
      }}
    >
      <div
        style={{
          width: 560,
          background: "#F7F4EF",
          borderRadius: 16,
          border: "0.5px solid #E4DDD3",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "18px 20px",
            borderBottom: "0.5px solid #E4DDD3",
          }}
        >
          <p
            style={{
              fontSize: 16,
              fontWeight: 500,
              color: "#2A2520",
              margin: 0,
            }}
          >
            {mode === "create" ? "숙소 등록" : "숙소 수정"}
          </p>
          <button
            onClick={onClose}
            style={{
              border: "none",
              background: "none",
              cursor: "pointer",
              fontSize: 18,
              color: "#8C8178",
            }}
          >
            ✕
          </button>
        </div>

        <div style={{ padding: 20 }}>
          {error && (
            <p style={{ fontSize: 13, color: "#A32D2D", marginBottom: 12 }}>
              {error}
            </p>
          )}

          <p
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: "#3B6D11",
              margin: "0 0 10px",
            }}
          >
            기본 정보
          </p>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: 10,
              marginBottom: 14,
            }}
          >
            <Field label="숙소명" gridColumn="1 / 3">
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="예: 강릉 오션뷰 하우스"
                style={inputStyle}
              />
            </Field>
            <Field label="주소" gridColumn="1 / 3">
              <input
                value={address}
                onChange={(e) => setAddress(e.target.value)}
                placeholder="예: 강원도 강릉시 ..."
                style={inputStyle}
              />
            </Field>
            <Field label="숙소 설명" gridColumn="1 / 3">
              <textarea
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="숙소에 대한 설명을 입력하세요"
                style={{ ...inputStyle, resize: "none", fontFamily: "inherit" }}
              />
            </Field>
            <Field label="월세 (원)">
              <input
                type="number"
                value={monthlyPrice}
                onChange={(e) => setMonthlyPrice(e.target.value)}
                placeholder="1200000"
                style={inputStyle}
              />
            </Field>
            <Field label="상태">
              <select
                value={status}
                onChange={(e) =>
                  setStatus(e.target.value as "AVAILABLE" | "MAINTENANCE")
                }
                style={inputStyle}
              >
                <option value="AVAILABLE">AVAILABLE</option>
                <option value="MAINTENANCE">MAINTENANCE</option>
              </select>
            </Field>
          </div>

          <p
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: "#3B6D11",
              margin: "16px 0 10px",
            }}
          >
            구조 정보
          </p>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(4, 1fr)",
              gap: 8,
              marginBottom: 14,
            }}
          >
            <Field label="방 수">
              <input
                type="number"
                value={roomCount}
                onChange={(e) => setRoomCount(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="화장실">
              <input
                type="number"
                value={bathroomCount}
                onChange={(e) => setBathroomCount(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="층수">
              <input
                type="number"
                value={floorCount}
                onChange={(e) => setFloorCount(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="주차">
              <input
                type="number"
                value={parkingCount}
                onChange={(e) => setParkingCount(e.target.value)}
                style={inputStyle}
              />
            </Field>
          </div>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: 10,
              marginBottom: 14,
            }}
          >
            <Field label="대지면적 (평)">
              <input
                type="number"
                value={landArea}
                onChange={(e) => setLandArea(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="건물면적 (평)">
              <input
                type="number"
                value={buildingArea}
                onChange={(e) => setBuildingArea(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="위도">
              <input
                type="number"
                value={latitude}
                onChange={(e) => setLatitude(e.target.value)}
                style={inputStyle}
              />
            </Field>
            <Field label="경도">
              <input
                type="number"
                value={longitude}
                onChange={(e) => setLongitude(e.target.value)}
                style={inputStyle}
              />
            </Field>
          </div>

          <p
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: "#3B6D11",
              margin: "16px 0 10px",
            }}
          >
            구성용품
          </p>
          <input
            value={amenities}
            onChange={(e) => setAmenities(e.target.value)}
            placeholder="에어컨, 세탁기, 와이파이 (쉼표로 구분)"
            style={{ ...inputStyle, marginBottom: 14 }}
          />

          <p
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: "#3B6D11",
              margin: "16px 0 10px",
            }}
          >
            이미지
          </p>
          <label
            style={{
              display: "block",
              border: "1.5px dashed #D6E4C8",
              borderRadius: 8,
              padding: 20,
              textAlign: "center",
              marginBottom: 14,
              background: "white",
              cursor: "pointer",
            }}
          >
            <input
              type="file"
              multiple
              accept="image/*"
              style={{ display: "none" }}
              onChange={(e) => setImageFiles(Array.from(e.target.files ?? []))}
            />
            <p style={{ fontSize: 12, color: "#8C8178", margin: 0 }}>
              {imageFiles.length > 0
                ? `${imageFiles.length}개 파일 선택됨`
                : mode === "edit"
                  ? "새 이미지를 추가하려면 선택하세요"
                  : "클릭해서 이미지를 선택하세요"}
            </p>
          </label>

          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              margin: "16px 0 10px",
            }}
          >
            <p
              style={{
                fontSize: 12,
                fontWeight: 500,
                color: "#3B6D11",
                margin: 0,
              }}
            >
              숙소 스토리
            </p>
            <button
              onClick={addStoryRow}
              style={{ fontSize: 12, padding: "5px 10px" }}
            >
              + 스토리 추가
            </button>
          </div>

          {loadingStories ? (
            <p style={{ fontSize: 12, color: "#8C8178" }}>
              스토리 불러오는 중...
            </p>
          ) : (
            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {stories.map((story, i) => (
                <div
                  key={story.id ?? `new-${i}`}
                  style={{
                    border: "0.5px solid #E4DDD3",
                    borderRadius: 8,
                    padding: 10,
                    background: "white",
                  }}
                >
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns: "60px 1fr auto",
                      gap: 8,
                      marginBottom: 8,
                    }}
                  >
                    <input
                      type="number"
                      placeholder="순서"
                      value={story.orderNum}
                      onChange={(e) =>
                        updateStoryRow(i, "orderNum", e.target.value)
                      }
                      style={{
                        ...inputStyle,
                        padding: "7px 8px",
                        fontSize: 12,
                      }}
                    />
                    <input
                      placeholder="스토리 제목"
                      value={story.title}
                      onChange={(e) =>
                        updateStoryRow(i, "title", e.target.value)
                      }
                      style={{
                        ...inputStyle,
                        padding: "7px 8px",
                        fontSize: 12,
                      }}
                    />
                    <button
                      onClick={() => removeStoryRow(i)}
                      style={{
                        border: "none",
                        background: "none",
                        color: "#D85A30",
                        cursor: "pointer",
                      }}
                    >
                      ✕
                    </button>
                  </div>
                  <textarea
                    rows={2}
                    placeholder="스토리 본문"
                    value={story.content}
                    onChange={(e) =>
                      updateStoryRow(i, "content", e.target.value)
                    }
                    style={{
                      ...inputStyle,
                      padding: "7px 8px",
                      fontSize: 12,
                      resize: "none",
                      fontFamily: "inherit",
                      marginBottom: 8,
                    }}
                  />
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(e) =>
                      updateStoryImage(i, e.target.files?.[0] ?? null)
                    }
                    style={{ fontSize: 11 }}
                  />
                  {story.existingImageUrl && !story.imageFile && (
                    <span
                      style={{ fontSize: 11, color: "#8C8178", marginLeft: 8 }}
                    >
                      기존 이미지 있음
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        <div
          style={{
            display: "flex",
            justifyContent: "flex-end",
            gap: 8,
            padding: "14px 20px",
            borderTop: "0.5px solid #E4DDD3",
          }}
        >
          <button
            onClick={onClose}
            style={{ fontSize: 13, padding: "7px 16px" }}
          >
            취소
          </button>
          <button
            onClick={handleSubmit}
            disabled={submitting}
            style={{
              fontSize: 13,
              padding: "7px 16px",
              background: "#3B6D11",
              color: "white",
              border: "none",
              borderRadius: 6,
            }}
          >
            {submitting
              ? "처리 중..."
              : mode === "create"
                ? "등록하기"
                : "수정하기"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  children,
  gridColumn,
}: {
  label: string;
  children: React.ReactNode;
  gridColumn?: string;
}) {
  return (
    <div style={gridColumn ? { gridColumn } : undefined}>
      <label
        style={{
          fontSize: 12,
          color: "#8C8178",
          display: "block",
          marginBottom: 4,
        }}
      >
        {label}
      </label>
      {children}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: "100%",
  border: "1px solid #D6E4C8",
  borderRadius: 6,
  padding: "8px 10px",
  fontSize: 13,
  background: "white",
  boxSizing: "border-box",
};
