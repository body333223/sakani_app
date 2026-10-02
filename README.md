# 🏠 تطبيق سكني (Sakani App) — المنصة الذكية الفاخرة لتأجير الشقق السكنية

<p align="center">
  <img src="assets/images/app_logo.jpg" alt="Sakani Logo" width="130" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.25);" />
</p>

<p align="center">
  <strong>منصة عقارية عصرية متكاملة تربط بين المستأجرين وأصحاب العقارات بأعلى معايير الأمان والتصميم الفاخر</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Architecture-Clean%20Architecture-teal" alt="Clean Architecture" />
  <img src="https://img.shields.io/badge/Security-AES--256%20Encrypted-critical" alt="Security" />
  <img src="https://img.shields.io/badge/Biometrics-Face%20ID%20%7C%20Touch%20ID-success" alt="Biometrics" />
  <img src="https://img.shields.io/badge/CI%2FCD-Codemagic%20Automated-blueviolet" alt="Codemagic" />
</p>

---

## 🌟 نظرة عامة (Overview)

تطبيق **سكني (Sakani)** هو حل رقمي متطور ومبتكر لقطاع تأجير العقارات في مصر والوطن العربي، مصمم لتوفير تجربة مستخدم استثنائية وسلسة (`Luxury UI/UX`) تجمع بين السرعة القصوى، التشفير العسكري للبيانات الحساسة، والتكامل التام بين المستأجرين والملاك.

---

## ✨ أبرز المزايا والوظائف (Key Features)

### 🔐 الأمان والمصادقة الحيوية (Biometrics & Security)
- **تسجيل الدخول بالبصمة وFace ID**: دعم كامل للمصادقة البيومترية الحيوية على أجهزة iPhone و Android مع سرعة استجابة فائقة.
- **خيار "تذكرني" (`Remember Me`)**: حفظ بيانات الدخول مشفرة بنظام `AES-256` مع تعبئة تلقائية عند فتح التطبيق.
- **تشفير شامل للبيانات**: تشفير التوكنات، جلسات المستخدمين، سجلات المحادثات، ومفاتيح الخادم الحساسة عبر `SecureStorageService`.
- **توثيق الهوية الرسمي (`KYC`)**: نظام توثيق رقمي لبطاقات الرقم القومي وجوازات السفر لضمان موثوقية المستأجرين والملاك.

### 🏛️ شريط التطبيق المخصص (`Luxury Custom AppBar`)
- **البروفايل الذكي على اليمين**: صورة المستخدم الشخصية بإطار ذهبي أنيق، مع ترحيب باسم المستخدم والتنقل المباشر لملفه الشخصي.
- **مركز التنبيهات على اليسار**: زر إشعارات مزود بشارة عداد (`Badge`)، يفتح لوحة إشعارات تفاعلية عصرية (`NotificationsBottomSheet`) لمتابعة الحجوزات والعروض أولاً بأول.

### 👤 الحساب والبروفايل الموحد (`Unified Luxury Profile`)
- **تجربة موحدة خالية من التكرار**: دمج كامل لبيانات الحساب، إعدادات الأمان، والمظهر في شاشة واحدة منظمة بدقة.
- **تحديث فوري للصورة والبيانات**: إمكانية التقاط صورة بالكاميرا أو اختيارها من المعرض بضغطة واحدة، مع نافذة فورية لتعديل الاسم ورقم الهاتف.
- **المحفظة الرقمية (`Digital Wallet`)**: متابعة الرصيد الفوري، شحن المحفظة، واستعراض سجل المعاملات المالية الموثقة.

### 🖼️ عرض بصري متطور وعالمي (Visuals & Animations)
- **سلايدر الشقق المميزة (`FeaturedCarousel`)**: تأثيرات عمق ثلاثية الأبعاد (`3D Perspective Coverflow`) ومؤشرات صفحات عصرية (`Pill Indicators`) مع بطاقة سعر زجاجية عائمة.
- **معرض صور تفاعلي على الكارت (`ApartmentCard Gallery`)**: إمكانية تصفح جميع صور الشقة بالسحب المباشر على الكارت في الصفحة الرئيسية دون الحاجة لفتح التفاصيل، مع عدّاد للصور.
- **أنيميشن فيزيائي (`Micro-interactions`)**: تأثيرات ارتداد سلسة (`BouncingTap`) ونبض لتفضيل الشقق.

### 💬 المحادثات الفورية المشفرة (Real-Time Encrypted Chat)
- محادثات سريعة ومباشرة بين المستأجر والمالك.
- تخزين فوري وتحديث فوري للرسائل دون تأخير مع دعم العمل دون اتصال بالإنترنت (`Offline Persistence`).

---

## 🏗️ الهيكلية المعمارية (Clean Architecture)

تم بناء المشروع باتباع مبادئ **Clean Architecture** الصارمة لضمان سهولة التوسع، الصيانة، والاختبار:

```
sakani_app/
├── lib/
│   ├── main.dart                          # نقطة الانطلاق وتهيئة التخزين المشفر
│   ├── core/
│   │   ├── config/                        # إعدادات الـ API، الدومين الثابت، الثيمات
│   │   ├── localization/                  # دعم اللغتين العربية (RTL) والإنجليزية
│   │   ├── security/                      # محرك التشفير AES-256 والمخزن الآمن
│   │   ├── services/                      # خدمات البصمة، KYC، والخدمات المشتركة
│   │   ├── utils/                         # الانتقالات والرسوم المتحركة الفاخرة
│   │   └── widgets/                       # المكونات العامة (AppBar, BottomSheets, Cards)
│   └── features/
│       ├── auth/                          # المصادقة، البصمة، وتذكرني
│       │   ├── data/                      # مصادر البيانات والمستودعات
│       │   ├── presentation/              # شاشات الدخول، التسجيل، وCubit/Provider
│       ├── apartments/                    # استعراض الشقق، السلايدر 3D، ولوحة التحكم
│       ├── bookings/                      # إدارة الحجوزات، التأكيد، والعمليات المالية
│       ├── chat/                          # نظام المحادثات المباشرة والمشفرة
│       ├── settings/                      # البروفايل الموحد، المظهر، وإعدادات الحساب
│       └── wallet/                        # محفظة سكني الرقمية والمعاملات
├── android/                               # إعدادات حماية أندرويد ودعم البصمة
├── ios/                                   # إعدادات iOS، أيقونات التطبيق، وأذونات Face ID
├── run_sakani_online.py                   # سكربت تشغيل الباك إند ونفق Ngrok الدائم
└── codemagic.yaml                         # خط أنابيب البناء الآلي (CI/CD) لـ iOS
```

---

## 🛠️ حزمة التقنيات المستخدمة (Tech Stack)

| التقنية | الاستخدام |
|---------|-----------|
| **Flutter 3.44+ / Dart 3.12+** | الإطار البرمجي الأساسي للتطبيقات متعددة المنصات |
| **BLoC / Cubit & Provider** | إدارة الحالة الاحترافية وفصل منطق الأعمال عن الواجهة |
| **local_auth** | المصادقة الحيوية لبصمة الإصبع وFace ID |
| **shared_preferences** | التخزين الدائم للبيانات المشفرة على القرص |
| **AES-256 & SHA-256** | محرك التشفير العسكري لحماية بيانات المستخدم والتوكنات |
| **CachedNetworkImage** | كاش ذكي للصور وتوفير استهلاك الذاكرة والإنترنت |
| **Google Fonts (Tajawal)** | طباعة خطوط عربية فاخرة وعصرية |
| **Python / Ngrok Tunneling** | تشغيل الخادم المحلي وربطه بدومين ثابت دائم مدى الحياة |
| **Codemagic CI/CD** | أتمتة بناء وتجهيز حزم iOS `.ipa` غير الموقعة والجاهزة للتثبيت |

---

## 🚀 التشغيل والتثبيت المحلي (Getting Started)

### المتطلبات المسبقة
- تثبيت [Flutter SDK](https://flutter.dev/docs/get-started/install) (إصدار 3.44 أو أحدث).
- تثبيت [Python 3.10+](https://www.python.org/).

### خطوات التثبيت:

1. **استنساخ المستودع (Clone Repository):**
   ```bash
   git clone https://github.com/body333223/sakani_app.git
   cd sakani_app
   ```

2. **تثبيت حزم الـ Flutter:**
   ```bash
   flutter pub get
   ```

3. **تشغيل الخادم المحلي المربوط بالدومين الثابت:**
   ```bash
   python run_sakani_online.py
   ```
   > يقوم السكربت تلقائياً بتشغيل الباك إند وربطه بنفق Ngrok الثابت: `https://prodigal-overpower-nail.ngrok-free.dev/api`.

4. **تشغيل التطبيق على الهاتف أو المحاكي:**
   ```bash
   flutter run
   ```

---

## 📦 البناء والإنتاج (Build & Deployment)

### 🍏 بناء نسخة الـ iOS (`.ipa`):
المشروع معد بالكامل للبناء الآلي عبر **Codemagic CI/CD**:
- ملف التكوين: [codemagic.yaml](file:///c:/Users/pC/Downloads/sakani_app/sakani_app/codemagic.yaml).
- يقوم ببناء التطبيق بصيغة `Release` وتجهيز ملف `sakani.ipa` جاهز للتثبيت المباشر عبر TrollStore أو AltStore أو TestFlight.

### 🤖 بناء نسخة أندرويد المشفرة (`.apk`):
```bash
flutter build apk --release --obfuscate --split-debug-info=./build/symbols
```

---

## 🔒 معايير الجودة والأمان (Quality & Standards)
- **Clean Architecture & SOLID Principles**: فصل تام للمسؤوليات بين طبقات Domain, Data, و Presentation.
- **Zero Analyzer Issues**: فحص الكود البرمجي عبر `flutter analyze` خالي بنسبة 100% من أي أخطاء أو تحذيرات.
- **RTL Native First**: دعم كامل وأصيل للغة العربية مع الحفاظ على مرونة التبديل للغة الإنجليزية.

---

<p align="center">
  صنع بكل ❤️ وفخر بواسطة فريق تطوير <strong>سكني (Sakani)</strong>
</p>
