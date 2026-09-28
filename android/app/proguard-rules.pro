# ─── SAKANI APP PROGUARD & R8 SECURITY & OBFUSCATION RULES ───
# حماية كاملة للملفات والكود ومنع الهندسة العكسية وفك التجميع

# 1. التعتيم الكامل وتغيير الأسماء (Full Obfuscation & Minification)
-repackageclasses ''
-allowaccessmodification
-overloadaggressively
-useuniqueclassmembernames

# 2. حذف معلومات أسطر الكود وملفات المصدر الأصلية (Strip Source Metadata)
-renamesourcefileattribute "Source"
-keepattributes Exceptions,InnerClasses,Signature

# 3. إزالة جميع رسائل السجلات والتصحيح بالكامل لمنع تسريب أي معلومات (Strip Logs)
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
}

# 4. الحفاظ على نقاط ربط محرك فلاتر الأساسية (Flutter Engine & Plugins Bridge)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 5. الحفاظ على دوال الـ Native (JNI methods)
-keepclasseswithmembernames class * {
    native <methods>;
}

# 6. الحفاظ على مكتبات التشفير والـ PointyCastle و Crypto
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**
-keep class com.google.crypto.tink.** { *; }

# 7. منع إظهار تحذيرات المكتبات الخارجية غير المؤثرة
-dontwarn io.flutter.**
-dontwarn javax.annotation.**
