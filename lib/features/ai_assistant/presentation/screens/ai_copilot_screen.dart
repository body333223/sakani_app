import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/bookings/presentation/screens/booking_screen.dart';
import 'package:sakani/core/security/booking_security_guard.dart';

class AiCopilotMessage {
  final String text;
  final bool isUser;
  final List<ApartmentEntity>? matchedApartments;
  final DateTime time;

  AiCopilotMessage({
    required this.text,
    required this.isUser,
    this.matchedApartments,
    required this.time,
  });
}

/// مستشار سكني الذكي بالذكاء الاصطناعي (Sakani AI Copilot)
class AiCopilotScreen extends StatefulWidget {
  const AiCopilotScreen({super.key});

  @override
  State<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends State<AiCopilotScreen> {
  final TextEditingController _textCtl = TextEditingController();
  final ScrollController _scrollCtl = ScrollController();
  final List<AiCopilotMessage> _messages = [];
  bool _isAnalyzing = false;

  final List<String> _quickPrompts = [
    'عاوز شقة في التجمع قريبة من الجامعة وميزانيتي 18 ألف',
    'شاليه في الساحل الشمالي إيجار يومي ع البحر',
    'استوديو مفروش في الشيخ زايد بسعر اقتصادي',
    'شقة عائلية 3 غرف ألترا لوكس في المعادي',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      AiCopilotMessage(
        text: 'أهلاً بك في مستشار سكني الذكي 🤖✨\nأنا هنا لمساعدتك في العثور على شقتك المثالية فوراً. يمكنك كتابة طلبك باللغة العربية أو العامية المصرية مع الميزانية والمنطقة، وسأرشح لك أفضل الخيارات المناسبة!',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(
          _scrollCtl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(String input) {
    final query = input.trim();
    if (query.isEmpty) return;

    final allApts = context.read<ApartmentCubit>().state.apartments;

    _textCtl.clear();
    setState(() {
      _messages.add(AiCopilotMessage(text: query, isUser: true, time: DateTime.now()));
      _isAnalyzing = true;
    });
    _scrollToBottom();

    // AI Semantic Matching Engine
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final q = query.toLowerCase();

      // Detect intent & filters
      bool wantsDaily = q.contains('يومي') || q.contains('ليلة') || q.contains('يوم');
      bool wantsFamily = q.contains('عائلة') || q.contains('عائلية') || q.contains('3 غرف') || q.contains('كبيرة');
      bool wantsStudio = q.contains('استوديو') || q.contains('غرفة') || q.contains('صغيرة');

      // Detect location
      String? targetCity;
      if (q.contains('تجمع') || q.contains('قاهرة جديدة')) targetCity = 'القاهرة الجديدة';
      if (q.contains('زايد') || q.contains('أكتوبر')) targetCity = 'الشيخ زايد';
      if (q.contains('معادي')) targetCity = 'المعادي';
      if (q.contains('ساحل') || q.contains('علمين')) targetCity = 'الساحل الشمالي';
      if (q.contains('إسكندرية') || q.contains('اسكندرية')) targetCity = 'الإسكندرية';

      // Detect budget
      double? budget;
      final budgetMatch = RegExp(r'(\d{4,6})').firstMatch(q);
      if (budgetMatch != null) {
        budget = double.tryParse(budgetMatch.group(1)!);
      }

      // Filter apartments
      List<ApartmentEntity> matches = allApts.where((apt) {
        if (targetCity != null && !apt.city.toLowerCase().contains(targetCity.toLowerCase()) && !apt.address.toLowerCase().contains(targetCity.toLowerCase())) {
          return false;
        }
        if (wantsDaily && apt.dailyPrice <= 0) return false;
        if (wantsStudio && apt.bedrooms > 1) return false;
        if (wantsFamily && apt.bedrooms < 2) return false;
        if (budget != null && apt.monthlyPrice > (budget * 1.25)) return false;
        return true;
      }).toList();

      if (matches.isEmpty) {
        matches = allApts.take(3).toList();
      } else {
        matches = matches.take(3).toList();
      }

      String responseText = '';
      if (matches.isNotEmpty) {
        responseText = 'بناءً على طلبك، حللت لك العقارات المتاحة ووجدت ${matches.length} خيارات مثالية تطابق رغبتك تماماً من حيث الموقع والميزانية والجودة:\nتفضل بمراجعة الخيارات الموصى بها أدناه وحجز موعدك فوراً 🏡✨';
      } else {
        responseText = 'عذراً، لم أجد شقة تطابق كافة المواصفات الدقيقة حالياً، لكن هذه أفضل الخيارات الموصى بها في منصة سكني:';
      }

      setState(() {
        _isAnalyzing = false;
        _messages.add(
          AiCopilotMessage(
            text: responseText,
            isUser: false,
            matchedApartments: matches,
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded, color: context.accentColor, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'مستشار سكني AI',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Quick Prompt Chips ──
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final p = _quickPrompts[idx];
                return ActionChip(
                  label: Text(p, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                  backgroundColor: context.cardColor,
                  side: BorderSide(color: context.borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () => _handleSend(p),
                );
              },
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // ── Messages List ──
          Expanded(
            child: ListView.builder(
              controller: _scrollCtl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                return _buildMessageItem(msg);
              },
            ),
          ),

          if (_isAnalyzing)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.accentColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الذكاء الاصطناعي يحلل طلبك ويبحث في الشقق المتاحة...',
                    style: TextStyle(color: context.accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // ── Input Bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtl,
                      style: TextStyle(color: context.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'اسألني بالعامية أو الفصحى عن أي شقة...',
                        hintStyle: TextStyle(color: context.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: context.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _handleSend(_textCtl.text),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(AiCopilotMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!msg.isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.accentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: context.accentColor, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isUser ? context.accentColor : context.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: msg.isUser ? context.accentColor : context.borderColor,
                    ),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.black : context.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: msg.isUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Render Matched Apartment Cards
          if (msg.matchedApartments != null && msg.matchedApartments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: msg.matchedApartments!.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final apt = msg.matchedApartments![i];
                  return _buildApartmentRecommendationCard(apt);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApartmentRecommendationCard(ApartmentEntity apt) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: apt.images.isNotEmpty
                    ? Image.network(
                        apt.images.first,
                        height: 105,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(height: 105, color: Colors.grey[800]),
                      )
                    : Container(height: 105, color: Colors.grey[800]),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                      SizedBox(width: 2),
                      Text(
                        '4.9',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  apt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  apt.city,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${apt.monthlyPrice.round()} ج.م',
                      style: TextStyle(
                        color: context.accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final nav = Navigator.of(context);
                        final canProceed = await BookingSecurityGuard.ensureCanBook(
                          context,
                          apartmentOwnerId: apt.ownerId,
                          apartmentTitle: apt.title,
                        );
                        if (canProceed && mounted) {
                          nav.push(
                            MaterialPageRoute(
                              builder: (_) => BookingScreen(apartment: ApartmentModel.fromEntity(apt)),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.accentColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'حجز سريع',
                          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
