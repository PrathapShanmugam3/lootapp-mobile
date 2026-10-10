import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's Light / Dark choice (light by default), persisted across launches.
class ThemeController extends Notifier<ThemeMode> {
  static const _prefsKey = 'theme_mode';

  /// Loaded in main() before runApp so the first frame already uses the
  /// saved mode (no light→dark flash on launch).
  static ThemeMode _initial = ThemeMode.light;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only an explicit "dark" turns dark on — anything else (unset, or a
      // "system" saved by an earlier build) falls back to light.
      _initial = prefs.getString(_prefsKey) == ThemeMode.dark.name ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      _initial = ThemeMode.light;
    }
  }

  @override
  ThemeMode build() => _initial;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {}
  }
}

final themeModeProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
