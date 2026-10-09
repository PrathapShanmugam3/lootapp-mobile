import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'common.dart';

/// One slide of an [AnnouncementDialog] carousel — an icon badge, headline,
/// and body copy. Use a single slide for a one-off announcement, or several
/// for a swipeable "what's new" style card like WhatsApp/Instagram/Telegram
/// show after an update.
class AnnouncementSlide {
  const AnnouncementSlide({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accent;
}

/// Full-bleed, brand-gradient popup for announcements, offers, and "what's
/// new" moments — the attractive card-style modal WhatsApp/Instagram/
/// Telegram show on web, adapted for this app's mobile theme. Swipeable when
/// given more than one [slides] entry.
///
/// ```dart
/// showAnnouncementDialog(
///   context,
///   slides: const [
///     AnnouncementSlide(
///       icon: Icons.celebration_rounded,
///       title: 'Double cashback weekend',
///       message: 'Earn 2x rewards on every redemption this Sat–Sun.',
///     ),
///   ],
///   primaryLabel: 'Got it',
/// );
/// ```
Future<void> showAnnouncementDialog(
  BuildContext context, {
  required List<AnnouncementSlide> slides,
  String primaryLabel = 'Got it',
  VoidCallback? onPrimaryTap,
  String? secondaryLabel,
  VoidCallback? onSecondaryTap,
  bool barrierDismissible = true,
}) {
  assert(slides.isNotEmpty, 'showAnnouncementDialog needs at least one slide');
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.midnight.withValues(alpha: 0.55),
    barrierLabel: 'Dismiss',
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, __) => _AnnouncementDialog(
      slides: slides,
      primaryLabel: primaryLabel,
      onPrimaryTap: onPrimaryTap,
      secondaryLabel: secondaryLabel,
      onSecondaryTap: onSecondaryTap,
    ),
    transitionBuilder: (ctx, animation, _, child) {
      final fade = CurvedAnimation(parent: animation, curve: const Interval(0, 0.6, curve: Curves.easeOut), reverseCurve: Curves.easeIn);
      final bounce = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween(begin: 0.82, end: 1.0).animate(bounce),
          child: child,
        ),
      );
    },
  );
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({
    required this.slides,
    required this.primaryLabel,
    this.onPrimaryTap,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final List<AnnouncementSlide> slides;
  final String primaryLabel;
  final VoidCallback? onPrimaryTap;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _controller = PageController();
  int _page = 0;

  bool get _isLast => _page == widget.slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePrimary() {
    HapticFeedback.lightImpact();
    if (!_isLast) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      return;
    }
    Navigator.of(context).pop();
    widget.onPrimaryTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final multi = widget.slides.length > 1;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 40, offset: const Offset(0, 20)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        SizedBox(
                          height: 300,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: widget.slides.length,
                            onPageChanged: (i) {
                              HapticFeedback.selectionClick();
                              setState(() => _page = i);
                            },
                            itemBuilder: (ctx, i) => _SlideCard(slide: widget.slides[i], active: i == _page),
                          ),
                        ),
                        if (multi)
                          Positioned(
                            top: 14,
                            left: 16,
                            right: 56,
                            child: _ProgressBar(count: widget.slides.length, index: _page),
                          ),
                        Positioned(
                          top: 10,
                          right: 14,
                          child: _CloseButton(onTap: () => Navigator.of(context).pop()),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                      child: Column(
                        children: [
                          GradientButton(
                            label: _isLast ? widget.primaryLabel : 'Next',
                            onPressed: _handlePrimary,
                            icon: _isLast ? null : Icons.arrow_forward_rounded,
                          ),
                          if (widget.secondaryLabel != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                widget.onSecondaryTap?.call();
                              },
                              child: Text(widget.secondaryLabel!),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideCard extends StatefulWidget {
  const _SlideCard({required this.slide, required this.active});

  final AnnouncementSlide slide;
  final bool active;

  @override
  State<_SlideCard> createState() => _SlideCardState();
}

class _SlideCardState extends State<_SlideCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    if (widget.active) _pop.forward();
  }

  @override
  void didUpdateWidget(covariant _SlideCard old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = widget.slide;
    final badge = ScaleTransition(
      scale: CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Icon(slide.icon, size: 36, color: Colors.white),
      ),
    );
    final text = FadeTransition(
      opacity: CurvedAnimation(parent: _pop, curve: const Interval(0.25, 1, curve: Curves.easeOut)),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(CurvedAnimation(parent: _pop, curve: const Interval(0.25, 1, curve: Curves.easeOutCubic))),
        child: Column(
          children: [
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.25),
            ),
            const SizedBox(height: 8),
            Text(
              slide.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -0.6),
          end: Alignment(1, 0.6),
          colors: [Color.lerp(slide.accent, AppColors.ink, 0.35)!, slide.accent],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: DecorativeOrbs()),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                badge,
                const SizedBox(height: 20),
                text,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Telegram-style segmented progress bar — one pill per slide, the active
/// one glides to full width to show "time" on the current slide rather than
/// a static dot, reinforcing the carousel is a sequence to move through.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final state = i < index ? 1.0 : (i == index ? 1.0 : 0.0);
        return Expanded(
          child: Container(
            height: 3.5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                widthFactor: state,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// [FractionallySizedBox] that animates [widthFactor] changes — stdlib has
/// no built-in for this, used by [_ProgressBar] to glide each segment fill.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required this.widthFactor,
    required this.child,
    required super.duration,
    super.curve,
  });

  final double widthFactor;
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() => _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(_widthFactor, widget.widthFactor, (v) => Tween<double>(begin: v as double)) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      child: widget.child,
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.88,
      onTap: onTap,
      child: Material(
        color: Colors.black.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(7),
            child: Icon(Icons.close_rounded, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
