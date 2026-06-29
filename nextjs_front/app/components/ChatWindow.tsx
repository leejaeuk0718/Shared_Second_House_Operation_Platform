"use client";

import { useEffect, useRef, useState } from "react";
import styles from "./ChatWindow.module.css";
import { api } from "@/lib/api";

interface ChatBotSource {
  id: string;
  question: string;
}

interface ChatMessage {
  text: string;
  isMe: boolean; // true = 내 질문, false = 봇 답변
  sources?: ChatBotSource[];
}

export const STORAGE_KEY = "chatbot_messages";
const WELCOME: ChatMessage = {
  text: "안녕하세요! 세컨하우스 운영 FAQ 챗봇입니다. 궁금한 점을 물어보세요. 🙂",
  isMe: false,
};

export default function ChatWindow({ onClose }: { onClose?: () => void }) {
  // 1. 단순하게 메시지 상태 관리 (세션 복원은 클라이언트 마운트 후 처리)
  // const [messages, setMessages] = useState<ChatMessage[]>([WELCOME]);
  const [messages, setMessages] = useState<ChatMessage[]>(() => {
    // 빌드 타임이나 서버 사이드 렌더링(SSR) 중에는 window가 없으므로 환영 메시지 리턴
    if (typeof window === "undefined") return [WELCOME];

    const saved = sessionStorage.getItem(STORAGE_KEY);
    if (!saved) return [WELCOME];

    try {
      return JSON.parse(saved) as ChatMessage[];
    } catch {
      return [WELCOME]; // 파싱 에러 나면 안전하게 기본값으로
    }
  });
  const [input, setInput] = useState("");
  const [isSending, setIsSending] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);

  // 3. 메시지가 바뀔 때마다 세션 저장 + 맨 아래로 스크롤
  useEffect(() => {
    if (messages.length > 1) {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(messages));
    }
    listRef.current?.scrollTo({
      top: listRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages]);

  // 🚀 질문 전송 함수
  const handleSend = async () => {
    const q = input.trim();
    if (!q || isSending) return;

    setInput(""); // 입력창 먼저 비우기
    setIsSending(true);

    // 내 질문 화면에 추가
    const updatedMessages = [...messages, { text: q, isMe: true }];
    setMessages(updatedMessages);

    try {
      // api.get 이 accessToken 을 Authorization: Bearer 로 자동 첨부 (JWT 인증)
      const data = await api.get<{ answer: string; sources?: ChatBotSource[] }>(
        `/api/chatBot/chat?q=${encodeURIComponent(q)}&topK=3`,
      );
      setMessages([
        ...updatedMessages,
        { text: data.answer, isMe: false, sources: data.sources },
      ]);
    } catch {
      setMessages([
        ...updatedMessages,
        { text: "답변을 가져오지 못했어요. 😢", isMe: false },
      ]);
    } finally {
      setIsSending(false);
    }
  };

  return (
    <div className={styles.chat}>
      {/* AppBar 헤더 */}
      <header className={styles.appBar}>
        AI 챗봇
        {onClose && (
          <button type="button" className={styles.closeBtn} onClick={onClose}>
            ✕
          </button>
        )}
      </header>

      {/* 💬 메시지 리스트 */}
      <div className={styles.list} ref={listRef}>
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`${styles.row} ${msg.isMe ? styles.rowMe : styles.rowBot}`}
          >
            {!msg.isMe && <div className={styles.avatar}>🤖</div>}

            <div className={styles.bubbleColumn}>
              <div
                className={`${styles.bubble} ${msg.isMe ? styles.bubbleMe : styles.bubbleBot}`}
              >
                {msg.text}
              </div>

              {/* 📚 참고한 FAQ (봇 답변이면서 sources가 있을 때만) */}
              {!msg.isMe && msg.sources && msg.sources.length > 0 && (
                <div className={styles.sources}>
                  <span className={styles.sourcesTitle}>📚 참고한 FAQ</span>
                  <div className={styles.chips}>
                    {msg.sources.map((s) => (
                      <span key={s.id} className={styles.chip}>
                        {s.question}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}

        {/* ⏳ 답변 로딩 중 */}
        {isSending && (
          <div className={`${styles.row} ${styles.rowBot}`}>
            <div className={styles.avatar}>🤖</div>
            <div className={`${styles.bubble} ${styles.bubbleBot}`}>
              <span className={styles.spinner} />
            </div>
          </div>
        )}
      </div>

      {/* ⌨️ 하단 입력창 */}
      <div className={styles.inputBar}>
        <input
          className={styles.input}
          value={input}
          disabled={isSending}
          placeholder="궁금한 점을 입력하세요..."
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && handleSend()}
        />
        <button
          className={styles.sendBtn}
          disabled={isSending || !input.trim()}
          onClick={handleSend}
        >
          ➤
        </button>
      </div>
    </div>
  );
}
