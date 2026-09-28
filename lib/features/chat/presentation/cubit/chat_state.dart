import 'package:equatable/equatable.dart';
import 'package:sakani/features/chat/domain/entities/chat_entities.dart';

class ChatState extends Equatable {
  final bool isLoadingRooms;
  final bool isLoadingMessages;
  final List<ChatRoomEntity> rooms;
  final List<ChatMessageEntity> activeMessages;
  final String? activeRoomId;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.isLoadingRooms = false,
    this.isLoadingMessages = false,
    this.rooms = const [],
    this.activeMessages = const [],
    this.activeRoomId,
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    bool? isLoadingRooms,
    bool? isLoadingMessages,
    List<ChatRoomEntity>? rooms,
    List<ChatMessageEntity>? activeMessages,
    String? activeRoomId,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      rooms: rooms ?? this.rooms,
      activeMessages: activeMessages ?? this.activeMessages,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingRooms,
        isLoadingMessages,
        rooms,
        activeMessages,
        activeRoomId,
        isSending,
        errorMessage,
      ];
}
