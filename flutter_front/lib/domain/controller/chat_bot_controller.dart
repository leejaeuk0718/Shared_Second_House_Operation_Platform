import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_front/domain/dto/chat_bot_answer_dto.dart';
import 'package:flutter_front/domain/service/chat_bot_service.dart';

/// 💬 화면에 뿌릴 챗봇 메시지 1건 (사용자 질문 / 봇 답변 공용)
class ChatMessage {
  final String text;
  final bool isMe; // true=내 질문, false=봇 답변
  final List<ChatBotSourceDto> sources; // 봇 답변의 근거 FAQ

  ChatMessage({required this.text, required this.isMe, this.sources = const []});
}

/// 🤖 챗봇 상태 관리 컨트롤러 (ChangeNotifier)
/// 대화 내역을 보관해, 화면을 나갔다 다시 들어와도 대화가 유지된다.
class ChatBotController extends ChangeNotifier {
  final ChatBotService _chatBotService = ChatBotService();

  final List<ChatMessage> _messages = [];
  bool _isSending = false; // 답변 대기 중 (중복 전송 방지 + 로딩 표시)

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  ChatBotController() {
    // 최초 1회 환영 인사
    _messages.add(_welcomeMessage());
  }

  ChatMessage _welcomeMessage() => ChatMessage(
        text: '안녕하세요! 세컨하우스 운영 FAQ 챗봇입니다. 궁금한 점을 물어보세요. 🙂',
        isMe: false,
      );

  /// 대화 내역을 비우고 환영 인사만 남긴다.
  /// 로그아웃/재로그인 시 이전 사용자의 대화가 남지 않도록 호출한다.
  /// (대화는 메모리에만 보관되므로 이 리스트만 비우면 된다.)
  void clear() {
    _messages
      ..clear()
      ..add(_welcomeMessage());
    notifyListeners();
  }

  /// 질문 전송 → 백엔드 RAG 답변 수신
  Future<void> send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _isSending) return;

    _messages.add(ChatMessage(text: q, isMe: true)); // 내 질문 버블
    _isSending = true;
    notifyListeners();

    try {
      final ChatBotAnswerDto result = await _chatBotService.ask(q);
      _messages.add(ChatMessage(
        text: result.answer,
        isMe: false,
        sources: result.sources,
      ));
    } on DioException catch (e) {
      debugPrint('🔴 [챗봇 컨트롤러] 통신 실패: ${e.message}');
      _messages.add(ChatMessage(
        text: '답변을 가져오지 못했어요. 잠시 후 다시 시도해 주세요. 😢',
        isMe: false,
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}