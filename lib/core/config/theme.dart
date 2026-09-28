import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────

class AppColors {
  // ── Royal Warm Champagne Gold Accent Palette ──
  static const Color gold = Color(0xFFF59E0B);          // Luminous Warm Champagne Gold
  static const Color goldDark = Color(0xFFD97706);      // Deep Burnished Amber Gold
  static const Color goldLight = Color(0xFFFDE68A);     // Soft Champagne Light Glow
  static const Color goldBronze = Color(0xFFB45309);    // Rich Deep Bronze
  static const Color goldShimmer = Color(0xFFFEF3C7);   // Sparkling Champagne Tint

  // ── Midnight Obsidian Dark Mode ──
  static const Color darkBg = Color(0xFF080C14);        // Deepest Obsidian OLED Canvas
  static const Color darkCard = Color(0xFF0F172A);      // Slate Obsidian Card
  static const Color darkSurface = Color(0xFF162032);   // Elevated Slate-Navy Surface
  static const Color darkBorder = Color(0xFF1E293B);    // Refined Border
  static const Color darkBorderGold = Color(0x33F59E0B);// Subtle Gold Micro-Border

  // ── Pearl White Light Mode ──
  static const Color lightBg = Color(0xFFF8FAFC);       // Modern Pearl Porcelain Canvas
  static const Color lightCard = Color(0xFFFFFFFF);     // Pure Alabaster White Card
  static const Color lightSurface = Color(0xFFF1F5F9);  // Soft Warm Pearl Surface
  static const Color lightBorder = Color(0xFFE2E8F0);   // Clean Modern Border
  static const Color lightBorderGold = Color(0x2BD97706);// Subtle Warm Amber Border

  // ── Premium Typography Colors ──
  static const Color textDark = Color(0xFF0F172A);              // Deep Obsidian Text
  static const Color textDarkSecondary = Color(0xFF64748B);     // Cool Slate Gray Text
  static const Color textLight = Color(0xFFF8FAFC);             // Pure Pearl Light Text
  static const Color textLightSecondary = Color(0xFF94A3B8);    // Soft Silver Slate Text

  // ── Status Colors (Modern Vibrant) ──
  static const Color error = Color(0xFFEF4444);        // Vibrant Rose Crimson
  static const Color success = Color(0xFF10B981);      // Emerald Green
  static const Color warning = Color(0xFFF59E0B);      // Champagne Amber
  static const Color info = Color(0xFF38BDF8);         // Sky Ice Blue
}

// ─── Border Radii ────────────────────────────────────────────────────────────

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 100;

  static BorderRadius get xsBr => BorderRadius.circular(xs);
  static BorderRadius get smBr => BorderRadius.circular(sm);
  static BorderRadius get mdBr => BorderRadius.circular(md);
  static BorderRadius get lgBr => BorderRadius.circular(lg);
  static BorderRadius get xlBr => BorderRadius.circular(xl);
  static BorderRadius get pillBr => BorderRadius.circular(pill);
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─── Gradients ───────────────────────────────────────────────────────────────

class AppGradients {
  // Ultra-Rich Shimmering Champagne Gold Gradient
  static const LinearGradient gold = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldSubtle = LinearGradient(
    colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient goldLuxe = LinearGradient(
    colors: [Color(0xFFFFFBEB), Color(0xFFFCD34D), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Modern Card Gradients (Subtle glass backdrop effect)
  static const LinearGradient darkCard = LinearGradient(
    colors: [Color(0xFF151E33), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCard = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient card(BuildContext context) {
    return context.isDark ? darkCard : lightCard;
  }

  // Solid background gradients
  static LinearGradient darkBg = const LinearGradient(
    colors: [Color(0xFF080C14), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient lightBg = const LinearGradient(
    colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient background(BuildContext context) {
    return context.isDark ? darkBg : lightBg;
  }
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    if (context.isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 1),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.02),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> get goldGlow => [
    BoxShadow(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.38),
      blurRadius: 24,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> elevated(BuildContext context) {
    if (context.isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.65),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
          blurRadius: 15,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.08),
        blurRadius: 28,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

// ─── Theme Data ──────────────────────────────────────────────────────────────

class AppTheme {
  static TextTheme _buildTextTheme(
    TextTheme base,
    Color primary,
    Color secondary,
  ) {
    return GoogleFonts.tajawalTextTheme(base).copyWith(
      displayLarge: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      displayMedium: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      displaySmall: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
      titleMedium: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleSmall: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      bodyLarge: GoogleFonts.tajawal(color: primary, fontSize: 16),
      bodyMedium: GoogleFonts.tajawal(color: primary, fontSize: 14),
      bodySmall: GoogleFonts.tajawal(color: secondary, fontSize: 12),
      labelLarge: GoogleFonts.tajawal(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      labelMedium: GoogleFonts.tajawal(color: primary, fontSize: 12),
      labelSmall: GoogleFonts.tajawal(color: secondary, fontSize: 11),
    );
  }

  // ── Dark Theme ──────────────────────────────────────────────────────

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gold,
        secondary: AppColors.goldLight,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: Color(0xFF080C14),
        onSecondary: Color(0xFF080C14),
        outline: AppColors.darkBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          color: AppColors.textLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: const Color(0xFF080C14),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.tajawal(color: AppColors.textLightSecondary),
        hintStyle: GoogleFonts.tajawal(color: AppColors.textLightSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
        color: AppColors.darkCard,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBr),
        backgroundColor: AppColors.darkCard,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.tajawal(
          color: AppColors.textLight,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textLightSecondary,
        selectedLabelStyle: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.darkBorder,
      textTheme: _buildTextTheme(
        base.textTheme,
        AppColors.textLight,
        AppColors.textLightSecondary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkCard,
        contentTextStyle: GoogleFonts.tajawal(color: AppColors.textLight),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBr),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.goldDark,
        secondary: AppColors.gold,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        outline: AppColors.lightBorder,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.tajawal(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          side: const BorderSide(color: AppColors.goldDark, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
          textStyle: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          textStyle: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.goldDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBr,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: GoogleFonts.tajawal(color: AppColors.textDarkSecondary),
        hintStyle: GoogleFonts.tajawal(color: AppColors.textDarkSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
        color: AppColors.lightCard,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBr),
        backgroundColor: AppColors.lightCard,
        selectedColor: AppColors.goldDark.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.tajawal(
          color: AppColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: AppColors.goldDark,
        unselectedItemColor: AppColors.textDarkSecondary,
        selectedLabelStyle: GoogleFonts.tajawal(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.tajawal(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
      dividerColor: AppColors.lightBorder,
      textTheme: _buildTextTheme(
        base.textTheme,
        AppColors.textDark,
        AppColors.textDarkSecondary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightCard,
        contentTextStyle: GoogleFonts.tajawal(color: AppColors.textDark),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smBr),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Context Extensions ──────────────────────────────────────────────────────

extension ThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  Color get cardColor => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get surfaceColor =>
      isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get bgColor => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get textPrimary => isDark ? AppColors.textLight : AppColors.textDark;
  Color get textSecondary =>
      isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
  Color get accentColor => isDark ? AppColors.gold : AppColors.goldDark;
  LinearGradient get goldGradient => AppGradients.gold;
}

