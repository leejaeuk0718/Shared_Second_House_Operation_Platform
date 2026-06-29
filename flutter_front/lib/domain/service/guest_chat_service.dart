import 'dart:convert';
import 'dart:developer' as developer;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuestChatService {
  StompClient? _stompClient;
  bool _isConnected = false;

  static const String _ipAddress = '10.0.2.2:8080';
  final String _wsUrl = 'ws://$_ipAddress/ws-guest-chat';
  final String _baseUrl = 'http://$_ipAddress/api/guest/chat';
  final _storage = const FlutterSecureStorage();

  bool get isConnected => _isConnected;

  /// 토큰 저장소 연동용 메서드 (JWT 복구 지점)
  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'accessToken');
  }

  /// HTTP 및 STOMP 통신을 위한 공통 헤더 생성 규칙
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// 유저가 선택한 숙소(House) ID를 기반으로 매핑된 채팅방 번호 조회 (GET 방식)
  Future<int?> getOrCreateRoom({
    required int accommodationId, // 백엔드의 {houseId}와 매핑됩니다.
  }) async {
    // 🟩 [수정 완] POST -> GET 방식 변환 및 경로변수(PathVariable) 주소 매핑 반영
    final url = Uri.parse('$_baseUrl/room/$accommodationId');
    final headers = await _getHeaders();

    try {
      // 🟩 [수정 완] http.post 대신 http.get 사용
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        // 백엔드가 반환하는 GuestChatRoom 엔티티 객체 구조에서 ID 추출
        if (decoded is Map<String, dynamic>) {
          // 객체 내부의 고유 ID 필드명(id 또는 chatRoomId)에 맞추어 리턴
          return decoded['id'] ?? decoded['chatRoomId'];
        } else if (decoded is int) {
          return decoded;
        }
      }
      developer.log('채팅방 매핑 실패 (코드: ${response.statusCode})', name: 'ChatService');
      return null;
    } catch (e) {
      developer.log('채팅방 생성 중 네트워크 예외 발생', error: e, name: 'ChatService');
      return null;
    }
  }

  /// 특정 채팅방의 과거 대화 내역 조회
  Future<List<Map<String, dynamic>>> getChatHistory(int chatRoomId) async {
    final url = Uri.parse('$_baseUrl/history/$chatRoomId');
    final headers = await _getHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes));
        return decodedData.map((item) => item as Map<String, dynamic>).toList();
      }
      developer.log('서버 에러 (코드: ${response.statusCode})', name: 'ChatService');
      return [];
    } catch (e) {
      developer.log('과거 내역 조회 중 네트워크 예외 발생', error: e, name: 'ChatService');
      return [];
    }
  }

  /// 웹소켓 서버 초기화 및 채널 연결
  void connectWebSocket({
    required int chatRoomId,
    required Function(Map<String, dynamic>) onMessageReceived,
  }) async {
    if (_stompClient != null && _isConnected) return;

    final headers = await _getHeaders();
    // STOMP용 headers에는 Content-Type이 필요하지 않을 수 있으므로 Authorization만 안전하게 추출
    final Map<String, String> stompHeaders = {};
    if (headers.containsKey('Authorization')) {
      stompHeaders['Authorization'] = headers['Authorization']!;
    }

    _stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        stompConnectHeaders: stompHeaders,
        onConnect: (StompFrame frame) {
          _isConnected = true;
          developer.log('WebSocket 연결 성공', name: 'ChatService');
          _subscribeRoom(chatRoomId, onMessageReceived);
        },
        onDisconnect: (StompFrame frame) {
          _isConnected = false;
          developer.log('WebSocket 연결 끊김', name: 'ChatService');
        },
        onStompError: (StompFrame frame) {
          developer.log('STOMP 에러 발생: ${frame.body}', name: 'ChatService');
        },
        onWebSocketError: (error) {
          developer.log('웹소켓 통신 에러', error: error, name: 'ChatService');
        },
      ),
    );

    _stompClient?.activate();
  }

  /// 특정 채팅방 실시간 구독 구독 (하행선)
  void _subscribeRoom(int chatRoomId, Function(Map<String, dynamic>) onMessageReceived) {
    _stompClient?.subscribe(
      destination: '/topic/guest/room/$chatRoomId',
      callback: (StompFrame frame) {
        if (frame.body != null) {
          final Map<String, dynamic> messageData = jsonDecode(frame.body!);
          onMessageReceived(messageData);
        }
      },
    );
    developer.log('구독 완료 -> /topic/guest/room/$chatRoomId', name: 'ChatService');
  }

  /// 실시간 메시지 발송 (상행선)
  void sendMessage({
    required int chatRoomId,
    required int senderId,
    required String senderName,
    required String content,
  }) {
    if (_stompClient == null || !_isConnected) {
      developer.log('메시지 전송 실패: 서버와 연결되어 있지 않습니다.', name: 'ChatService');
      return;
    }

    final Map<String, dynamic> chatDto = {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
    };

    _stompClient?.send(
      destination: '/app/guest/chat/send',
      body: jsonEncode(chatDto),
      headers: {'content-type': 'application/json'},
    );
    developer.log('메시지 발신 완료: $content', name: 'ChatService');
  }

  /// 웹소켓 세션 안전 종료
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
    _isConnected = false;
    developer.log('WebSocket 연결 해제 완료', name: 'ChatService');
  }
}