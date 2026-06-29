import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_front/domain/controller/chat_bot_controller.dart';
import 'package:flutter_front/domain/dto/chat_bot_answer_dto.dart';
import 'package:flutter_front/common/constants/app_colors.dart';

/// 🤖 Gemini RAG 기반 QnA 챗봇 화면
/// 상태(대화 내역·전송중)는 ChatBotController(Provider)가 관리해, 화면을 나갔다
/// 들어와도 대화가 유지된다. 통신은 웹소켓 없이 HTTP 단발성 요청/응답.
class GuestChatBotScreen extends StatefulWidget {
  const GuestChatBotScreen({super.key});

  @override
  State<GuestChatBotScreen> createState() => _GuestChatBotScreenState();
}

class _GuestChatBotScreenState extends State<GuestChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 🎨 React 챗봇과 동일한 테마 (Next.js globals.css 토큰 = AppColors)
  static const Color primaryColor = AppColors.primary;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 🚀 질문 전송 (컨트롤러에 위임)
  void _handleSend() {
    final text = _messageController.text.trim();
    final controller = context.read<ChatBotController>();
    if (text.isEmpty || controller.isSending) return;

    _messageController.clear();
    controller.send(text); // 비동기 — 완료 시 컨트롤러가 notifyListeners
    _scrollToBottom();
  }

  /// 📜 리스트를 맨 아래로 부드럽게 스크롤
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 구독 → 메시지/전송상태 변화 시 자동 리빌드
    final controller = context.watch<ChatBotController>();
    final messages = controller.messages;
    final isSending = controller.isSending;

    // 새 메시지가 렌더된 뒤 맨 아래로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppBar(
        title: const Text(
          'AI 챗봇',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 💬 메시지 리스트 영역 (마지막에 로딩 버블 한 칸 추가)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + (isSending ? 1 : 0),
              itemBuilder: (context, index) {
                // 마지막 칸이면 "답변 작성 중" 로딩 버블
                if (isSending && index == messages.length) {
                  return _buildTypingBubble();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),

          // ⌨️ 하단 입력창 영역
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isSending,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '궁금한 점을 입력하세요...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: isSending ? AppColors.textSecondary : primaryColor,
                    ),
                    onPressed: isSending ? null : _handleSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 💬 메시지 버블 1개 (질문/답변 공용)
  Widget _buildMessageBubble(ChatMessage msg) {
    final bool isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor,
              child: Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primaryLight : AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft:
                          isMe ? const Radius.circular(12) : const Radius.circular(2),
                      bottomRight:
                          isMe ? const Radius.circular(2) : const Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      )
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary, height: 1.4),
                  ),
                ),
                // 📚 봇 답변의 근거 FAQ를 칩으로 표시 (있을 때만)
                if (!isMe && msg.sources.isNotEmpty) _buildSources(msg.sources),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📚 답변 근거 FAQ 목록 (참고용)
  Widget _buildSources(List<ChatBotSourceDto> sources) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 참고한 FAQ',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sources
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.question,
                        style: const TextStyle(fontSize: 11, color: primaryColor),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// ⏳ 답변 작성 중 로딩 버블
  Widget _buildTypingBubble() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor,
            child: Text('🤖', style: TextStyle(fontSize: 18)),
          ),
          SizedBox(width: 8),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}