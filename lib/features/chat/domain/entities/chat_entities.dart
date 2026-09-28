import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;

  ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [id, senderId, senderName, text, timestamp];
}

class ChatRoomEntity extends Equatable {
  final String id;
  final String apartmentId;
  final String apartmentTitle;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String ownerName;
  final String? lastMessage;
  final DateTime? lastTimestamp;
  final List<String> participants;

  ChatRoomEntity({
    required this.id,
    required this.apartmentId,
    required this.apartmentTitle,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.ownerName,
    this.lastMessage,
    this.lastTimestamp,
    List<String>? participants,
  }) : participants = participants ?? [tenantId, ownerId];

  @override
  List<Object?> get props => [
        id,
        apartmentId,
        apartmentTitle,
        tenantId,
        tenantName,
        ownerId,
        ownerName,
        lastMessage,
        lastTimestamp,
        participants,
      ];
}
