import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/services/support_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  static const Color emeraldColor = Color(0xFF10B981);
  static const Color emeraldDark = Color(0xFF059669);

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  SupportTicketModel? _activeTicket;
  List<SupportMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  // New ticket state
  String _selectedSubject = 'استفسار عن حجز وإيجار شقة';
  final TextEditingController _newTicketMsgController = TextEditingController();

  final List<String> _quickSubjects = [
    'استفسار عن حجز وإيجار شقة',
    'مشكلة في توثيق الهوية KYC',
    'استفسار عن استرداد التأمين أو الدفع',
    'شكوى أو إبلاغ عن عقار',
    'طلب مساعدة عامة من خدمة العملاء',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    // Live polling every 3.5 seconds
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (_activeTicket != null && mounted) {
        _refreshMessagesSilently();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _msgController.dispose();
    _newTicketMsgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final user = AuthService.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userTickets = await SupportService.getUserTickets(user.uid);
      if (userTickets.isNotEmpty) {
        // Find open or latest ticket
        final openTicket = userTickets.firstWhere(
          (t) => t.status == 'open' || t.status == 'in_progress',
          orElse: () => userTickets.first,
        );
        _activeTicket = openTicket;
        final msgs = await SupportService.getTicketMessages(openTicket.id);
        _messages = msgs;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _refreshMessagesSilently() async {
    if (_activeTicket == null) return;
    try {
      final msgs = await SupportService.getTicketMessages(_activeTicket!.id);
      if (msgs.length != _messages.length && mounted) {
        setState(() {
          _messages = msgs;
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startNewTicket() async {
    final text = _newTicketMsgController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة رسالتك أو استفسارك للبدء')),
      );
      return;
    }

    final user = AuthService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final ticket = await SupportService.createTicket(
      userId: user.uid,
      userName: user.name.isNotEmpty ? user.name : 'مستخدم سكني',
      userEmail: user.email,
      userPhone: user.phone,
      subject: _selectedSubject,
      initialMessage: text,
    );

    if (ticket != null) {
      _activeTicket = ticket;
      final msgs = await SupportService.getTicketMessages(ticket.id);
      _messages = msgs;
      _newTicketMsgController.clear();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تذكرة الدعم، يرجى التحقق من الاتصال')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _activeTicket == null || _isSending) return;

    final user = AuthService.currentUser;
    final senderId = user?.uid ?? 'user';
    final senderName = user?.name ?? 'المستخدم';

    _msgController.clear();
    setState(() => _isSending = true);

    // Optimistic UI update
    final tempMsg = SupportMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      ticketId: _activeTicket!.id,
      senderId: senderId,
      senderName: senderName,
      senderRole: 'customer',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMsg);
    });
    _scrollToBottom();

    final sent = await SupportService.sendMessage(
      ticketId: _activeTicket!.id,
      senderId: senderId,
      senderName: senderName,
      text: text,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (sent != null) {
        final idx = _messages.indexWhere((m) => m.id == tempMsg.id);
        if (idx != -1) {
          _messages[idx] = sent;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'الدعم الفني المباشر',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.verified_user_rounded, color: emeraldColor, size: 16),
              ],
            ),
            Text(
              _activeTicket != null
                  ? (_activeTicket!.assignedAgentName ?? 'جاري التوصيل بموظف الشيفت...')
                  : 'متاح على مدار 24 ساعة لخدمتك',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'AES-256',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          if (_activeTicket != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'تذكرة جديدة',
              onPressed: () {
                setState(() {
                  _activeTicket = null;
                  _messages = [];
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeTicket == null
              ? _buildNewTicketView(isDark)
              : _buildActiveChatView(isDark),
    );
  }

  Widget _buildNewTicketView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF047857), const Color(0xFF065F46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text(
                  'مرحباً بك في مركز دعم سكني',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'تواصل مباشرة مع موظفي خدمة العملاء والمشرفين. يتم توجيه رسالتك تلقائياً للموظف النشط في هذا الشيفت.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'موضوع الاستفسار:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSubject,
                isExpanded: true,
                items: _quickSubjects.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSubject = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'تفاصيل رسالتك أو استفسارك:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _newTicketMsgController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب ما تود الاستفسار عنه بالتفصيل لمساعدتك بأسرع شكل...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: emeraldColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _startNewTicket,
            style: ElevatedButton.styleFrom(
              backgroundColor: emeraldDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              'بدء المحادثة المباشرة الآن',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveChatView(bool isDark) {
    return Column(
      children: [
        // Ticket banner info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _activeTicket!.status == 'resolved' ? Colors.green : emeraldDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _activeTicket!.status == 'resolved' ? 'تم الحل' : 'جاري المتابعة',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _activeTicket!.subject,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'شيفت ${_activeTicket!.shift == 'morning' ? 'صباحي' : (_activeTicket!.shift == 'evening' ? 'مسائي' : 'ليلي')}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'لا توجد رسائل سابقة في هذه التذكرة',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageBubble(msg, isDark);
                  },
                ),
        ),

        // Message input bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'اكتب ردك أو استفسارك هنا...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: emeraldDark),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(SupportMessageModel msg, bool isDark) {
    final isCustomer = !msg.isFromAgent;

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCustomer
              ? emeraldDark
              : (isDark ? const Color(0xFF334155) : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isCustomer ? 16 : 4),
            bottomRight: Radius.circular(isCustomer ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCustomer ? 'أنت' : (msg.senderName.isNotEmpty ? msg.senderName : 'خدمة العملاء'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCustomer
                        ? Colors.white.withValues(alpha: 0.9)
                        : (isDark ? Colors.tealAccent : const Color(0xFF047857)),
                  ),
                ),
                if (!isCustomer) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.headset_mic, size: 12, color: emeraldColor),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                color: isCustomer ? Colors.white : (isDark ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 9,
                color: isCustomer ? Colors.white.withValues(alpha: 0.7) : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
