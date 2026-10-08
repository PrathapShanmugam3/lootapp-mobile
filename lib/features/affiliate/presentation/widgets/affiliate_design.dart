import 'package:flutter/material.dart';

/// Purple/violet design system for the Affiliate (User) portal only —
/// scoped to this feature so it never touches the shared flat theme used
/// by Manager/Admin. Matches the client-supplied screenshots exactly:
/// vivid purple gradient header/hero, lavender page background, white
/// rounded-20 cards, pill-shaped floating bottom nav with a circular
/// gradient Profile button.
class AffColors {
  AffColors._();

  static const purpleStart = Color(0xFFB224EF);
  static const purpleEnd = Color(0xFF7B2FF7);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purpleStart, purpleEnd],
  );

  static const pageBg = Color(0xFFF3EEFB);
  static const ink = Color(0xFF1E1333);
  static const inkMuted = Color(0xFF6B6480);
  static const inkFaint = Color(0xFF9D96B5);
  static const hairline = Color(0xFFEDE7F8);

  static const success = Color(0xFF16A34A);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);

  static List<BoxShadow> cardShadow = [
    BoxShadow(color: purpleEnd.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 10)),
  ];
}

/// Purple gradient app header shared by every affiliate screen — title,
/// subtitle, bell + avatar actions baked in.
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
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Container(
      decoration: const BoxDecoration(gradient: AffColors.gradient),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 14, 0),
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
                        style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12.5, fontWeight: FontWeight.w500),
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
            color: Colors.white.withValues(alpha: 0.18),
            shape: const CircleBorder(),
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
                  color: const Color(0xFFFACC15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AffColors.purpleEnd, width: 1.5),
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
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    );
  }
}

/// Full-bleed purple gradient hero card used at the top of Dashboard /
/// Wallet / Profile bodies (wallet balance, greeting, avatar block).
class AffHeroCard extends StatelessWidget {
  const AffHeroCard({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AffColors.gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: DefaultTextStyle.merge(style: const TextStyle(color: Colors.white), child: child),
    );
  }
}

/// White rounded-20 card with a soft purple-tinted shadow — the base
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: AffColors.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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

/// One destination in [AffNavBar].
class AffNavItem {
  const AffNavItem({required this.icon, required this.selectedIcon, required this.label});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Pill-shaped floating bottom nav — white rounded bar holding the first
/// N-1 tabs, plus a circular gradient Profile button that floats above and
/// overlaps its right edge, exactly matching the screenshots.
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
      padding: EdgeInsets.fromLTRB(16, 0, 16, 10 + MediaQuery.of(context).padding.bottom),
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Container(
              height: 64,
              margin: const EdgeInsets.only(right: 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.18), blurRadius: 22, offset: const Offset(0, 10))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < barItems.length; i++)
                    _AffNavButton(item: barItems[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Positioned(
              right: 0,
              child: GestureDetector(
                onTap: () => onSelected(profileIndex),
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AffColors.gradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 8))],
                  ),
                  child: Icon(profileSelected ? profileItem.selectedIcon : profileItem.icon, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
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
    final color = selected ? AffColors.purpleEnd : AffColors.inkFaint;
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? item.selectedIcon : item.icon, size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header: bold title + optional "View all →" action link.
class AffSectionHeader extends StatelessWidget {
  const AffSectionHeader({super.key, required this.title, this.action, this.onActionTap});

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AffColors.ink)),
          if (action != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(action!, style: const TextStyle(color: AffColors.purpleEnd, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}
