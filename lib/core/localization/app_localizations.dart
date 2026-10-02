import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

class AppLocalizations {
  final String lang;

  AppLocalizations(this.lang);

  static AppLocalizations of(String lang) => AppLocalizations(lang);

  static const Map<String, Map<String, String>> _localized = {
    'ar': {
      // App & General
      'appName': 'سكني',
      'appTagline': 'تأجير الشقق الفاخرة المعتمدة',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'darkMode': 'الوضع الداكن',
      'lightMode': 'الوضع الفاتح',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'confirm': 'تأكيد',
      'currency': 'ج.م',
      'perMonth': 'ج.م / شهرياً',
      'perDay': 'ج.م / يومياً',

      // Navigation & Tabs
      'home': 'الرئيسية',
      'explore': 'استكشاف',
      'wishlist': 'المفضلة',
      'favorites': 'المفضلة',
      'myBookings': 'حجوزاتي',
      'chats': 'المحادثات',
      'myAccount': 'حسابي',
      'settings': 'الإعدادات',

      // Auth
      'login': 'تسجيل الدخول',
      'register': 'إنشاء حساب',
      'logout': 'تسجيل خروج',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'fullName': 'الاسم الكامل',
      'phone': 'رقم الجوال',
      'accountType': 'نوع الحساب',
      'tenant': 'مستأجر',
      'owner': 'مالك عقار',
      'noAccount': 'ليس لديك حساب؟ إنشاء حساب جديد',
      'hasAccount': 'لديك حساب بالفعل؟ تسجيل الدخول',
      'emailRequired': 'البريد الإلكتروني مطلوب',
      'passwordRequired': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'nameRequired': 'الاسم مطلوب',
      'phoneRequired': 'رقم جوال صحيح مطلوب',
      'welcome': 'مرحباً!',
      'welcomeBack': 'مرحباً بعودتك!',

      // Apartment Search & Details
      'findApartment': 'ابحث عن شقتك المثالية',
      'searchPlaceholder': 'ابحث بالمدينة أو الحي أو المنطقة...',
      'allCities': 'كل المدن',
      'cairo': 'القاهرة',
      'giza': 'الجيزة',
      'alexandria': 'الإسكندرية',
      'tagamoa': 'التجمع الخامس',
      'zayed': 'الشيخ زايد',
      'northCoast': 'الساحل الشمالي',
      'apartmentDetails': 'تفاصيل الشقة',
      'apartmentInfo': 'معلومات الشقة',
      'bookNow': 'حجز الآن',
      'instantBook': 'حجز فوري',
      'noApartments': 'لا توجد شقق متاحة حالياً',
      'bedrooms': 'غرف النوم',
      'bathrooms': 'الحمامات',
      'area': 'المساحة (م²)',
      'maxGuests': 'أقصى ضيوف',
      'amenities': 'المرافق والخدمات',
      'description': 'الوصف والبيانات',
      'location': 'الموقع الجغرافي',
      'city': 'المدينة',
      'address': 'العنوان',
      'ownerName': 'المالك',
      'contactPhone': 'هاتف التواصل',

      // Rental Types
      'daily': 'يومي',
      'monthly': 'شهري',
      'yearly': 'سنوي',
      'rentalType': 'نوع الإيجار',

      // Booking & Payment
      'bookingTitle': 'حجز الشقة',
      'bookingDate': 'تاريخ الحجز',
      'from': 'من',
      'to': 'إلى',
      'duration': 'مدة الإقامة',
      'days': 'يوم',
      'months': 'شهر',
      'guests': 'عدد الضيوف',
      'guest': 'ضيف',
      'baseRent': 'المبلغ الأساسي للإيجار',
      'platformCommission': 'عمولة المنصة',
      'fairDeposit': 'تأمين مالي عادل',
      'totalDue': 'الإجمالي المطلوب دفعه',
      'paymentMethod': 'طريقة الدفع والحساب الوسيط',
      'escrowBadge': 'ضمان مالي شامل (Escrow Safe Pay)',
      'escrowDescription': 'أموالك محمية بحساب وسيط، ولا يتم تحويلها إلى المالك إلا بعد استلام الشقة والتأكد من مطابقتها للمواصفات.',
      'walletPay': 'محفظة سكني الرقمية',
      'cardPay': 'بطاقة بنكية (Visa / MasterCard / Meeza)',
      'vodafonePay': 'محافظ المحمول وإنستاباي (InstaPay)',
      'fawryPay': 'فوري باي (FawryPay)',
      'confirmBooking': 'تأكيد الحجز',
      'bookingSuccess': 'تم إرسال طلب الحجز بنجاح والمبلغ محمي بحساب الضمان 🛡️',
      'insufficientBalance': 'رصيد المحفظة غير كافٍ. يرجى الشحن أو اختيار وسيلة دفع أخرى.',

      // E-Contract & Signature
      'eContract': 'عقد الإيجار الإلكتروني الموحد',
      'digitalSignature': 'التوقيع الرقمي باليد',
      'signHere': 'وقّع هنا بإصبعك ✍️',
      'clearSignature': 'مسح التوقيع',
      'saveSignature': 'اعتماد التوقيع',
      'agreeToTerms': 'أوافق على كافة الشروط والأحكام الخاصة بالعقد الموحد',
      'contractAuthenticated': 'توثيق واعتماد العقد رسمياً',
      'previewContract': 'معاينة وتوقيع عقد الإيجار الإلكتروني ✍️',

      // AI Assistant & Calculator
      'aiAssistant': 'المساعد العقاري الذكي (AI)',
      'aiRentEstimator': 'حاسبة تسعير الإيجار العادل',
      'chatWithAi': 'محادثة وبحث ذكي',
      'aiThinking': 'جاري التفكير وتحليل الشقق المتاحة...',
      'suggestedPrice': 'القيمة الإيجارية المقترحة بالذكاء الاصطناعي',

      // Trust & Reviews
      'trustScore': 'مؤشر الثقة',
      'verifiedUser': 'طرف موثوق ومعتمد',
      'addReview': 'إضافة تقييم جديد',
      'submitReview': 'إرسال التقييم',

      // Notifications
      'notifications': 'الإشعارات',
      'markAllAsRead': 'تحديد الكل كمقروء',
      'noNotifications': 'لا توجد إشعارات جديدة حالياً',

      // Amenities
      'furnished': 'مفروشة بالكامل',
      'airConditioned': 'مكيفة بالكامل',
      'wifi': 'إنترنت فائق السرعة',
      'elevator': 'مصعد كهربائي',
      'parking': 'موقف سيارات خاص',
      'security': 'أمن وحراسة 24/7',
      'balcony': 'شرفة وإطلالة مميزة',
      'pool': 'حمام سباحة',
      'gym': 'صالة رياضية / جيم',
      'kitchen': 'مطبخ متكامل الأجهزة',

      // Filter & General
      'all': 'الكل',
      'seeAll': 'عرض الكل',
      'search': 'بحث',
      'filter': 'تصفية',
      'noResults': 'لا توجد شقق مطابقة لخيارات البحث',
      'startDate': 'تاريخ الوصول',
      'endDate': 'تاريخ المغادرة',
      'nights': 'ليالي',
      'night': 'ليلة',
      'changeLanguage': 'تغيير اللغة',
      'languageChanged': 'تم تغيير لغة التطبيق بنجاح',
      'wallet': 'المحفظة الرقمية',
      'currentBalance': 'الرصيد المتاح',
      'topUp': 'شحن الرصيد',
      'history': 'سجل المعاملات',
      'contracts': 'العقود الإلكترونية',
      'support': 'الدعم الفني والمساعدة',
      'terms': 'الشروط والأحكام',
      'privacy': 'سياسة الخصوصية',
      'aboutUs': 'عن منصة سكني',
      'close': 'إغلاق',
      'retry': 'إعادة المحاولة',
      'profile': 'الملف الشخصي',
      'editProfile': 'تعديل البيانات',
      'securitySettings': 'إعدادات الأمان',
      'notificationsSettings': 'إعدادات الإشعارات',
      'appearance': 'المظهر والسمة',
    },
    'en': {
      // App & General
      'appName': 'Sakani',
      'appTagline': 'Luxury Verified Apartments Rental',
      'language': 'Language',
      'arabic': 'العربية',
      'english': 'English',
      'darkMode': 'Dark Mode',
      'lightMode': 'Light Mode',
      'cancel': 'Cancel',
      'save': 'Save',
      'confirm': 'Confirm',
      'currency': 'EGP',
      'perMonth': 'EGP / Month',
      'perDay': 'EGP / Day',

      // Navigation & Tabs
      'home': 'Home',
      'explore': 'Explore',
      'wishlist': 'Wishlist',
      'favorites': 'Favorites',
      'myBookings': 'My Bookings',
      'chats': 'Chats',
      'myAccount': 'My Account',
      'settings': 'Settings',

      // Auth
      'login': 'Login',
      'register': 'Create Account',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'fullName': 'Full Name',
      'phone': 'Phone Number',
      'accountType': 'Account Type',
      'tenant': 'Tenant',
      'owner': 'Property Owner',
      'noAccount': "Don't have an account? Sign Up",
      'hasAccount': 'Already have an account? Login',
      'emailRequired': 'Email is required',
      'passwordRequired': 'Password must be at least 6 characters',
      'nameRequired': 'Full name is required',
      'phoneRequired': 'Valid phone number is required',
      'welcome': 'Welcome!',
      'welcomeBack': 'Welcome back!',

      // Apartment Search & Details
      'findApartment': 'Find your dream apartment',
      'searchPlaceholder': 'Search by city, district or area...',
      'allCities': 'All Cities',
      'cairo': 'Cairo',
      'giza': 'Giza',
      'alexandria': 'Alexandria',
      'tagamoa': 'New Cairo (Tagamoa)',
      'zayed': 'Sheikh Zayed',
      'northCoast': 'North Coast',
      'apartmentDetails': 'Apartment Details',
      'apartmentInfo': 'Apartment Info',
      'bookNow': 'Book Now',
      'instantBook': 'Instant Booking',
      'noApartments': 'No apartments available currently',
      'bedrooms': 'Bedrooms',
      'bathrooms': 'Bathrooms',
      'area': 'Area (m²)',
      'maxGuests': 'Max Guests',
      'amenities': 'Amenities & Facilities',
      'description': 'Description & Overview',
      'location': 'Location',
      'city': 'City',
      'address': 'Address',
      'ownerName': 'Owner',
      'contactPhone': 'Contact Phone',

      // Rental Types
      'daily': 'Daily',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
      'rentalType': 'Rental Type',

      // Booking & Payment
      'bookingTitle': 'Book Apartment',
      'bookingDate': 'Booking Dates',
      'from': 'From',
      'to': 'To',
      'duration': 'Stay Duration',
      'days': 'Days',
      'months': 'Months',
      'guests': 'Number of Guests',
      'guest': 'Guest',
      'baseRent': 'Base Rental Amount',
      'platformCommission': 'Platform Commission',
      'fairDeposit': 'Fair Security Deposit',
      'totalDue': 'Total Payable Amount',
      'paymentMethod': 'Payment Method & Escrow',
      'escrowBadge': 'Escrow Safe Pay Guarantee',
      'escrowDescription': 'Your funds are held securely in escrow and only released to the landlord after inspection and check-in confirmation.',
      'walletPay': 'Sakani Digital Wallet',
      'cardPay': 'Credit/Debit Card (Visa/Mastercard/Meeza)',
      'vodafonePay': 'Mobile Wallets & InstaPay',
      'fawryPay': 'FawryPay (Cash Reference Code)',
      'confirmBooking': 'Confirm Booking',
      'bookingSuccess': 'Booking request submitted successfully with Escrow protection 🛡️',
      'insufficientBalance': 'Insufficient wallet balance. Please top up or choose another payment method.',

      // E-Contract & Signature
      'eContract': 'Unified Digital Tenancy Contract',
      'digitalSignature': 'Digital Hand Signature',
      'signHere': 'Sign here with your finger ✍️',
      'clearSignature': 'Clear Signature',
      'saveSignature': 'Apply Signature',
      'agreeToTerms': 'I agree to all tenancy contract terms and conditions',
      'contractAuthenticated': 'Officially Authenticate Contract',
      'previewContract': 'Preview & Sign E-Tenancy Contract ✍️',

      // AI Assistant & Calculator
      'aiAssistant': 'AI Property Assistant',
      'aiRentEstimator': 'Fair Rent Estimator',
      'chatWithAi': 'Smart Search & Chat',
      'aiThinking': 'Analyzing available apartments...',
      'suggestedPrice': 'AI Suggested Fair Monthly Rent',

      // Trust & Reviews
      'trustScore': 'Trust Score',
      'verifiedUser': 'Verified & Trusted User',
      'addReview': 'Add New Review',
      'submitReview': 'Submit Review',

      // Notifications
      'notifications': 'Notifications',
      'markAllAsRead': 'Mark all as read',
      'noNotifications': 'No new notifications currently',

      // Map View
      'interactiveMap': 'Interactive Apartments Map',
      'filterByCity': 'Filter by Area',

      // Amenities
      'furnished': 'Fully Furnished',
      'airConditioned': 'Air Conditioned',
      'wifi': 'High-Speed Wi-Fi',
      'elevator': 'Elevator',
      'parking': 'Private Parking',
      'security': '24/7 Security',
      'balcony': 'Scenic Balcony',
      'pool': 'Swimming Pool',
      'gym': 'Gym / Fitness',
      'kitchen': 'Equipped Kitchen',

      // Filter & General
      'all': 'All',
      'seeAll': 'See All',
      'search': 'Search',
      'filter': 'Filter',
      'noResults': 'No apartments match your search criteria',
      'startDate': 'Check-in Date',
      'endDate': 'Check-out Date',
      'nights': 'nights',
      'night': 'night',
      'changeLanguage': 'Change Language',
      'languageChanged': 'App language updated successfully',
      'wallet': 'Digital Wallet',
      'currentBalance': 'Available Balance',
      'topUp': 'Top Up Balance',
      'history': 'Transaction History',
      'contracts': 'E-Contracts',
      'support': 'Customer Support',
      'terms': 'Terms & Conditions',
      'privacy': 'Privacy Policy',
      'aboutUs': 'About Sakani',
      'close': 'Close',
      'retry': 'Retry',
      'profile': 'Profile',
      'editProfile': 'Edit Profile',
      'securitySettings': 'Security Settings',
      'notificationsSettings': 'Notification Settings',
      'appearance': 'Appearance & Theme',
    },
  };

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String tr(String key, [List<String>? args]) {
    final map = _localized[lang] ?? _localized['ar']!;
    var text = map[key] ?? key;
    if (args != null) {
      for (final arg in args) {
        text = text.replaceFirst('%s', arg);
      }
    }
    return text;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension StringTranslate on String {
  String tr(String lang, [List<String>? args]) {
    return AppLocalizations(lang).tr(this, args);
  }
}

extension BuildContextLocalization on BuildContext {
  String tr(String key, [List<String>? args]) {
    final lang = watch<LocaleProvider>().lang;
    return AppLocalizations(lang).tr(key, args);
  }

  bool get isArabic => watch<LocaleProvider>().isArabic;
  String get currentLang => watch<LocaleProvider>().lang;
}

