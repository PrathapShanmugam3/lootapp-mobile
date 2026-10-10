import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette — "1a Polished Violet" (LootHat Redesign). Vivid violet →
/// magenta gradients, a lavender page, white rounded cards with soft violet
/// shadows, Plus Jakarta Sans for text and Space Grotesk for numbers.
/// Which colour set the app is drawing with. Flipped by [ThemeController]
/// (see main.dart), which then rebuilds the whole tree so every token getter
/// below is re-read.
class Palette {
  Palette._();

  static bool dark = false;
}

class AppColors {
  AppColors._();

  // Legacy web tokens (lootapp-ui globals.css) — still referenced in places.
  static const gradientStart = Color(0xFF8B5CF6);
  static const gradientEnd = Color(0xFF3B82F6);
  static const primaryDeep = Color(0xFF6D28D9);
  static const gradientStartDark = Color(0xFFA78BFA);
  static const gradientEndDark = Color(0xFF60A5FA);

  /// Brand violet — selection states, links, primary actions.
  static const primary = Color(0xFF7C3AED);
  static const violet = primary; // alias kept for existing call sites
  static Color get primaryMuted => Palette.dark ? const Color(0xFF2D2150) : const Color(0xFFEDE9FE);

  /// Warm highlight for notification dots and sparkles.
  static const gold = Color(0xFFFACC15);
  static Color get goldMuted => Palette.dark ? const Color(0xFF33280F) : const Color(0xFFFEF3C7);

  // Vivid accents used sparingly (conversions chip, earnings chip, …).
  static const pinkAccent = Color(0xFFEC4899);
  static const cyan = Color(0xFF22D3EE);
  static const emerald = Color(0xFF10B981);
  static const orange = Color(0xFFF59E0B);

  // Dark tones (snackbars, overlays).
  static const midnight = Color(0xFF1C1235);
  static const midnightSoft = Color(0xFF3D3456);

  // Surfaces — lavender page, white cards.
  static Color get canvas => Palette.dark ? const Color(0xFF0F0B1A) : const Color(0xFFF6F4FF);
  static Color get surface => Palette.dark ? const Color(0xFF1A1428) : Colors.white;
  static Color get surfaceTint => Palette.dark ? const Color(0xFF221B35) : const Color(0xFFF1EDFA);
  static Color get hairline => Palette.dark ? const Color(0xFF261F3A) : const Color(0xFFF1EDFA);
  static Color get fieldBg => Palette.dark ? const Color(0xFF211A33) : const Color(0xFFFAF9FF);
  static Color get hairlineStrong => Palette.dark ? const Color(0xFF2E2645) : const Color(0xFFE6E0F5);

  // Ink — violet-tinted neutrals.
  static Color get ink => Palette.dark ? const Color(0xFFF3F0FF) : const Color(0xFF1C1235);
  static Color get inkLabel => Palette.dark ? const Color(0xFFD9D3EE) : const Color(0xFF3D3456);
  static Color get inkMuted => Palette.dark ? const Color(0xFFA9A0C6) : const Color(0xFF6B6285);
  static Color get inkFaint => Palette.dark ? const Color(0xFF8C84AA) : const Color(0xFF8B82A8);
  static Color get inkHint => Palette.dark ? const Color(0xFF7A7298) : const Color(0xFF9A92B4);

  // Semantic.
  static const success = Color(0xFF16A34A);
  static Color get successMuted => Palette.dark ? const Color(0xFF0F2A22) : const Color(0xFFECFDF5);
  static const danger = Color(0xFFE11D48);
  static Color get dangerMuted => Palette.dark ? const Color(0xFF3A1520) : const Color(0xFFFFE4E9);
  static const warning = Color(0xFFD97706);
  static Color get warningMuted => Palette.dark ? const Color(0xFF33280F) : const Color(0xFFFEF3C7);

  /// Button / chip gradient (violet → lilac).
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
  );

  /// Header / hero gradient (violet → purple → magenta, 120deg).
  static const LinearGradient midnightGradient = LinearGradient(
    begin: Alignment(-1, -0.6),
    end: Alignment(1, 0.6),
    colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFC026D3)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary call-to-action gradient.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment(-1, -0.6),
    end: Alignment(1, 0.6),
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFC026D3)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Flat accent fill — kept for call-site compatibility.
  static const Color accentFill = primary;

  // Gradient tokens (several screens still reference these names).
  static const LinearGradient heroGradient = midnightGradient;
  static const LinearGradient cardGradient = accentGradient;
  static const LinearGradient buttonGradient = ctaGradient;
  static const LinearGradient brandGradient = accentGradient;
  static Color get plum => ink;
  static const magenta = Color(0xFFC026D3);
  static const orchid = primary;
  static const pink = Color(0xFFDB2777);
  static const amber = Color(0xFFD97706);
  static const mint = success;

  /// Card elevation from the design: 0 4px 16px rgba(60,20,120,.08).
  static List<BoxShadow> softShadow([double strength = 1]) => [
        BoxShadow(
          color: (Palette.dark ? Colors.black : const Color(0xFF3C1478)).withValues(alpha: (Palette.dark ? 0.35 : 0.08) * strength),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Soft colored glow under an accent element (buttons, active chips).
  static List<BoxShadow> glow(Color color, [double strength = 1]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.38 * strength),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ];
}

class AppTheme {
  AppTheme._();

  /// Theme for whichever [Palette] is active — the colour tokens are
  /// already light/dark aware, so one builder covers both.
  static ThemeData current() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Palette.dark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      outlineVariant: AppColors.hairline,
      error: AppColors.danger,
    );
    return _build(scheme);
  }

  static TextTheme _textTheme(TextTheme base, Color ink) {
    TextStyle? t(TextStyle? s, double size, FontWeight w, {double ls = 0, double? h}) =>
        s?.copyWith(fontSize: size, fontWeight: w, letterSpacing: ls, height: h, color: ink);
    return base.copyWith(
      displaySmall: t(base.displaySmall, 32, FontWeight.w700, ls: -0.6),
      headlineMedium: t(base.headlineMedium, 26, FontWeight.w700, ls: -0.4),
      headlineSmall: t(base.headlineSmall, 22, FontWeight.w700, ls: -0.3),
      titleLarge: t(base.titleLarge, 18, FontWeight.w700, ls: -0.2),
      titleMedium: t(base.titleMedium, 15, FontWeight.w600, ls: -0.1),
      titleSmall: t(base.titleSmall, 13.5, FontWeight.w600),
      bodyLarge: t(base.bodyLarge, 15, FontWeight.w400, h: 1.45),
      bodyMedium: t(base.bodyMedium, 14, FontWeight.w400, h: 1.45),
      labelLarge: t(base.labelLarge, 14, FontWeight.w600, ls: 0),
    );
  }

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'PlusJakartaSans');
    final radius = BorderRadius.circular(15);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: _textTheme(base.textTheme, AppColors.ink),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: Palette.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.hairline),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: AppColors.inkMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        hintStyle: TextStyle(color: AppColors.inkHint, fontWeight: FontWeight.w500),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? AppColors.primary : AppColors.inkHint,
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.hairlineStrong, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AppColors.hairlineStrong, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 46),
          side: BorderSide(color: AppColors.hairlineStrong, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primaryMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: BorderSide(color: AppColors.hairline)),
        side: BorderSide(color: AppColors.hairline),
        checkmarkColor: AppColors.primary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkFaint,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: AppColors.hairline,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.hairlineStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.dark ? const Color(0xFF2D2150) : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          side: WidgetStatePropertyAll(BorderSide(color: AppColors.hairlineStrong)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primaryMuted : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.inkMuted,
          ),
          textStyle: const WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.hairline,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: BorderSide(color: AppColors.hairlineStrong, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : null,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.primary : AppColors.hairlineStrong,
        ),
      ),
    );
  }
}
