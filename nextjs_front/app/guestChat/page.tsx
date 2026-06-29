"use client"; // Next.js App Router에서 이 컴포넌트가 클라이언트 사이드(브라우저)에서만 실행됨을 명시

import { useSearchParams } from "next/navigation";
import { useEffect, useState, useRef, Suspense } from "react";
import { Client } from "@stomp/stompjs"; // 웹소켓(STOMP) 프로토콜을 사용하기 위한 클라이언트 라이브러리
import { api } from "@/lib/api"; // 공통 api 모듈 경로

// [타입 정의] 백엔드 및 웹소켓 서버와 주고받을 채팅 메시지의 데이터 규격 선언
interface ChatMessage {
  chatId?: number; // 메시지 식별 고유 ID (선택적)
  chatRoomId: number; // 채팅방 고유 번호
  senderId: number; // 발신자 고유 ID
  senderName: string; // 발신자 이름
  content?: string; // 메시지 내용 (실시간 발신용)
  messageContent?: string; // 메시지 내용 (과거 이력 조회 API용 데이터 매핑)
  sentAt?: string; // 발신 시간 (선택적)
  writer?: string; // 작성자 표기 다변화 대비용 필드들
  senderNickname?: string;
  userName?: string;
  userId?: number; // ➕ 백엔드에서 과거 내역을 userId로 줄 경우를 대비해 추가
}

function GuestChatContent() {
  // 브라우저 주소창의 '?roomId=1' 형태에서 방 번호를 가져와 숫자로 변환
  const searchParams = useSearchParams();
  const chatRoomId = Number(searchParams.get("roomId"));

  // 🔄 [수정] 하드코딩(100)을 지우고, 로그인한 실제 유저 정보를 담을 상태 관리
  const [senderId, setSenderId] = useState<number | null>(null);
  const [senderName, setSenderName] = useState<string>("게스트");

  // [상태 관리] 메시지 배열, 입력창 텍스트, 화면 로딩 상태 관리
  const [messages, setMessages] = useState<ChatMessage[]>([]); // 채팅 기록 상태
  const [inputText, setInputText] = useState(""); // 입력 폼 상태
  const [isLoading, setIsLoading] = useState(true); // 과거 내역 조회 완료 여부

  // [참조 관리] 컴포넌트 리렌더링과 상관없이 유지가 필요한 웹소켓 객체와 스크롤 DOM 노드 보관
  const stompClientRef = useRef<Client | null>(null); // 웹소켓 연결 세션 유지용
  const scrollRef = useRef<HTMLDivElement | null>(null); // 새 메시지 수신 시 스크롤 아래로 내리기 위한 용도

  // -------------------------------------------------------------------------------
  // ➕ [추가] 로그인 유저 정보 가져오기 (마이페이지와 동일한 API 주소 연동)
  // [수정] 로그인 유저 정보 가져오기 (fetch 대신 공통 api 모듈로 변경)
  // -------------------------------------------------------------------------------
  useEffect(() => {
    const fetchCurrentUser = async () => {
      try {
        const userData = await api.get<{
          userId: number;
          nickname?: string;
          username?: string;
        }>("/api/users");

        if (userData && userData.userId) {
          setSenderId(userData.userId); // 이제 정상적으로 4번 ID가 안착합니다!
          setSenderName(userData.nickname || userData.username || "게스트");
          console.log("✅ 채팅방 유저 연동 성공:", userData.userId);
        }
      } catch (error) {
        console.error("❌ 유저 정보 로드 실패:", error);
        // 토큰 만료 등의 예외 상황을 고려한 개발/테스트용 방어코드
        setSenderId(4);
      }
    };
    fetchCurrentUser();
  }, []);

  // -------------------------------------------------------------------------------
  // 1. 과거 메시지 내역 조회 (HTTP GET)
  // 컴포넌트가 처음 마운트되거나 chatRoomId가 변경될 때 기존 API에서 과거 대화 내용을 가져옴
  // -------------------------------------------------------------------------------
  useEffect(() => {
    if (!chatRoomId) return;

    const fetchChatHistory = async () => {
      try {
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_SERVER_URL}/api/guest/chat/history/${chatRoomId}`,
        );
        if (response.ok) {
          const historyData = await response.json();

          // 💡 브라우저 F12 개발자도구 콘솔에서 백엔드가 주는 실제 필드명이 무엇인지 체크하기 위한 로그
          console.log("🎬 백엔드 원본 데이터 확인:", historyData);

          setMessages(historyData); // 가져온 배열 데이터로 대화 창 초기화
        }
      } catch (error) {
        console.error("❌ 과거 채팅 내역 로드 실패:", error);
      } finally {
        setIsLoading(false); // 성공 여부와 관계없이 로딩 상태 해제
      }
    };

    fetchChatHistory();
  }, [chatRoomId]);

  // -------------------------------------------------------------------------------
  // 2. STOMP 웹소켓 실시간 연결 및 구독(Subscribe)
  // 컴포넌트 활성화 시 웹소켓을 연결하고 특정 방의 실시간 메시지 발행 채널을 리슨(Listen)함
  // -------------------------------------------------------------------------------
  useEffect(() => {
    if (!chatRoomId) return;

    const socketUrl = process.env.NEXT_PUBLIC_WEBSOCKET_URL;
    if (!socketUrl) return;

    // STOMP 클라이언트 설정 및 브로커(Broker) URL 주입
    const client = new Client({
      brokerURL: socketUrl,
      reconnectDelay: 5000, // 연결이 끊겼을 때 5초마다 자동으로 재연결 시도
      debug: (str) => console.log("🔄 [STOMP 디버그]:", str),
      onConnect: () => {
        console.log(`🚀 [웹 웹소켓] 연결 성공! ${chatRoomId}번 방 구독 시작`);

        // 서버의 특정 토픽 주소를 구독하여 다른 사람이 보낸 실시간 메시지를 수신
        client.subscribe(`/topic/guest/room/${chatRoomId}`, (message) => {
          const incoming: ChatMessage = JSON.parse(message.body); // 수신한 JSON 문자열 파싱
          setMessages((prev) => [...prev, incoming]); // 기존 대화 배열 뒤에 실시간 새 메시지 누적
        });
      },
    });

    client.activate(); // 웹소켓 연결 실행
    stompClientRef.current = client; // 전역 참조변수에 소켓 세션 저장

    // [Clean-up] 사용자가 페이지를 이탈하거나 컴포넌트가 사라질 때 웹소켓 연결을 안전하게 차단
    return () => {
      if (stompClientRef.current) {
        stompClientRef.current.deactivate();
        console.log("🔌 [웹 웹소켓] 연결 해제");
      }
    };
  }, [chatRoomId]);

  // -------------------------------------------------------------------------------
  // 3. 스크롤 자동 제어
  // 메시지 배열(messages)이 변경될 때마다(새 대화 추가 혹은 내역 로드 시) 최하단으로 스크롤 고정
  // -------------------------------------------------------------------------------
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages]);

  // -------------------------------------------------------------------------------
  // 4. 실시간 메시지 발신(Publish) 함수
  // 사용자가 입력한 메시지를 뼈대(DTO)에 담아 웹소켓 엔드포인트로 전송함
  // -------------------------------------------------------------------------------
  const handleSendMessage = () => {
    const content = inputText.trim(); // 공백 문자 제거
    if (!content || !chatRoomId) {
      console.log("⚠️ 텍스트가 비어있거나 방 번호가 없습니다.");
      return;
    }

    // 🔄 [수정] senderId가 null 혹은 undefined일 경우를 대비한 방어막 로직 추가
    if (senderId === null || senderId === undefined) {
      alert("사용자 정보를 확인하는 중입니다. 잠시 후 다시 시도해 주세요.");
      return;
    }

    // 소켓이 연결되지 않은 불안정한 상태에서의 전송을 방지하는 안전장치
    if (!stompClientRef.current?.connected) {
      console.error(
        "❌ 에러: 웹소켓이 아직 서버와 연결되지 않은 상태입니다! 발송을 차단합니다.",
      );
      return;
    }

    // 백엔드 엔드포인트 규격에 맞는 데이터 구조 작성
    const chatDto = {
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      content: content,
    };

    // 지정된 경로(/app/guest/chat/send)로 메시지 발행
    stompClientRef.current.publish({
      destination: "/app/guest/chat/send",
      body: JSON.stringify(chatDto),
    });

    setInputText(""); // 전송 완료 후 입력창 비우기
  };

  // -------------------------------------------------------------------------------
  // [예외 및 로딩 조건부 렌더링] 방 번호 유무 및 서버 비동기 로딩 대기 처리
  // -------------------------------------------------------------------------------
  if (!chatRoomId) {
    return (
      <div
        className="flex h-screen items-center justify-center font-bold"
        style={{ color: "var(--color-danger)" }}
      >
        잘못된 접근입니다. 방 번호(roomId)가 없습니다.
      </div>
    );
  }

  if (isLoading) {
    return (
      <div
        className="flex h-screen items-center justify-center"
        style={{
          color: "var(--color-text-muted)",
          fontSize: "var(--font-size-base)",
        }}
      >
        채팅방 로딩 중...
      </div>
    );
  }

  // -------------------------------------------------------------------------------
  // [메인 메인 뷰 구성 UI 구성]
  // -------------------------------------------------------------------------------
  return (
    <div
      className="flex flex-col h-screen mx-auto border-x shadow-lg"
      style={{
        maxWidth: "var(--max-width)", // 전역 변수에서 정의한 최대 가로 크기 상속
        backgroundColor: "var(--color-background)", // 전역 배경색 상속
        borderColor: "var(--color-border)", // 전역 테두리색 상속
      }}
    >
      {/* 상단 상단 바: 방 정보를 표시하며 전역 메인 포인트 컬러(초록) 적용 */}
      <header
        className="text-white p-4 text-center font-bold sticky top-0 z-50 shadow-sm"
        style={{
          backgroundColor: "var(--color-primary)",
          fontSize: "var(--font-size-lg)",
        }}
      >
        {chatRoomId}번 게스트 단체방 (Web - Query)
      </header>

      {/* ス크롤 가능한 대화 내역 출력 구역 */}
      <div ref={scrollRef} className="flex-1 p-4 overflow-y-auto space-y-3">
        {/* 안내 배너: 입장 공지 문구 */}
        <p
          className="text-center text-xs py-1 rounded-full w-2/3 mx-auto"
          style={{
            backgroundColor: "var(--color-primary-light)",
            color: "var(--color-primary)",
            fontSize: "var(--font-size-sm)",
          }}
        >
          📢 실시간 단체 채팅방에 입장하셨습니다.
        </p>

        {/* 메시지 리스트 루프 반전 및 렌더링 */}
        {messages.map((msg, index) => {
          // 🔄 [수정] 백엔드에서 넘겨주는 발신자 ID 값 추출 (과거 내역과 실시간 맵핑 명칭 방어막)
          const msgSenderId = msg.senderId ?? msg.userId;

          // 🔄 [수정] 현재 로그인한 실제 유저 아이디와 메시지 고유 발신 ID가 정확히 같을 때만 본인으로 처리
          const isMe =
            msgSenderId !== undefined &&
            msgSenderId !== null &&
            msgSenderId === senderId;

          // 다양한 백엔드 필드 명칭(content, messageContent) 유연하게 바인딩 처리
          const displayContent =
            msg.content || msg.messageContent || "내용 없음";

          // 상대방 닉네임 유연하게 바인딩 처리
          const displaySenderName =
            msg.senderName ||
            msg.writer ||
            msg.senderNickname ||
            msg.userName ||
            "다른 게스트";

          return (
            <div
              key={msg.chatId ?? index} // 데이터베이스 ID가 없을 시 루프 index를 임시 key로 사용
              className={`flex ${isMe ? "justify-end" : "justify-start"}`} // 내가 쓴 글은 우측, 상대방 글은 좌측 배치
            >
              {/* 말풍선 컨테이너: 본인 글과 상대방 글에 따라 다른 비대칭 라운딩과 배경색 부여 */}
              <div
                className={`max-w-[75%] px-4 py-2.5 shadow-sm`}
                style={{
                  fontSize: "var(--font-size-base)",
                  lineHeight: "1.6",
                  borderRadius: "var(--radius-md)",
                  borderTopRightRadius: isMe ? "0px" : "var(--radius-md)", // 내가 쓴 글이면 우측 상단 뾰족하게
                  borderTopLeftRadius: isMe ? "var(--radius-md)" : "0px", // 상대가 쓴 글이면 좌측 상단 뾰족하게
                  backgroundColor: isMe
                    ? "var(--color-primary-light)" // 본인 말풍선: 연한 브랜드 컬러
                    : "var(--color-card-bg)", // 상대방 말풍선: 공통 카드 배경색
                  color: "var(--color-foreground)",
                  border: isMe ? "none" : "1px solid var(--color-border)",
                }}
              >
                {/* 🔄 [수정] 내가 쓴 글이 아닐 때만(상대방 메시지) 위에 이름/닉네임 노출 */}
                {!isMe && (
                  <div
                    className="font-bold mb-1"
                    style={{
                      color: "var(--color-primary)",
                      fontSize: "var(--font-size-sm)",
                    }}
                  >
                    {displaySenderName}
                    {/* 데이터 구분을 확실하게 돕기 위해 상대방 아이디(ID)를 이름 옆에 연하게 표시 */}
                    <span className="text-xs font-normal text-gray-400 ml-1">
                      (ID: {msgSenderId})
                    </span>
                  </div>
                )}
                {/* 줄 바꿈과 영문 길이에 따라 레이아웃이 깨지지 않게 해주는 단어 파괴 스타일 적용 */}
                <div className="break-all">{displayContent}</div>
              </div>
            </div>
          );
        })}
      </div>

      {/* 하단 텍스트 작성 폼 레이아웃 영역 */}
      <div
        className="p-3 flex items-center gap-2 border-t"
        style={{
          backgroundColor: "var(--color-background)",
          borderColor: "var(--color-border)",
        }}
      >
        {/* 인풋 필드: 글자 제어 및 엔터키 이벤트 감지(onKeyDown) 바인딩 */}
        <input
          type="text"
          value={inputText}
          disabled={senderId === null}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
          placeholder="메시지를 입력하세요..."
          className="flex-1 px-4 py-2 focus:outline-none transition-colors"
          style={{
            backgroundColor: "var(--color-card-bg)",
            border: "1px solid var(--color-border)",
            borderRadius: "var(--radius-lg)",
            fontSize: "var(--font-size-base)",
            color: "var(--color-foreground)",
          }}
        />
        {/* 발송 버튼: 디자인 가이드 시스템의 .btn-sm 클래스를 확장하여 원형 구조로 커스텀 스타일링 */}
        <button
          onClick={handleSendMessage}
          className="btn-sm flex items-center justify-center"
          style={{
            width: "36px",
            height: "36px",
            padding: "0",
            borderRadius: "50%",
            backgroundColor: "var(--color-primary)",
          }}
        >
          {/* 종이비행기 전송 아이콘 아이콘(SVG) */}
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2}
            stroke="currentColor"
            className="w-4 h-4"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5"
            />
          </svg>
        </button>
      </div>
    </div>
  );
}

// -------------------------------------------------------------------------------
// [메인 페이지 컴포넌트 내보내기]
// Next.js useSearchParams 비동기 바인딩 시 발생할 수 있는 클라이언트 오류 방지를 위해
// Suspense 래퍼(Wrapper) 컴포넌트로 내부 비즈니스 로직을 감싸 안전하게 내보냄
// -------------------------------------------------------------------------------
export default function GuestChatRoomPage() {
  return (
    <Suspense
      fallback={
        <div
          className="flex h-screen items-center justify-center"
          style={{ color: "var(--color-text-muted)" }}
        >
          페이지 준비 중...
        </div>
      }
    >
      <GuestChatContent />
    </Suspense>
  );
}
