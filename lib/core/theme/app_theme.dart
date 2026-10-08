import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Brand palette — "Midnight Violet". Deep indigo ink, a vivid violet accent
/// with a warm gold highlight for money/rewards, cool lavender-tinted
/// surfaces and layered soft shadows. Every screen should pull from here
/// rather than hard-coding hex values.
class AppColors {
  AppColors._();

  // Legacy web tokens (lootapp-ui globals.css) — still referenced in places.
  static const gradientStart = Color(0xFF8B5CF6);
  static const gradientEnd = Color(0xFF3B82F6);
  static const primaryDeep = Color(0xFF4A2FD0);
  static const gradientStartDark = Color(0xFFA78BFA);
  static const gradientEndDark = Color(0xFF60A5FA);

  /// Brand accent — selection states, links, primary actions.
  static const primary = Color(0xFF6C4DF6);
  static const violet = primary; // alias kept for existing call sites
  static const primaryMuted = Color(0xFFF0ECFF);

  /// Warm highlight reserved for money, rewards and "premium" moments.
  static const gold = Color(0xFFF5B942);
  static const goldMuted = Color(0xFFFFF4DC);

  // Midnight surfaces used for hero blocks, nav and the login header.
  static const midnight = Color(0xFF110C2E);
  static const midnightSoft = Color(0xFF1E1550);

  // Surfaces — cool lavender-tinted whites.
  static const canvas = Color(0xFFF7F6FC);
  static const surface = Colors.white;
  static const surfaceTint = Color(0xFFF3F1FA);
  static const hairline = Color(0xFFEAE7F4);
  static const hairlineStrong = Color(0xFFDAD6EA);

  // Ink — deep indigo-tinted neutrals.
  static const ink = Color(0xFF14112B);
  static const inkLabel = Color(0xFF38345A);
  static const inkMuted = Color(0xFF6A6688);
  static const inkFaint = Color(0xFF9C99B6);

  // Semantic.
  static const success = Color(0xFF12A150);
  static const successMuted = Color(0xFFE5F7EC);
  static const danger = Color(0xFFE0343A);
  static const dangerMuted = Color(0xFFFDEBEC);
  static const warning = Color(0xFFC2650A);
  static const warningMuted = Color(0xFFFFF1DF);

  /// Brand gradient — primary buttons, selected tab, avatar chips.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF5B3DF0)],
  );

  /// Deep hero gradient — headers, login banner, balance cards.
  static const LinearGradient midnightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1550), Color(0xFF3A22A8), Color(0xFF6C4DF6)],
    stops: [0.0, 0.62, 1.0],
  );

  /// Flat accent fill — kept for call-site compatibility.
  static const Color accentFill = primary;

  // Gradient tokens (several screens still reference these names).
  static const LinearGradient heroGradient = midnightGradient;
  static const LinearGradient cardGradient = accentGradient;
  static const LinearGradient buttonGradient = accentGradient;
  static const LinearGradient brandGradient = accentGradient;
  static const plum = ink;
  static const magenta = primary;
  static const orchid = primary;
  static const pink = Color(0xFFDB2777);
  static const amber = Color(0xFFB45309);
  static const mint = success;

  /// Layered elevation — a tight contact shadow plus a wide, violet-tinted
  /// ambient one. Reads as "lifted" without looking heavy.
  static List<BoxShadow> softShadow([double strength = 1]) => [
        BoxShadow(
          color: const Color(0xFF1E1550).withValues(alpha: 0.05 * strength),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: const Color(0xFF3A22A8).withValues(alpha: 0.08 * strength),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Soft colored glow under an accent element (buttons, active chips).
  static List<BoxShadow> glow(Color color, [double strength = 1]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.32 * strength),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
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
    final radius = BorderRadius.circular(14);

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
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isLight ? AppColors.hairline : Colors.transparent),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: AppColors.inkMuted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? const Color(0xFFFBFAFE) : scheme.surfaceContainerHighest,
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontWeight: FontWeight.w400),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? AppColors.primary : AppColors.inkFaint,
        ),
        border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.hairlineStrong)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.hairlineStrong)),
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
          side: const BorderSide(color: AppColors.hairlineStrong, width: 1.2),
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
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? Colors.white : scheme.surfaceContainerHighest,
        selectedColor: AppColors.primaryMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999), side: const BorderSide(color: AppColors.hairline)),
        side: const BorderSide(color: AppColors.hairline),
        checkmarkColor: AppColors.primary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.inkFaint,
        indicatorColor: AppColors.primary,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnight,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
