import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../../core/widgets/common.dart' show PressableScale, ShineSweep;

/// "1a Polished Violet" — the LootHat Redesign design system for the
/// Affiliate (User) portal. Violet → magenta gradients, a lavender page,
/// white rounded cards with soft violet shadows, Plus Jakarta Sans for text
/// and Space Grotesk for numbers.
class AffColors {
  AffColors._();

  // --- Brand violets (names kept for existing call sites) ---
  static const purpleStart = Color(0xFFA855F7); // lilac
  static const purpleEnd = Color(0xFF7C3AED); // brand violet
  static const violetDeep = Color(0xFF6D28D9);
  static const purple = Color(0xFF9333EA);
  static const magenta = Color(0xFFC026D3);
  static const fuchsia = Color(0xFFD946EF);

  // --- Vivid accents ---
  static const pink = Color(0xFFEC4899);
  static const rose = Color(0xFFF43F5E);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFBBF24);
  static const cyan = Color(0xFF22D3EE);
  static const emerald = Color(0xFF10B981);
  static const orange = Color(0xFFFF8A3D);
  static const gold = Color(0xFFFACC15); // notification dot
  static const goldSoft = Color(0xFFFDE68A);

  // --- Dark tones ---
  static const midnight = Color(0xFF1C1235);
  static const midnightSoft = Color(0xFF3D3456);

  // --- Surfaces & ink ---
  static const pageBg = Color(0xFFF6F4FF);
  static const ink = Color(0xFF1C1235);
  static const inkLabel = Color(0xFF3D3456);
  static const inkMuted = Color(0xFF6B6285);
  static const inkFaint = Color(0xFF8B82A8);
  static const inkHint = Color(0xFF9A92B4);
  static const hairline = Color(0xFFF1EDFA);
  static const fieldBorder = Color(0xFFE6E0F5);
  static const fieldBg = Color(0xFFFAF9FF);
  static const chipLilac = Color(0xFFEDE9FE);
  static const chipPink = Color(0xFFFCE7F3);

  // --- Semantic ---
  static const success = Color(0xFF16A34A);
  static const live = Color(0xFF059669);
  static const liveBg = Color(0xFFECFDF5);
  static const danger = Color(0xFFE11D48);
  static const warning = Color(0xFFD97706);

  // --- Gradients (CSS 120deg ≈ left→right with a slight downward tilt) ---
  static const _tiltStart = Alignment(-1, -0.6);
  static const _tiltEnd = Alignment(1, 0.6);

  /// Violet → lilac: buttons, avatars, icon chips.
  static const gradient = LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [purpleEnd, purpleStart]);

  /// Header: 6d28d9 → 9333ea (55%) → c026d3.
  static const heroGradient = LinearGradient(begin: _tiltStart, end: _tiltEnd, colors: [violetDeep, purple, magenta], stops: [0, 0.55, 1]);

  /// Welcome / profile hero: 7c3aed → a855f7 (60%) → d946ef.
  static const welcomeGradient = LinearGradient(begin: _tiltStart, end: _tiltEnd, colors: [purpleEnd, purpleStart, fuchsia], stops: [0, 0.6, 1]);

  /// Wallet balance card: db2777 → 9333ea (55%) → 6d28d9.
  static const walletGradient = LinearGradient(begin: _tiltStart, end: _tiltEnd, colors: [Color(0xFFDB2777), purple, violetDeep], stops: [0, 0.55, 1]);

  /// Primary call-to-action: 7c3aed → 9333ea (55%) → c026d3.
  static const ctaGradient = LinearGradient(begin: _tiltStart, end: _tiltEnd, colors: [purpleEnd, purple, magenta], stops: [0, 0.55, 1]);

  /// Nav pill: 135deg 7c3aed → c026d3.
  static const pillGradient = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [purpleEnd, magenta]);

  /// Card elevation: 0 4px 16px rgba(60,20,120,.08).
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6)),
  ];

  // --- Vivid per-item palette (offer / campaign avatars, buttons, chips) ---
  // Each entry: [light, strong, tint-bg, tint-fg]
  static const _palette = [
    (a: Color(0xFFA855F7), b: Color(0xFF7C3AED), bg: Color(0xFFEDE9FE), fg: Color(0xFF7C3AED)), // violet
    (a: Color(0xFFF472B6), b: Color(0xFFE11D74), bg: Color(0xFFFCE7F3), fg: Color(0xFFDB2777)), // pink
    (a: Color(0xFFFBBF24), b: Color(0xFFF97316), bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706)), // amber → orange
    (a: Color(0xFF34D399), b: Color(0xFF059669), bg: Color(0xFFD1FAE5), fg: Color(0xFF059669)), // emerald
    (a: Color(0xFF38BDF8), b: Color(0xFF2563EB), bg: Color(0xFFE0F2FE), fg: Color(0xFF0284C7)), // sky → blue
    (a: Color(0xFF818CF8), b: Color(0xFF4F46E5), bg: Color(0xFFE0E7FF), fg: Color(0xFF4F46E5)), // indigo
  ];

  static int _hash(String seed) {
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static ({Color a, Color b, Color bg, Color fg}) _pick(String seed) => _palette[_hash(seed) % _palette.length];

  /// Stable pale chip colours for [seed] (tinted bg + strong text).
  static ({Color bg, Color fg}) tintFor(String seed) {
    final c = _pick(seed);
    return (bg: c.bg, fg: c.fg);
  }

  /// Stable accent colour for [seed].
  static Color colorFor(String seed) => _pick(seed).b;

  /// Stable vivid gradient for [seed] — avatars and per-item buttons.
  static LinearGradient gradientFor(String seed) {
    final c = _pick(seed);
    return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.a, c.b]);
  }
}

/// Text styles from the design: Plus Jakarta Sans for copy, Space Grotesk
/// for numbers, amounts and timestamps.
class AffText {
  AffText._();

  static TextStyle jakarta(double size, FontWeight weight, {Color color = AffColors.ink, double? letterSpacing, double? height}) =>
      TextStyle(fontFamily: 'PlusJakartaSans', fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);

  static TextStyle number(double size, FontWeight weight, {Color color = AffColors.ink, double? letterSpacing, double? height}) =>
      TextStyle(fontFamily: 'SpaceGrotesk', fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);
}

/// Flat gradient app header shared by every affiliate screen: title,
/// "LootHat Affiliate" subtitle, bell + avatar actions.
class AffHeader extends StatelessWidget implements PreferredSizeWidget {
  const AffHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Container(
      decoration: BoxDecoration(
        gradient: AffColors.heroGradient,
        boxShadow: [BoxShadow(color: AffColors.violetDeep.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: Stack(
        children: [
          // Soft light in the top-right corner for depth.
          Positioned(
            top: -70,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0)], stops: const [0, 0.7]),
                ),
              ),
            ),
          ),
          // 1px highlight along the bottom edge.
          Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 1, color: Colors.white.withValues(alpha: 0.18))),
          SafeArea(
        bottom: false,
        child: SizedBox(
          height: 74,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                if (automaticallyImplyLeading && canPop)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AffText.jakarta(21, FontWeight.w800, color: Colors.white, letterSpacing: -0.4, height: 1.05),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AffText.jakarta(11, FontWeight.w500, color: Colors.white.withValues(alpha: 0.75), height: 1),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

/// 38×38 rounded-13 glass icon button for the header (notification bell…),
/// with an optional pulsing yellow dot.
class AffHeaderIcon extends StatelessWidget {
  const AffHeaderIcon({super.key, required this.icon, required this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(13)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              if (showDot) const Positioned(top: 8, right: 9, child: PulseDot(color: AffColors.gold, size: 7)),
            ],
          ),
        ),
      ),
    );
  }
}

/// White circular initials avatar for the header (violet Space Grotesk).
class AffHeaderAvatar extends StatelessWidget {
  const AffHeaderAvatar({super.key, required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: Text(initials, style: AffText.number(14, FontWeight.w800, color: AffColors.purpleEnd)),
        ),
      ),
    );
  }
}

/// Small dot that pulses (scale 1 → 1.55, fading) — the "live" indicator.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value < 0.5 ? _c.value * 2 : (1 - _c.value) * 2);
        return Transform.scale(
          scale: 1 + 0.55 * t,
          child: Opacity(
            opacity: 1 - 0.75 * t,
            child: Container(width: widget.size, height: widget.size, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
          ),
        );
      },
    );
  }
}

/// Gradient hero card (welcome banner, profile, wallet balance) with the
/// design's gliding shimmer.
class AffHeroCard extends StatelessWidget {
  const AffHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    this.gradient = AffColors.welcomeGradient,
    this.radius = 22,
    this.shimmer = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;
  final double radius;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final base = (gradient is LinearGradient) ? (gradient as LinearGradient).colors[1] : AffColors.purpleEnd;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: base.withValues(alpha: 0.32), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            if (shimmer) const Positioned.fill(child: ShineSweep(duration: Duration(milliseconds: 3600), strength: 0.28)),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// White rounded card with the design's soft violet shadow — the base
/// surface for stat tiles, lists and forms. Tappable cards sink slightly
/// under the finger.
class AffCard extends StatelessWidget {
  const AffCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.radius = 20, this.wash});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  /// Optional colour wash: a soft tint of this colour fading in from the
  /// top-right corner of the white card.
  final Color? wash;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: wash == null ? Colors.white : null,
        gradient: wash == null
            ? null
            : RadialGradient(center: Alignment.topRight, radius: 0.95, colors: [wash!.withValues(alpha: 0.13), Colors.white], stops: const [0, 1]),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AffColors.purpleEnd.withValues(alpha: 0.07)),
        boxShadow: AffColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
    return onTap == null ? card : PressableScale(onTap: onTap, scale: 0.975, child: card);
  }
}

/// Rounded-square icon chip. [solid] = gradient fill with a white icon (the
/// design's stat-tile chips); otherwise a soft tint of [color].
class AffIconChip extends StatelessWidget {
  const AffIconChip({super.key, required this.icon, this.color = AffColors.purpleEnd, this.size = 34, this.solid = false});

  final IconData icon;
  final Color color;
  final double size;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: solid ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(color, Colors.white, 0.22)!, color]) : null,
        color: solid ? null : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
        border: solid ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1) : null,
        boxShadow: solid ? [BoxShadow(color: color.withValues(alpha: 0.38), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Icon(icon, color: solid ? Colors.white : color, size: size * 0.48),
    );
  }
}

/// One destination in [AffNavBar].
class AffNavItem {
  const AffNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.from = AffColors.purpleEnd,
    this.to = AffColors.magenta,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Gradient of the sliding pill while this tab is selected.
  final Color from;
  final Color to;
}

/// Floating glass tab bar from the design: 68px tall, radius 26, frosted
/// white, with a gradient pill that springs between the five destinations.
class AffNavBar extends StatelessWidget {
  const AffNavBar({super.key, required this.items, required this.selectedIndex, required this.onSelected});

  final List<AffNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const pillW = 60.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                color: Colors.white.withValues(alpha: 0.92),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final itemW = c.maxWidth / items.length;
                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 380),
                          curve: const Cubic(0.34, 1.5, 0.5, 1),
                          top: 8,
                          left: selectedIndex * itemW + (itemW - pillW) / 2,
                          width: pillW,
                          height: 52,
                          child: TweenAnimationBuilder<Color?>(
                            tween: ColorTween(end: items[selectedIndex].from),
                            duration: const Duration(milliseconds: 380),
                            builder: (context, from, _) => TweenAnimationBuilder<Color?>(
                              tween: ColorTween(end: items[selectedIndex].to),
                              duration: const Duration(milliseconds: 380),
                              builder: (context, to, _) => Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [from ?? AffColors.purpleEnd, to ?? AffColors.magenta]),
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [BoxShadow(color: (from ?? AffColors.purpleEnd).withValues(alpha: 0.42), blurRadius: 18, offset: const Offset(0, 8))],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(child: _AffNavButton(item: items[i], selected: i == selectedIndex, onTap: () => onSelected(i))),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AffNavButton extends StatelessWidget {
  const _AffNavButton({required this.item, required this.selected, required this.onTap});

  final AffNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AffColors.inkFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(selected ? item.selectedIcon : item.icon, size: 20, color: color),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: AffText.jakarta(9.5, FontWeight.w700, color: color),
              child: Text(item.label, maxLines: 1, softWrap: false, overflow: TextOverflow.fade),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section header: bold title + optional "View all →" link.
class AffSectionHeader extends StatelessWidget {
  const AffSectionHeader({super.key, required this.title, this.action, this.onActionTap});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 15,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AffColors.purpleStart, AffColors.magenta]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(15, FontWeight.w800))),
              ],
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text('$action →', style: AffText.jakarta(11, FontWeight.w600, color: AffColors.purpleEnd)),
              ),
            ),
        ],
      ),
    );
  }
}
