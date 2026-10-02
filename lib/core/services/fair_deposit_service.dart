/// محرك حساب التأمين المالي العادل والمدروس بناءً على المنطقة ونوع الإيجار
class FairDepositService {
  FairDepositService._();

  /// فئات المناطق الإيجارية ومستوى الخطورة والتأمين
  static String getRegionTier(String city) {
    final lower = city.toLowerCase();
    if (lower.contains('تجمع') ||
        lower.contains('زايد') ||
        lower.contains('ساحل') ||
        lower.contains('سليمانية')) {
      return 'منطقة راقية (عالية التجهيز)';
    } else if (lower.contains('معادي') ||
        lower.contains('جديدة') ||
        lower.contains('نصر') ||
        lower.contains('دقي') ||
        lower.contains('زمالك') ||
        lower.contains('مهندسين')) {
      return 'منطقة قياسية (سكنية عائلية)';
    } else {
      return 'منطقة اقتصادية / طلابية (ميسرة)';
    }
  }

  /// حساب التأمين العادل بدقة متناهية
  static double calculateFairDeposit({
    required String city,
    required String periodType, // 'يومي', 'شهري', 'سنوي'
    required double basePrice,   // dailyPrice, monthlyPrice, or yearlyPrice
    required int daysCount,
    required double apartmentSpecifiedDeposit,
  }) {
    final lower = city.toLowerCase();

    // 1. حالة الإيجار اليومي
    if (periodType == 'يومي') {
      // التأمين اليومي لا يجب أن يكون شهراً كاملاً، بل تأمين رمزي عادل مقابل المفاتيح
      if (lower.contains('تجمع') || lower.contains('زايد') || lower.contains('ساحل')) {
        return (daysCount * basePrice * 0.20).clamp(400.0, 2000.0);
      } else {
        return (daysCount * basePrice * 0.15).clamp(250.0, 1000.0);
      }
    }

    // 2. حالة الإيجار السنوي
    if (periodType == 'سنوي') {
      // يعادل إيجار شهر واحد أو شهر ونصف كحد أقصى
      final monthlyEquivalent = basePrice / 12.0;
      if (lower.contains('تجمع') || lower.contains('زايد') || lower.contains('ساحل')) {
        return (monthlyEquivalent * 1.0).clamp(3000.0, 25000.0);
      } else {
        return (monthlyEquivalent * 0.75).clamp(1500.0, 12000.0);
      }
    }

    // 3. حالة الإيجار الشهري
    final monthlyPrice = basePrice;
    if (lower.contains('تجمع') || lower.contains('زايد') || lower.contains('ساحل')) {
      // للمناطق الراقية: نصف شهر إلى شهر كامل بحد أقصى لحماية الأثاث
      final calculated = monthlyPrice * 0.60;
      return calculated.clamp(2000.0, 20000.0);
    } else if (lower.contains('معادي') ||
        lower.contains('جديدة') ||
        lower.contains('نصر') ||
        lower.contains('دقي') ||
        lower.contains('زمالك')) {
      // للمناطق المتوسطة: 35% إلى 45% من شهر الإيجار
      final calculated = monthlyPrice * 0.40;
      return calculated.clamp(1200.0, 10000.0);
    } else {
      // للمناطق الطلابية والاقتصادية: 20% فقط لتسهيل السكن على الطلاب
      final calculated = monthlyPrice * 0.20;
      return calculated.clamp(500.0, 4000.0);
    }
  }
}
