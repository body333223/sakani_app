import 'package:sakani/features/chat/domain/entities/chat_entities.dart';

class ChatMessageModel extends ChatMessageEntity {
  ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    super.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory ChatMessageModel.fromEntity(ChatMessageEntity entity) {
    return ChatMessageModel(
      id: entity.id,
      senderId: entity.senderId,
      senderName: entity.senderName,
      text: entity.text,
      timestamp: entity.timestamp,
    );
  }
}

class ChatRoomModel extends ChatRoomEntity {
  ChatRoomModel({
    required super.id,
    required super.apartmentId,
    required super.apartmentTitle,
    required super.tenantId,
    required super.tenantName,
    required super.ownerId,
    required super.ownerName,
    super.lastMessage,
    super.lastTimestamp,
    super.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'apartmentTitle': apartmentTitle,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'lastMessage': lastMessage,
      'lastTimestamp': lastTimestamp?.toIso8601String(),
      'participants': participants,
    };
  }

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      apartmentId: map['apartmentId'] ?? '',
      apartmentTitle: map['apartmentTitle'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      lastMessage: map['lastMessage'],
      lastTimestamp: map['lastTimestamp'] != null
          ? DateTime.tryParse(map['lastTimestamp'])
          : null,
      participants: map['participants'] != null
          ? List<String>.from(map['participants'])
          : [map['tenantId'] ?? '', map['ownerId'] ?? ''],
    );
  }

  factory ChatRoomModel.fromEntity(ChatRoomEntity entity) {
    return ChatRoomModel(
      id: entity.id,
      apartmentId: entity.apartmentId,
      apartmentTitle: entity.apartmentTitle,
      tenantId: entity.tenantId,
      tenantName: entity.tenantName,
      ownerId: entity.ownerId,
      ownerName: entity.ownerName,
      lastMessage: entity.lastMessage,
      lastTimestamp: entity.lastTimestamp,
      participants: entity.participants,
    );
  }
}

/// Backwards compatibility aliases
typedef ChatMessage = ChatMessageModel;
typedef ChatRoom = ChatRoomModel;
