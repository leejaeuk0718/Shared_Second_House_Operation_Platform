import Image from "next/image";

interface AuthLayoutProps {
  children: React.ReactNode;
  imageSrc?: string;
  headline: string;
  subline: string;
}

export default function AuthLayout({
  children,
  imageSrc = "/images/auth-bg.jpg",
  headline,
  subline,
}: AuthLayoutProps) {
  return (
    <div className="relative w-full h-screen overflow-hidden">
      {/* 배경 이미지 — 화면 전체 꽉 채움 */}
      <Image
        src={imageSrc}
        alt="Second House"
        fill
        priority
        className="object-cover"
        sizes="100vw"
      />

      {/* 어두운 오버레이 */}
      <div className="absolute inset-0 bg-black/15" />

      {/* 오른쪽 하단 문구 */}
      <div className="absolute bottom-12 right-12 z-10 text-right">
        <h1 className="text-white text-6xl font-bold leading-tight drop-shadow-lg whitespace-pre-line">
          {headline}
        </h1>
        <p className="mt-4 text-white/80 text-lg">{subline}</p>
      </div>

      {/* 곡선 패널 */}
      <div className="absolute left-0 top-0 h-full w-[420px] z-20">
        <svg
          className="absolute left-0 top-0 h-full w-full"
          viewBox="0 0 420 1000"
          preserveAspectRatio="none"
        >
          <path
            d="
              M0,0
              L300,0
              C420,180 420,350 300,500
              C420,650 420,820 300,1000
              L0,1000
              Z
            "
            fill="white"
          />
        </svg>

        {/* 컨텐츠 */}
        <div className="relative h-full flex flex-col justify-center py-12 pl-10 pr-2 translate-x-14">
          <div className="mb-8">
            <p className="text-[#3B6D11] text-sm font-semibold tracking-[0.35em]">
              SECOND HOUSE
            </p>
            <div className="mt-3 h-[2px] w-12 bg-[#3B6D11]" />
          </div>
          <div className="relative h-full flex flex-col justify-center py-12 pl-10 translate-x-12">
            <div className="w-[340px]">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
