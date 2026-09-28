import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sakani/core/config/api_config.dart';
import 'package:sakani/features/chat/data/models/chat_message.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatRoomModel>> getChatRooms(String userId);
  Future<List<ChatMessageModel>> getMessages(String roomId);
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });
  Future<ChatRoomModel> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  });
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client client;

  ChatRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    try {
      final response = await client
          .get(Uri.parse(ApiConfig.userRooms(userId)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => ChatRoomModel.fromMap(item, item['id'] ?? '')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String roomId) async {
    try {
      final response = await client
          .get(Uri.parse(ApiConfig.roomMessages(roomId)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => ChatMessageModel.fromMap(item, item['id'] ?? '')).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      await client
          .post(
            Uri.parse(ApiConfig.sendMessage(roomId)),
            headers: ApiConfig.authHeaders,
            body: jsonEncode({
              'roomId': roomId,
              'senderId': senderId,
              'senderName': senderName,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  @override
  Future<ChatRoomModel> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConfig.createRoom),
            headers: ApiConfig.authHeaders,
            body: jsonEncode({
              'apartmentId': apartmentId,
              'apartmentTitle': apartmentTitle,
              'tenantId': tenantId,
              'tenantName': tenantName,
              'ownerId': ownerId,
              'ownerName': ownerName,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatRoomModel.fromMap(data, data['id'] ?? '');
      }
    } catch (_) {}

    return ChatRoomModel(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
      apartmentId: apartmentId,
      apartmentTitle: apartmentTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      ownerId: ownerId,
      ownerName: ownerName,
      participants: [tenantId, ownerId],
      lastMessage: '',
      lastTimestamp: DateTime.now(),
    );
  }
}
