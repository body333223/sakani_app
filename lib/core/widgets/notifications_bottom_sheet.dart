import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

class NotificationItem {
  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String timeAr;
  final String timeEn;
  final IconData icon;
  final Color color;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.timeAr,
    required this.timeEn,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleAr': titleAr,
        'titleEn': titleEn,
        'bodyAr': bodyAr,
        'bodyEn': bodyEn,
        'timeAr': timeAr,
        'timeEn': timeEn,
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
        'isRead': isRead,
      };

  static IconData _iconFromCode(dynamic code) {
    if (code is int) {
      if (code == 0xe59c) return Icons.check_circle_rounded;
      if (code == 0xe002) return Icons.account_balance_wallet_rounded;
      if (code == 0xe6e8) return Icons.verified_user_rounded;
      if (code == 0xe59a) return Icons.star_rounded;
      if (code == 0xe3e0) return Icons.location_on_rounded;
    }
    return Icons.notifications_rounded;
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] ?? '',
        titleAr: json['titleAr'] ?? '',
        titleEn: json['titleEn'] ?? '',
        bodyAr: json['bodyAr'] ?? '',
        bodyEn: json['bodyEn'] ?? '',
        timeAr: json['timeAr'] ?? '',
        timeEn: json['timeEn'] ?? '',
        icon: _iconFromCode(json['iconCode']),
        color: Color(json['colorValue'] is int ? json['colorValue'] as int : 0xFFD4AF37),
        isRead: json['isRead'] ?? false,
      );
}

class NotificationsBottomSheet extends StatefulWidget {
  const NotificationsBottomSheet({super.key});

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static const String _storageKey = 'sakani_app_notifications_v2';
  static const String _readIdsKey = 'sakani_app_read_notif_ids';
  static bool _initialized = false;

  static final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'notif_welcome',
      titleAr: 'مرحباً بك في سكني! 🌟',
      titleEn: 'Welcome to Sakani! 🌟',
      bodyAr: 'استكشف أفضل الشقق المعتمدة وتجربة التأجير الأكثر أماناً في مصر.',
      bodyEn: 'Explore top verified apartments and enjoy the safest rental experience in Egypt.',
      timeAr: 'الآن',
      timeEn: 'Just now',
      icon: Icons.celebration_rounded,
      color: AppColors.gold,
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_escrow',
      titleAr: 'حماية المدفوعات والضمان 🛡️',
      titleEn: 'Escrow Payment Protection 🛡️',
      bodyAr: 'أموالك محفوظة بالكامل في حساب الضمان حتى استلام الشقة وتأكيد المعاينة.',
      bodyEn: 'Your funds are safely held in escrow until key handover and property verification.',
      timeAr: 'اليوم',
      timeEn: 'Today',
      icon: Icons.shield_rounded,
      color: AppColors.success,
      isRead: false,
    ),
    NotificationItem(
      id: 'notif_wallet',
      titleAr: 'المحفظة الرقمية الذكية 💳',
      titleEn: 'Smart Digital Wallet 💳',
      bodyAr: 'يمكنك الآن شحن وسحب أموالك فورياً عبر انستاباي والمحافظ الإلكترونية.',
      bodyEn: 'You can now top up and withdraw instantly via InstaPay and mobile wallets.',
      timeAr: 'أمس',
      timeEn: 'Yesterday',
      icon: Icons.account_balance_wallet_rounded,
      color: Colors.blueAccent,
      isRead: true,
    ),
  ];

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = prefs.getStringList(_readIdsKey) ?? [];
      final readSet = readIds.toSet();

      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        _notifications.clear();
        for (final item in decoded) {
          final notif = NotificationItem.fromJson(item as Map<String, dynamic>);
          if (readSet.contains(notif.id)) {
            notif.isRead = true;
          }
          _notifications.add(notif);
        }
      } else {
        for (final n in _notifications) {
          if (readSet.contains(n.id)) {
            n.isRead = true;
          }
        }
      }

      _updateUnreadCount();
      _initialized = true;
    } catch (_) {
      _updateUnreadCount();
    }
  }

  static void _updateUnreadCount() {
    unreadCountNotifier.value = _notifications.where((n) => !n.isRead).length;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);

      final readIds = _notifications.where((n) => n.isRead).map((n) => n.id).toList();
      await prefs.setStringList(_readIdsKey, readIds);
    } catch (_) {}
  }

  static Future<void> addNotification({
    required String title,
    required String body,
    IconData icon = Icons.notifications_active_rounded,
    Color? color,
  }) async {
    await init();
    final newNotif = NotificationItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      titleAr: title,
      titleEn: title,
      bodyAr: body,
      bodyEn: body,
      timeAr: 'الآن',
      timeEn: 'Just now',
      icon: icon,
      color: color ?? AppColors.gold,
      isRead: false,
    );
    _notifications.insert(0, newNotif);
    _updateUnreadCount();
    await _persist();
  }

  static Future<void> show(BuildContext context) async {
    await init();
    if (!context.mounted) return;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsBottomSheet(),
    );
  }

  @override
  State<NotificationsBottomSheet> createState() => _NotificationsBottomSheetState();
}

class _NotificationsBottomSheetState extends State<NotificationsBottomSheet> {
  List<NotificationItem> get _notifications => NotificationsBottomSheet._notifications;

  Future<void> _markAllAsRead() async {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    NotificationsBottomSheet._updateUnreadCount();
    await NotificationsBottomSheet._persist();
  }

  Future<void> _markSingleAsRead(NotificationItem item) async {
    if (!item.isRead) {
      setState(() {
        item.isRead = true;
      });
      NotificationsBottomSheet._updateUnreadCount();
      await NotificationsBottomSheet._persist();
    }
  }

  Future<void> _removeNotification(String id) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    NotificationsBottomSheet._updateUnreadCount();
    await NotificationsBottomSheet._persist();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isAr = context.watch<LocaleProvider>().isArabic;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_rounded, color: context.accentColor, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  isAr ? 'التنبيهات والإشعارات' : 'Notifications & Alerts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isAr ? '$unreadCount جديد' : '$unreadCount New',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isAr ? 'تحديد كمقروء' : 'Mark all as read',
                      style: TextStyle(
                        color: context.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: context.borderColor, height: 1),

          // Notifications List
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 60,
                          color: context.textSecondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'لا توجد إشعارات حالياً' : 'No notifications currently',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final title = isAr ? item.titleAr : item.titleEn;
                      final body = isAr ? item.bodyAr : item.bodyEn;
                      final time = isAr ? item.timeAr : item.timeEn;

                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _removeNotification(item.id),
                        background: Container(
                          alignment: isAr ? Alignment.centerLeft : Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        child: InkWell(
                          onTap: () => _markSingleAsRead(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? context.cardColor
                                  : context.accentColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.isRead
                                    ? context.borderColor
                                    : context.accentColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: item.color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.icon, color: item.color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: item.isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.w800,
                                                color: context.textPrimary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.textSecondary.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: context.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: context.accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
