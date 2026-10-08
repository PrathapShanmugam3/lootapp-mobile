import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette — flat, minimal system (Linear/Notion-style). One accent
/// color used sparingly for interactive elements; everything else is
/// near-white surfaces, hairline borders and high-contrast ink. No
/// gradients, no colored shadows — every screen should pull from here
/// rather than hard-coding hex values.
class AppColors {
  AppColors._();

  // Legacy web tokens (lootapp-ui globals.css) — still referenced in places.
  static const gradientStart = Color(0xFF8B5CF6);
  static const gradientEnd = Color(0xFF3B82F6);
  static const primaryDeep = Color(0xFF4F46E5);
  static const gradientStartDark = Color(0xFFA78BFA);
  static const gradientEndDark = Color(0xFF60A5FA);

  /// Single accent — used for selection states, links, primary actions.
  /// Deliberately restrained: most of the UI should read in ink/surface.
  static const primary = Color(0xFF5B4FE8);
  static const violet = primary; // alias kept for existing call sites
  static const primaryMuted = Color(0xFFEEECFD);

  // Surfaces — flat, near-white. No tinted "card gradient" surfaces.
  static const canvas = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const surfaceTint = Color(0xFFF5F5F6);
  static const hairline = Color(0xFFE7E7EA);
  static const hairlineStrong = Color(0xFFD8D8DD);

  // Ink — neutral greys, not purple-tinted.
  static const ink = Color(0xFF17171C);
  static const inkLabel = Color(0xFF3A3A42);
  static const inkMuted = Color(0xFF6B6B74);
  static const inkFaint = Color(0xFF9B9BA3);

  // Semantic.
  static const success = Color(0xFF16A34A);
  static const successMuted = Color(0xFFE8F6ED);
  static const danger = Color(0xFFDC2626);
  static const dangerMuted = Color(0xFFFCEAEA);
  static const warning = Color(0xFFB45309);
  static const warningMuted = Color(0xFFFCF3E4);

  /// Flat accent fill — used only where a single solid block of color is
  /// intentional (primary button, selected nav icon). No gradients.
  static const Color accentFill = primary;

  // --- Deprecated gradient tokens, kept only so any stray reference still
  // compiles; nothing new should use these. All resolve to flat colors.
  static const LinearGradient heroGradient = LinearGradient(colors: [ink, ink]);
  static const LinearGradient cardGradient = LinearGradient(colors: [primary, primary]);
  static const LinearGradient buttonGradient = LinearGradient(colors: [primary, primary]);
  static const LinearGradient brandGradient = cardGradient;
  static const plum = ink;
  static const magenta = primary;
  static const orchid = primary;
  static const pink = Color(0xFFDB2777);
  static const amber = Color(0xFFB45309);
  static const mint = success;

  /// Minimal 1px elevation — a hairline border plus a whisper of shadow.
  /// Use instead of colored glows.
  static List<BoxShadow> softShadow([double strength = 1]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04 * strength),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  /// No-op kept for call-site compatibility — flat design uses borders, not
  /// colored glows, so this returns an empty shadow list.
  static List<BoxShadow> glow(Color color, [double strength = 1]) => const [];
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
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

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.gradientStartDark,
      brightness: Brightness.dark,
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
    final isLight = scheme.brightness == Brightness.light;
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final radius = BorderRadius.circular(10);

    return base.copyWith(
      scaffoldBackgroundColor: isLight ? AppColors.canvas : scheme.surface,
      textTheme: _textTheme(base.textTheme, isLight ? AppColors.ink : scheme.onSurface),
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
        backgroundColor: isLight ? AppColors.canvas : scheme.surface,
        foregroundColor: isLight ? AppColors.ink : scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: isLight ? AppColors.ink : scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5),
        color: isLight ? Colors.white : scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isLight ? AppColors.hairline : Colors.transparent),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: AppColors.inkMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontWeight: FontWeight.w400),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? AppColors.primary : AppColors.inkFaint,
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.hairlineStrong)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.hairlineStrong)),
        focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.danger)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.danger, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(64, 44),
          side: const BorderSide(color: AppColors.hairlineStrong, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
        selectedColor: AppColors.primaryMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.hairline)),
        side: const BorderSide(color: AppColors.hairline),
        checkmarkColor: AppColors.primary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.ink,
        unselectedLabelColor: AppColors.inkFaint,
        indicatorColor: AppColors.ink,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: AppColors.hairline,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.hairlineStrong,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.hairline,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: AppColors.hairlineStrong, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.ink : null,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.ink : AppColors.hairlineStrong,
        ),
      ),
    );
  }
}
