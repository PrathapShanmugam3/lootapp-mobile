import 'package:flutter/material.dart';

import '../../../../core/widgets/common.dart' show DecorativeOrbs;

/// "Midnight Violet" design system for the Affiliate (User) portal — scoped
/// to this feature so it never touches the shared theme used by
/// Manager/Admin. Deep indigo header + hero surfaces with soft glows, a gold
/// accent for money, lavender page background, white rounded-22 cards with
/// layered shadows, and a floating midnight pill nav with a glowing Profile
/// button.
class AffColors {
  AffColors._();

  // Brand violet (names kept for existing call sites).
  static const purpleStart = Color(0xFF8B5CF6);
  static const purpleEnd = Color(0xFF5B3DF0);

  // Midnight tones for the header, hero and nav.
  static const midnight = Color(0xFF110C2E);
  static const midnightSoft = Color(0xFF1E1550);

  /// Warm highlight for money / rewards.
  static const gold = Color(0xFFF5B942);
  static const goldSoft = Color(0xFFFFE3A3);

  /// Accent gradient — avatars, icon chips, progress fills.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleStart, purpleEnd],
  );

  /// Deep gradient — header, hero card.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1550), Color(0xFF3A22A8), Color(0xFF6C4DF6)],
    stops: [0.0, 0.62, 1.0],
  );

  static const pageBg = Color(0xFFF5F3FC);
  static const ink = Color(0xFF14112B);
  static const inkMuted = Color(0xFF6A6688);
  static const inkFaint = Color(0xFF9C99B6);
  static const hairline = Color(0xFFEBE8F6);

  static const success = Color(0xFF12A150);
  static const danger = Color(0xFFE0343A);
  static const warning = Color(0xFFD97706);

  /// Layered card shadow: tight contact shadow + wide violet ambient glow.
  static List<BoxShadow> cardShadow = [
    BoxShadow(color: midnightSoft.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1)),
    BoxShadow(color: purpleEnd.withValues(alpha: 0.09), blurRadius: 26, offset: const Offset(0, 12)),
  ];
}

/// Deep-violet app header shared by every affiliate screen — title,
/// subtitle, bell + avatar actions baked in. Rounded bottom edge with soft
/// glow orbs for depth.
class AffHeader extends StatelessWidget implements PreferredSizeWidget {
  const AffHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    const radius = BorderRadius.vertical(bottom: Radius.circular(30));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: AffColors.midnightSoft.withValues(alpha: 0.28), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AffColors.heroGradient),
          child: Stack(
            children: [
              const Positioned.fill(child: DecorativeOrbs(scale: 0.8)),
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 14, 4),
                    child: Row(
                      children: [
                        if (automaticallyImplyLeading && canPop)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12.5, fontWeight: FontWeight.w500, letterSpacing: 0.1),
                              ),
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
        ),
      ),
    );
  }
}

/// Circular glass icon button for the header (notification bell, etc.).
class AffHeaderIcon extends StatelessWidget {
  const AffHeaderIcon({super.key, required this.icon, required this.onTap, this.showDot = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.14),
            shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(icon, color: Colors.white, size: 19),
              ),
            ),
          ),
          if (showDot)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AffColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AffColors.midnightSoft, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular initials avatar for the header (white ring on gradient).
class AffHeaderAvatar extends StatelessWidget {
  const AffHeaderAvatar({super.key, required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AffColors.goldSoft, AffColors.gold], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Text(initials, style: const TextStyle(color: AffColors.midnight, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      ),
    );
  }
}

/// Deep midnight-violet hero card used at the top of Dashboard / Wallet /
/// Profile bodies (wallet balance, greeting, avatar block). Soft glow orbs and
/// a hairline highlight border give it depth.
class AffHeroCard extends StatelessWidget {
  const AffHeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AffColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.36), blurRadius: 30, offset: const Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            const Positioned.fill(child: DecorativeOrbs()),
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

/// White rounded-22 card with a layered violet-tinted shadow — the base
/// surface for stat tiles, lists, forms across the affiliate portal.
class AffCard extends StatelessWidget {
  const AffCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AffColors.hairline),
        boxShadow: AffColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

/// Rounded-square icon chip tinted with [color] — use for stat tiles and
/// list leading icons instead of repeating the brand gradient everywhere.
class AffIconChip extends StatelessWidget {
  const AffIconChip({super.key, required this.icon, this.color = AffColors.purpleEnd, this.size = 42, this.solid = false});

  final IconData icon;
  final Color color;
  final double size;

  /// Solid gradient fill with a white icon, instead of a soft tint.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: solid ? LinearGradient(colors: [color.withValues(alpha: 0.85), color], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: solid ? null : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: solid ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))] : null,
      ),
      child: Icon(icon, color: solid ? Colors.white : color, size: size * 0.48),
    );
  }
}

/// One destination in [AffNavBar].
class AffNavItem {
  const AffNavItem({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating bottom nav — a midnight glass pill holding the first N-1 tabs
/// (the selected one lit by a glowing violet capsule), plus a circular
/// gradient Profile button that overlaps its right edge with a gold ring
/// when active.
class AffNavBar extends StatelessWidget {
  const AffNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<AffNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final barItems = items.sublist(0, items.length - 1);
    final profileItem = items.last;
    final profileIndex = items.length - 1;
    final profileSelected = selectedIndex == profileIndex;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, 10 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Container(
              height: 68,
              margin: const EdgeInsets.only(right: 30),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AffColors.midnightSoft, AffColors.midnight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [BoxShadow(color: AffColors.midnight.withValues(alpha: 0.40), blurRadius: 26, offset: const Offset(0, 12))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < barItems.length; i++)
                    _AffNavButton(item: barItems[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            Positioned(
              right: 0,
              child: PressableScaleLite(
                onTap: () => onSelected(profileIndex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AffColors.gradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: profileSelected ? AffColors.gold : Colors.white.withValues(alpha: 0.85),
                      width: profileSelected ? 2.5 : 3,
                    ),
                    boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Icon(profileSelected ? profileItem.selectedIcon : profileItem.icon, color: Colors.white, size: 25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap target with a quick scale-down on press (for the nav Profile button).
class PressableScaleLite extends StatefulWidget {
  const PressableScaleLite({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableScaleLite> createState() => _PressableScaleLiteState();
}

class _PressableScaleLiteState extends State<PressableScaleLite> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.92 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
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
    final color = selected ? Colors.white : Colors.white.withValues(alpha: 0.5);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        radius: 28,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? 46 : 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected ? AffColors.gradient : null,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: selected ? [BoxShadow(color: AffColors.purpleStart.withValues(alpha: 0.55), blurRadius: 14, offset: const Offset(0, 4))] : null,
                ),
                child: Icon(selected ? item.selectedIcon : item.icon, size: 21, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color, letterSpacing: 0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header: bold title + optional "View all" pill action.
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AffColors.ink, letterSpacing: -0.3),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(color: AffColors.purpleEnd.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!, style: const TextStyle(color: AffColors.purpleEnd, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 13, color: AffColors.purpleEnd),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
