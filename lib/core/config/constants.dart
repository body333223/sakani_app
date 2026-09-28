/// ثوابت النظام العامة لتطبيق سكني (Clean Architecture Core Constants)
/// يحتوي هذا الملف على الإعدادات الثابتة العامة مثل نسب العمولات وفترات الإيجار والمرافق.
/// ملاحظة: تم إزالة أي قوائم مدن أو أماكن مسبقة لضمان أن تكون كافة البيانات ديناميكية بالكامل.
class AppConstants {
  /// اسم التطبيق بالعربية
  static const String appName = 'سكني';

  /// اسم التطبيق بالإنجليزية
  static const String appNameEn = 'Sakani';

  /// نسبة عمولة المنصة (10%)
  static const double commissionRate = 0.10;

  /// فترات وخيارات الإيجار المتاحة
  static const List<String> rentalPeriods = ['يومي', 'شهري', 'سنوي'];

  /// قائمة المرافق والخدمات المتاحة للاختيار عند إضافة عقار
  static const List<String> amenities = [
    'واي فاي',
    'تكييف',
    'موقف سيارات',
    'مطبخ',
    'غسالة',
    'تلفزيون',
    'مسبح',
    'صالة رياضية',
    'مصعد',
    'أمن',
    'حديقة',
    'خدمة تنظيف',
  ];

  /// سياسات الإلغاء ونسب الاسترداد
  static const Map<String, double> cancellationPolicies = {
    'مرنة': 1.0,
    'متوسطة': 0.5,
    'صارمة': 0.0,
  };

  /// حالات الحجز في النظام
  static const List<String> bookingStatuses = [
    'قيد الانتظار',
    'مقبول',
    'مرفوض',
    'نشط',
    'منتهي',
    'ملغي',
  ];
}

