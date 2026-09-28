import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sakani/features/chat/data/models/chat_message.dart';
import 'package:sakani/features/chat/data/services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  StreamSubscription? _roomsSub;
  StreamSubscription? _messagesSub;

  List<ChatRoom> _rooms = [];
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatRoom> get rooms => _rooms;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void loadRooms(String userId) {
    _isLoading = true;
    notifyListeners();
    _roomsSub?.cancel();
    _roomsSub = _chatService
        .getChatRooms(userId)
        .listen(
          (rooms) {
            _rooms = rooms;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  void loadMessages(String roomId) {
    _messagesSub?.cancel();
    _messages = [];
    notifyListeners();
    _messagesSub = _chatService
        .getMessages(roomId)
        .listen(
          (msgs) {
            _messages = msgs;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _chatService.sendMessage(
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );
  }

  Future<ChatRoom> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
    return await _chatService.createRoom(
      apartmentId: apartmentId,
      apartmentTitle: apartmentTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      ownerId: ownerId,
      ownerName: ownerName,
    );
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _messagesSub?.cancel();
    super.dispose();
  }
}
