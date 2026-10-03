import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';

class ConciergeServiceItem {
  final String id;
  final String title;
  final String subtitle;
  final String priceLabel;
  final IconData icon;
  final Color iconColor;
  final List<String> features;

  ConciergeServiceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.icon,
    required this.iconColor,
    required this.features,
  });
}

/// شاشة خدمات الكونسيرج الفندقية والضيافة المعتمدة داخل الشقق
class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({super.key});

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  final List<ConciergeServiceItem> _services = [
    ConciergeServiceItem(
      id: 'clean',
      title: 'النظافة الفندقية والتعقيم الشامل',
      subtitle: 'تنظيف عميق، تعقيم الأسطح، وتغيير مفروشات السرير والمناشف بمفارش فاخرة',
      priceLabel: '350 ج.م / زيارة',
      icon: Icons.cleaning_services_rounded,
      iconColor: Colors.blueAccent,
      features: ['تنظيف وتعقيم بالبخار', 'تغيير مفارش وأغطية فندقية', 'تعطير وتجهيز الشقة'],
    ),
    ConciergeServiceItem(
      id: 'maintenance',
      title: 'طوارئ الصيانة السريعة (خلال 60 دقيقة)',
      subtitle: 'فريق فني معتمد لحل أعطال التكييف، السباكة، والكهرباء على مدار الساعة',
      priceLabel: '200 ج.م كشف صيانة',
      icon: Icons.handyman_rounded,
      iconColor: Colors.orangeAccent,
      features: ['فني معتمد خلال ساعة', 'ضمان 30 يوم على الإصلاح', 'قطع غيار أصلية'],
    ),
    ConciergeServiceItem(
      id: 'airport',
      title: 'استقبال وتوصيل كبار الشخصيات بالمطار (VIP)',
      subtitle: 'سيارة حديثة وسائق محترف في انتظارك عند صالة الوصول بالمطار مع خدمة الحقائب',
      priceLabel: '450 ج.م / رحلة',
      icon: Icons.flight_land_rounded,
      iconColor: Colors.purpleAccent,
      features: ['سيارة خاصة مكيفة موديل حديث', 'استقبال بلافتة باسم النزيل', 'متابعة موعد وصول الطائرة'],
    ),
    ConciergeServiceItem(
      id: 'grocery',
      title: 'تجهيز الشقة بالمستلزمات قبل الوصول',
      subtitle: 'تعبئة الثلاجة والمطبخ بالأطعمة والمشروبات الأساسية والمياه لتجد كل شيء جاهزاً',
      priceLabel: '150 ج.م خدمة توصيل + الفاتورة',
      icon: Icons.local_grocery_store_rounded,
      iconColor: Colors.greenAccent,
      features: ['مياه وعصائر ومشروبات', 'مخبوزات طازجة وأجبان', 'حسب قائمة طلباتك الخاصة'],
    ),
  ];

  void _bookService(ConciergeServiceItem service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: service.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(service.icon, color: service.iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        service.priceLabel,
                        style: TextStyle(
                          color: context.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'المميزات المشمولة:',
              style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...service.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text(f, style: TextStyle(color: context.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'تأكيد طلب الخدمة الفورية ⚡',
              onPressed: () {
                Navigator.pop(ctx);
                NotificationsBottomSheet.addNotification(
                  title: 'تم تأكيد طلب الخدمة: ${service.title} 🛎️',
                  body: 'فريق سكني للضيافة سيصل لمقر شقتك في الموعد المحدد لتقديم الخدمة.',
                  icon: service.icon,
                  color: service.iconColor,
                );
                AppSnackbar.show(
                  context,
                  message: 'تم تسجيل طلبك بنجاح وسيتواصل معك مشرف الخدمة فوراً 🛎️',
                  type: ToastType.success,
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.room_service_rounded, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text(
              'خدمات الكونسيرج الفندقية',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.18),
                    AppColors.goldDark.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'إقامة فندقية 5 نجوم في شقتك',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'اطلب خدمات النظافة، الصيانة الفورية، وتوصيل المطار بضغطة زر مع فريق سكني المعتمد.',
                          style: TextStyle(color: context.textSecondary, fontSize: 11, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'الخدمات المتاحة الآن',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: service.iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(service.icon, color: service.iconColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.title,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.priceLabel,
                                  style: TextStyle(
                                    color: context.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        service.subtitle,
                        style: TextStyle(color: context.textSecondary, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.accentColor,
                            side: BorderSide(color: context.accentColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _bookService(service),
                          icon: const Icon(Icons.add_task_rounded, size: 16),
                          label: const Text('طلب الخدمة الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
