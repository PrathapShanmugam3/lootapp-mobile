import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

/// Headline surface — wallet balance, greetings, key totals. A deep
/// midnight-violet gradient with soft radial glows and a hairline highlight
/// border, so it reads as the premium focal point of the page. Keep this
/// (not a plain [Card]) as the go-to headline surface across all portals.
class GradientHeroCard extends StatelessWidget {
  const GradientHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.midnightGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: AppColors.glow(AppColors.primaryDeep, 0.9),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            const Positioned.fill(child: DecorativeOrbs()),
            Padding(
              padding: padding,
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft radial glows layered on a dark gradient surface — gives hero
/// blocks depth without any image assets. They drift slowly so the surface
/// feels alive (static when the OS asks to reduce motion). Fills its parent
/// [Stack].
class DecorativeOrbs extends StatefulWidget {
  const DecorativeOrbs({super.key, this.scale = 1});

  final double scale;

  @override
  State<DecorativeOrbs> createState() => _DecorativeOrbsState();
}

class _DecorativeOrbsState extends State<DecorativeOrbs> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    Widget orb(double size, Color color, double alpha) => Container(
          width: size * scale,
          height: size * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
            ),
          ),
        );
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value) - 0.5; // -0.5..0.5
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(right: (-70 + t * 40) * scale, top: (-80 + t * 24) * scale, child: orb(240, const Color(0xFFC4A8FF), 0.38)),
              Positioned(left: (-60 - t * 36) * scale, bottom: (-90 + t * 30) * scale, child: orb(220, AppColors.gold, 0.16)),
              Positioned(right: (30 - t * 50) * scale, bottom: (-60 - t * 20) * scale, child: orb(150, const Color(0xFF6C4DF6), 0.45)),
              Positioned(left: (90 + t * 60) * scale, top: (-70 - t * 20) * scale, child: orb(170, AppColors.pinkAccent, 0.30)),
              Positioned(right: (110 + t * 40) * scale, bottom: (-80 + t * 24) * scale, child: orb(150, AppColors.cyan, 0.22)),
            ],
          );
        },
      ),
    );
  }
}

/// Number that counts up (or tweens) to [value] when first shown and
/// whenever [value] changes. [format] turns the in-flight number into text.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final num value;
  final String Function(num) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return Text(format(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// Visible flag that the content below is offline sample data, not the
/// user's real account — shown whenever the server couldn't be reached.
class SampleDataBanner extends StatelessWidget {
  const SampleDataBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: AppColors.goldMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Sample data — couldn\'t reach the server',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.warning),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact stat tile for KPI rows — icon, label, value, optional trend chip.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trendText,
    this.trendUp,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? trendText;
  final bool? trendUp;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.primary),
                ),
              const Spacer(),
              if (trendText != null)
                TrendChip(text: trendText!, up: trendUp ?? true),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.6,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class TrendChip extends StatelessWidget {
  const TrendChip({super.key, required this.text, required this.up});

  final String text;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final color = up ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: up ? AppColors.successMuted : AppColors.dangerMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onActionTap,
  });

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
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
                color: AppColors.ink,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: Text(action!, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

/// Full-screen loading state — a page-shaped shimmer skeleton (hero card +
/// bento stat row + a few list rows) rather than a bare spinner, so screens
/// never show a blank page while fetching. Pass [compact] for shorter
/// content areas (sheets, cards) where the full hero+stats skeleton would
/// overflow.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.hairline,
      highlightColor: const Color(0xFFF7F5FD),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (!compact) ...[
            const SkeletonBox(height: 120, borderRadius: 16),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: SkeletonBox(height: 88, borderRadius: 14)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 88, borderRadius: 14)),
              ],
            ),
            const SizedBox(height: 22),
          ],
          for (var i = 0; i < 4; i++) ...[
            const SkeletonBox(height: 60, borderRadius: 12),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// A single shimmering placeholder block — the atom [LoadingState] and
/// per-screen skeletons are built from.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = 8,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Branded inline spinner for buttons/pull-to-refresh moments where a full
/// skeleton page doesn't apply — use instead of a bare
/// [CircularProgressIndicator] so even small loading moments pick up the
/// accent color.
class BrandSpinner extends StatelessWidget {
  const BrandSpinner({super.key, this.size = 22, this.strokeWidth = 2.6});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.dangerMuted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 26,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 13.5),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 26, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.inkMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status pill — used for offer categories, user status, pay-record status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 9, 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat page header — replaces the previous purple-gradient banner. Plain
/// canvas-colored surface, a hairline bottom border, high-contrast ink
/// title. Keeps each screen's own actions (bell, settings, etc.) via
/// [actions] so every screen shares the same chrome.
///
/// Auto-adds a back arrow when the current route can be popped (same
/// behavior a plain [AppBar] gives for free) — pass [automaticallyImplyLeading]
/// false to suppress it, or [leading] to use a custom leading widget instead.
class PortalHeader extends StatelessWidget implements PreferredSizeWidget {
  const PortalHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  /// Optional strip (usually a [TabBar]) rendered below the title row.
  final PreferredSizeWidget? bottom;

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  // Row content height is the max of: the title+subtitle text block, or a
  // 44px icon button (leading/actions use a shrunk tap target below, not
  // the default 48px one — that default was the cause of a ~7px bottom
  // overflow here before). Content row is top/bottom padding (10+10) + 44,
  // which comfortably fits both the one-line and two-line title block.
  static const double _rowHeight = 64;

  @override
  Size get preferredSize =>
      Size.fromHeight(_rowHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final resolvedLeading =
        leading ??
        (automaticallyImplyLeading && canPop
            ? _HeaderIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.of(context).pop(),
              )
            : null);

    // No SafeArea here: like a plain AppBar, Scaffold already adds the
    // status-bar inset on top of preferredSize for the app-bar slot, so
    // applying SafeArea too double-counts that inset and overflows this
    // widget's own fixed-height box by exactly the (small) rounding
    // difference between the two insets.
    // The outer Container is placed in a ConstrainedBox(maxHeight:
    // preferredSize.height) by Scaffold — using Expanded for the title row
    // (instead of a SizedBox pinned to the same _rowHeight constant) means
    // it always fills whatever height Scaffold actually grants, so the two
    // numbers can never drift apart by a stray pixel of rounding.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: const Border(bottom: BorderSide(color: AppColors.hairline)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDeep.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                resolvedLeading != null ? 6 : 20,
                0,
                12,
                0,
              ),
              child: Row(
                children: [
                  if (resolvedLeading != null) ...[
                    resolvedLeading,
                    const SizedBox(width: 2),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Text(
                              subtitle!,
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

/// Compact header icon button — 40×40 tap target (not the default 48px),
/// so it fits inside [PortalHeader]'s fixed-height row without overflow.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 19,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: size),
        color: AppColors.ink,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

/// Circular icon button for [PortalHeader] actions (bell, settings, redeem…)
/// with an optional unread dot.
class PortalHeaderAction extends StatelessWidget {
  const PortalHeaderAction({
    super.key,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _HeaderIconButton(
            icon: icon,
            size: 21,
            tooltip: tooltip,
            onPressed: onPressed,
          ),
          if (showDot)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Initials avatar used at the right end of [PortalHeader] actions.
class PortalHeaderAvatar extends StatelessWidget {
  const PortalHeaderAvatar({super.key, required this.initials, this.onTap});

  final String initials;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.transparent,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// White card with a hairline border and a whisper of shadow — the flat
/// replacement for the old colored-shadow bento card. Used throughout for
/// stat tiles, chart cards, campaign lists, settings groups.
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppColors.softShadow(0.7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: Colors.transparent,
          child: onTap == null
              ? Padding(padding: padding, child: child)
              : InkWell(
                  onTap: onTap,
                  child: Padding(padding: padding, child: child),
                ),
        ),
      ),
    );
    return card;
  }
}

/// A settings/menu row with a neutral icon chip, used inside [BentoCard]
/// groups (Profile's "More" section, etc.) in place of a plain [ListTile].
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.chipColor,
    required this.label,
    this.labelColor,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final Color chipColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: chipColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: labelColor ?? AppColors.ink,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkFaint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hairline divider between [SettingsRow]s inside a [BentoCard] group.
class RowDivider extends StatelessWidget {
  const RowDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.hairline,
  );
}

/// Maps common status strings to a semantic color; falls back to primary.
Color statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'success':
    case 'active':
    case 'approved':
    case 'live':
    case 'open':
      return AppColors.success;
    case 'failed':
    case 'rejected':
    case 'banned':
    case 'suspended':
    case 'closed':
      return AppColors.danger;
    case 'pending':
    case 'processing':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

/// A soft highlight that sweeps across its parent every few seconds —
/// the "shine" on primary buttons. Static under reduce-motion.
class ShineSweep extends StatefulWidget {
  const ShineSweep({super.key});

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

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
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final p = (_c.value / 0.4).clamp(0.0, 1.0); // sweep in the first 40%, then rest
              final x = -90 + (w + 180) * Curves.easeInOut.transform(p);
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: x,
                    top: -10,
                    bottom: -10,
                    width: 70,
                    child: Transform(
                      transform: Matrix4.skewX(-0.45),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.30), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Full-width primary CTA — violet gradient with a soft colored glow and a
/// subtle top highlight. Shows a white spinner while [loading]; goes flat
/// grey when disabled.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final radius = BorderRadius.circular(16);
    return PressableScale(
      onTap: enabled ? onPressed : null,
      scale: 0.985,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed == null && !loading ? 0.5 : 1,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            boxShadow: enabled ? AppColors.glow(AppColors.primary, 0.9) : null,
          ),
          child: Stack(
            children: [
              if (enabled) Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: const ShineSweep())),
              Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onPressed : null,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: loading
                      ? const SizedBox(
                          key: ValueKey('spin'),
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                            strokeCap: StrokeCap.round,
                          ),
                        )
                      : Padding(
                          key: const ValueKey('label'),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15.5,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

/// Subtle shrink-on-press feedback for tappable cards and buttons.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.98,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Fades and slides its child up on first build. Pass increasing [index]
/// values to stagger a list of sections.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 10,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 50).clamp(0, 400);
    final total = 300 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOut),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
    );
  }
}

/// One destination in [BrandNavBar].
class BrandNavItem {
  const BrandNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Bottom navigation bar — white sheet with rounded top corners and a
/// lifted shadow; the selected destination gets a tinted capsule behind its
/// icon and a brand-colored label. Shared by the manager and admin shells.
class BrandNavBar extends StatelessWidget {
  const BrandNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BrandNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnightSoft.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BrandNavButton(
                    item: items[i],
                    selected: i == selectedIndex,
                    onTap: () {
                      if (i != selectedIndex) HapticFeedback.selectionClick();
                      onSelected(i);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandNavButton extends StatelessWidget {
  const _BrandNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BrandNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.inkFaint;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: selected ? 52 : 32,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 22,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
