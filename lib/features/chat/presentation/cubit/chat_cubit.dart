import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/features/chat/domain/entities/chat_entities.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';
import 'package:sakani/features/chat/domain/usecases/create_room_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/get_chat_rooms_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/get_messages_usecase.dart';
import 'package:sakani/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:sakani/features/chat/presentation/cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetChatRoomsUseCase getChatRoomsUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final CreateRoomUseCase createRoomUseCase;
  final ChatRepository chatRepository;

  StreamSubscription<List<ChatRoomEntity>>? _roomsSub;
  StreamSubscription<List<ChatMessageEntity>>? _messagesSub;

  ChatCubit({
    required this.getChatRoomsUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.createRoomUseCase,
    required this.chatRepository,
  }) : super(const ChatState());

  void loadRooms(String userId) {
    if (userId.isEmpty) return;
    emit(state.copyWith(isLoadingRooms: true));
    _roomsSub?.cancel();
    _roomsSub = getChatRoomsUseCase(userId).listen((rooms) {
      emit(state.copyWith(isLoadingRooms: false, rooms: rooms));
    });
  }

  void openRoom(String roomId) {
    emit(state.copyWith(isLoadingMessages: true, activeRoomId: roomId));
    _messagesSub?.cancel();
    _messagesSub = getMessagesUseCase(roomId).listen((messages) {
      emit(state.copyWith(isLoadingMessages: false, activeMessages: messages));
    });
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    emit(state.copyWith(isSending: true));
    final result = await sendMessageUseCase(SendMessageParams(
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
    ));

    result.fold(
      (failure) => emit(state.copyWith(isSending: false, errorMessage: failure.message)),
      (_) => emit(state.copyWith(isSending: false)),
    );
  }

  Future<ChatRoomEntity?> createOrGetRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
    final result = await createRoomUseCase(CreateRoomParams(
      apartmentId: apartmentId,
      apartmentTitle: apartmentTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      ownerId: ownerId,
      ownerName: ownerName,
    ));

    return result.dataOrNull;
  }

  @override
  Future<void> close() {
    _roomsSub?.cancel();
    _messagesSub?.cancel();
    return super.close();
  }
}
