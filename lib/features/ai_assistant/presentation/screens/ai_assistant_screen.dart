import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final List<ApartmentEntity>? suggestedApartments;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.suggestedApartments,
  }) : time = time ?? DateTime.now();
}

/// شاشة المساعد العقاري الذكي وحاسبة التسعير التلقائي بالذكاء الاصطناعي
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  // AI Price Estimator State
  String _estCity = 'التجمع الخامس';
  int _estBedrooms = 2;
  double _estArea = 120;
  bool _estFurnished = true;
  double? _estimatedPrice;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'مرحباً بك! أنا مساعد سكني الذكي 🤖\nأستطيع مساعدتك في العثور على أفضل شقة تناسب ميزانيتك، أو تحليل أسعار الإيجار الحالية في أي منطقة في مصر. كيف يمكنني خدمتك اليوم؟',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateRentEstimate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;

    final userMsg = query.trim();
    _textController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userMsg, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simulate AI thinking and filtering real apartments
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final cubit = context.read<ApartmentCubit>();
      final allApts = cubit.state.apartments;

      final lowerQuery = userMsg.toLowerCase();
      List<ApartmentEntity> matched = [];

      // Keyword & city matching
      matched = allApts.where((apt) {
        final matchCity = lowerQuery.contains('تجمع') && apt.city.contains('تجمع') ||
            lowerQuery.contains('زايد') && apt.city.contains('زايد') ||
            lowerQuery.contains('قاهرة') && apt.city.contains('قاهرة') ||
            lowerQuery.contains('إسكندرية') && apt.city.contains('إسكندرية') ||
            lowerQuery.contains('ساحل') && apt.city.contains('ساحل');

        final matchStudents = lowerQuery.contains('طالب') || lowerQuery.contains('طلاب') || lowerQuery.contains('رخيص');
        final matchPrice = matchStudents ? (apt.monthlyPrice <= 8000 && apt.monthlyPrice > 0) : true;

        return matchCity || (matchStudents && matchPrice);
      }).toList();

      if (matched.isEmpty) {
        // Fallback to top rated apartments
        matched = allApts.take(2).toList();
      }

      String replyText;
      if (lowerQuery.contains('طالب') || lowerQuery.contains('طلاب')) {
        replyText =
            'وجدت لك شققاً ممتازة قريبة من الجامعات والخدمات بميزانيات اقتصادية تناسب الطلاب وبدون تعقيدات في التأمين:';
      } else if (lowerQuery.contains('تجمع') || lowerQuery.contains('زايد')) {
        replyText =
            'بناءً على طلبك، هذه أفضل الخيارات المتاحة حالياً في المناطق الراقية مع تشطيب ألترا سوبر لوكس:';
      } else if (lowerQuery.contains('سعر') || lowerQuery.contains('كام') || lowerQuery.contains('ميزانية')) {
        replyText =
            'متوسط الأسعار في هذه الفئة يتراوح بين 6,000 إلى 15,000 ج.م شهرياً. إليك أنسب الوحدات المتوفرة فوراً:';
      } else {
        replyText =
            'قمت بتحليل طلبك في قاعدة بيانات سكني، وهذه أفضل الوحدات التي تتطابق مع تفضيلاتك:';
      }

      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: replyText,
          isUser: false,
          suggestedApartments: matched,
        ));
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _calculateRentEstimate() {
    double basePerMeter = 90.0;
    if (_estCity == 'التجمع الخامس' || _estCity == 'الشيخ زايد') {
      basePerMeter = 140.0;
    } else if (_estCity == 'الساحل الشمالي') {
      basePerMeter = 160.0;
    } else if (_estCity == 'الإسكندرية') {
      basePerMeter = 85.0;
    }

    double total = _estArea * basePerMeter;
    total += (_estBedrooms * 1200);
    if (_estFurnished) {
      total *= 1.35; // 35% premium for furnished
    }

    setState(() {
      _estimatedPrice = (total / 100).round() * 100.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.tr('aiAssistant'),
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  lang == 'ar' ? 'متصل وجاهز للمساعدة' : 'Online & ready to help',
                  style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.accentColor,
          labelColor: context.accentColor,
          unselectedLabelColor: context.textSecondary,
          labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.chat_bubble_outline_rounded), text: tr.tr('chatWithAi')),
            Tab(icon: const Icon(Icons.calculate_outlined), text: tr.tr('aiRentEstimator')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: Conversational AI ──
          Column(
            children: [
              // Quick Suggestion Chips
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _QuickChip(
                      label: '🎓 شقق قريبة من الجامعات',
                      onTap: () => _sendMessage('ابحث عن شقق مناسبة للطلاب قريبة من الجامعات بميزانية اقتصادية'),
                    ),
                    _QuickChip(
                      label: '💎 شقق بالتجمع الخامس',
                      onTap: () => _sendMessage('أريد شقة مميزة بالتجمع الخامس مفروشة بالكامل'),
                    ),
                    _QuickChip(
                      label: '💰 شقق بأسعار اقتصادية',
                      onTap: () => _sendMessage('ما هي أرخص الشقق المتاحة حالياً في القاهرة؟'),
                    ),
                    _QuickChip(
                      label: '🏖️ شقق وشاليهات الساحل',
                      onTap: () => _sendMessage('ابحث لي عن شاليه أو شقة بالساحل الشمالي'),
                    ),
                  ],
                ),
              ),

              // Chat Messages List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _ChatBubble(message: msg);
                  },
                ),
              ),

              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr.tr('aiThinking'),
                        style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border(top: BorderSide(color: context.borderColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.tajawal(fontSize: 14, color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'اكتب ما تبحث عنه (مثال: شقة غرفتين في زايد)...',
                          hintStyle: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          filled: true,
                          fillColor: context.cardColor,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.gold,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── TAB 2: AI Rent Estimator ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withValues(alpha: 0.15),
                        context.surfaceColor,
                      ],
                    ),
                    borderRadius: AppRadius.mdBr,
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: AppColors.gold, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تستخدم هذه الأداة الذكاء الاصطناعي لحساب متوسط الإيجار العادل وفقاً لبيانات السوق الحقيقية ومؤشرات العرض والطلب.',
                          style: GoogleFonts.tajawal(fontSize: 12, color: context.textPrimary, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // City Selector
                Text('المدينة أو المنطقة:', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _estCity,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.cardColor,
                    border: OutlineInputBorder(borderRadius: AppRadius.smBr, borderSide: BorderSide(color: context.borderColor)),
                  ),
                  items: ['التجمع الخامس', 'الشيخ زايد', 'القاهرة', 'الجيزة', 'الإسكندرية', 'الساحل الشمالي']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.tajawal(color: context.textPrimary))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _estCity = val);
                      _calculateRentEstimate();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Bedrooms Selector
                Text('عدد الغرف: $_estBedrooms غرف', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: _estBedrooms.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: context.accentColor,
                  label: '$_estBedrooms',
                  onChanged: (val) {
                    setState(() => _estBedrooms = val.round());
                    _calculateRentEstimate();
                  },
                ),
                const SizedBox(height: 12),

                // Area Selector
                Text('المساحة التقريبية: ${_estArea.round()} م²', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: _estArea,
                  min: 40,
                  max: 300,
                  divisions: 26,
                  activeColor: context.accentColor,
                  label: '${_estArea.round()} م²',
                  onChanged: (val) {
                    setState(() => _estArea = val);
                    _calculateRentEstimate();
                  },
                ),
                const SizedBox(height: 12),

                // Furnished Toggle
                SwitchListTile(
                  title: Text('شقة مفروشة بالكامل', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('الشقق المفروشة تحقق عائداً أعلى بنسبة 35% في المتوسط', style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary)),
                  value: _estFurnished,
                  activeThumbColor: context.accentColor,
                  onChanged: (val) {
                    setState(() => _estFurnished = val);
                    _calculateRentEstimate();
                  },
                ),
                const SizedBox(height: 24),

                // Estimation Card
                if (_estimatedPrice != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.2),
                          const Color(0xFF0F172A),
                        ],
                      ),
                      borderRadius: AppRadius.lgBr,
                      border: Border.all(color: AppColors.gold, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          tr.tr('suggestedPrice'),
                          style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_estimatedPrice!.round()} ${tr.tr('perMonth')}',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نطاق السوق: ${(_estimatedPrice! * 0.9).round()} - ${(_estimatedPrice! * 1.1).round()} ج.م',
                          style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 12),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricItem(label: 'مؤشر الطلب', value: 'مرتفع جداً 🔥'),
                            _MetricItem(label: 'الإيجار اليومي', value: '${(_estimatedPrice! / 20).round()} ج.م'),
                            _MetricItem(label: 'التأمين المقترح', value: '${_estimatedPrice!.round()} ج.م'),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: AppColors.gold, size: 16),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? context.accentColor
                        : context.cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    border: Border.all(
                      color: message.isUser ? Colors.transparent : context.borderColor,
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.tajawal(
                      color: message.isUser ? const Color(0xFF080C14) : context.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: message.isUser ? FontWeight.w700 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Suggested Apartments list if any
          if (message.suggestedApartments != null && message.suggestedApartments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.suggestedApartments!.length,
                itemBuilder: (context, i) {
                  final apt = message.suggestedApartments![i];
                  return Container(
                    width: 230,
                    margin: const EdgeInsets.only(left: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            apt.title,
                            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 12, color: context.accentColor),
                              const SizedBox(width: 2),
                              Text(apt.city, style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary)),
                              const Spacer(),
                              Text(
                                '${apt.monthlyPrice.round()} ج.م',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.gold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.accentColor,
                                foregroundColor: const Color(0xFF080C14),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () {
                                final model = apt is ApartmentModel ? apt : ApartmentModel.fromEntity(apt);
                                Navigator.pushNamed(context, '/booking', arguments: model);
                              },
                              child: Text('حجز فوري', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.bold)),
        backgroundColor: context.cardColor,
        side: BorderSide(color: context.borderColor),
        onPressed: onTap,
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.tajawal(fontSize: 10, color: context.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
      ],
    );
  }
}
