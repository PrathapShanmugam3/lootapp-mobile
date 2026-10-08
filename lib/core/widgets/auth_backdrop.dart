import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'common.dart' show DecorativeOrbs;

/// Midnight-violet gradient cap behind the floating white card used by the
/// auth screens (forgot / reset password), matching the login header.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Stack(children: const [Positioned.fill(child: DecorativeOrbs(scale: 1.4))]),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
