import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_front/common/constants/app_colors.dart'; // 🟩 공통 컬러 임포트 경로 확인
import 'package:flutter_front/domain/service/guest_chat_service.dart';

class GuestChatScreen extends StatefulWidget {
  final int chatRoomId;
  final int currentUserId;
  final String currentUserName;

  const GuestChatScreen({
    super.key,
    required this.chatRoomId,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  State<GuestChatScreen> createState() => _GuestChatScreenState();
}

class _GuestChatScreenState extends State<GuestChatScreen> {
  final GuestChatService _chatService = GuestChatService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChatRoomSequence();
  }

  Future<void> _initChatRoomSequence() async {
    try {
      List<Map<String, dynamic>> history = await _chatService.getChatHistory(widget.chatRoomId);

      if (mounted) {
        setState(() {
          _messages.addAll(history);
          _isLoading = false;
        });
        _scrollToBottom();
      }

      _chatService.connectWebSocket(
        chatRoomId: widget.chatRoomId,
        onMessageReceived: (Map<String, dynamic> incomingMessage) {
          if (!mounted) return;

          setState(() {
            _messages.add(incomingMessage);
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방을 불러오는 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _chatService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(
      chatRoomId: widget.chatRoomId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      content: text,
    );

    _messageController.clear();
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      DateTime dateTime = DateTime.parse(isoString);
      return DateFormat('a h:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.chatRoomId}번 채팅방',
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];

                final String myId = widget.currentUserId.toString();
                final String senderId = (chat['senderId'] ?? chat['sender_id'] ?? '').toString();
                final bool isMe = (myId == senderId);

                final String messageContent = chat['content'] ?? chat['messageContent'] ?? '내용 없음';
                final String senderName = chat['senderName'] ?? '게스트';

                final String rawTime = chat['sentAt'] ?? chat['sent_at'] ?? '';
                final String formattedTime = _formatTime(rawTime);

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          radius: 18,
                          // 🟩 [서식 반영] 상대방 프로필 아바타를 포레스트 그린 소프트 톤으로 유연하게 매칭
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primary, size: 18),
                        ),
                        const SizedBox(width: 8),
                      ],

                      if (isMe && formattedTime.isNotEmpty) ...[
                        Text(formattedTime, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), // TextStyle 앞에 const 가능
                        const SizedBox(width: 6),
                      ],

                      GestureDetector(
                        onLongPress: null,
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                senderName,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.55,
                              ),
                              decoration: BoxDecoration(
                                // 🟩 [서식 반영] 내가 보낸 말풍선은 연한 그린(surfaceVariant 계열), 상대방은 깨끗한 흰색(surface) 지정
                                color: isMe ? AppColors.border : AppColors.border,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(2),
                                  bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  )
                                ],
                              ),
                              child: Text(
                                messageContent,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isMe && formattedTime.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        // 🟩 Text 앞의 const를 제거하고, 변하지 않는 TextStyle 앞에 const를 붙여줍니다.
                        Text(formattedTime, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // 🟩 하단 메시지 입력 섹션
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight, // 공통 흰색 바탕
                border: const Border(
                  top: BorderSide(color: AppColors.border, width: 0.5), // 세련된 한 줄 분할선
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        hintStyle: TextStyle(color: AppColors.textHint),
                        // 🟩 하단 바 내부 폼은 불필요한 Outline 외곽선을 걷어내고 플랫한 디자인 톤 유지
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 🟩 [서식 반영] 전송 아이콘 버튼 색상을 주 메인 색상인 포레스트 그린으로 교체
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}