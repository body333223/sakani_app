import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/chat/data/models/chat_message.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/chat/presentation/providers/chat_provider.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/loading_widget.dart';
import 'package:sakani/features/chat/presentation/screens/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final bool isEmbedded;
  const ChatListScreen({super.key, this.isEmbedded = false});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid;
      if (userId != null && mounted) {
        context.read<ChatProvider>().loadRooms(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Consumer<ChatProvider>(
      builder: (context, chat, _) {
        if (chat.isLoading) {
          return const LoadingWidget();
        }
        if (chat.rooms.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'لا توجد محادثات',
            subtitle: 'ابدأ محادثة مع مالك شقة',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: chat.rooms.length,
          itemBuilder: (context, index) {
            final room = chat.rooms[index];
            return _ChatRoomCard(
              room: room,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
                );
              },
            );
          },
        );
      },
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: bodyContent,
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;

  const _ChatRoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isOwner = auth.user?.uid == room.ownerId;
    final otherName = isOwner ? room.tenantName : room.ownerName;
    final initial = otherName.isNotEmpty ? otherName[0] : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StyledCard(
        onTap: onTap,
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.accentColor.withValues(alpha: 0.2),
                    context.accentColor.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: context.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: context.accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.apartmentTitle,
                    style: TextStyle(
                      color: context.accentColor.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  if (room.lastMessage != null &&
                      room.lastMessage!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      room.lastMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              color: context.accentColor.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
