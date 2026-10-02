/// محرك الأمان الرقمي ومكافحة الاختراق وحقن البيانات (Security & Sanitization Engine)
class SecuritySanitizer {
  SecuritySanitizer._();

  /// تنظيف النصوص ومنع حقن الاستعلامات (SQL Injection Sanitizer)
  static String sanitizeSql(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll("'", "''")
        .replaceAll(";", "")
        .replaceAll("--", "")
        .replaceAll("/*", "")
        .replaceAll("*/", "")
        .replaceAll("xp_", "")
        .trim();
  }

  /// تنظيف النصوص ومنع هجمات البرمجة عبر المواقع (XSS Prevention)
  static String sanitizeXss(String input) {
    if (input.isEmpty) return '';
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// التحقق من أمان وصلاحية الملفات المرفوعة (File Upload Security Validator)
  static bool isAllowedImageFile(String filename, int fileSizeBytes) {
    const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
    if (fileSizeBytes > maxSizeBytes) return false;

    final lower = filename.toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return allowedExtensions.any((ext) => lower.endsWith(ext));
  }

  /// فحص محاولات تسريب أرقام الهواتف أو الالتفاف (Anti-Bypass Filter)
  static bool containsHiddenPhoneNumber(String text) {
    // Egyptian phone numbers pattern: 010, 011, 012, 015 followed by 8 digits
    final regex = RegExp(r'(01[0125][0-9]{8})');
    return regex.hasMatch(text.replaceAll(RegExp(r'\s+'), ''));
  }
}
