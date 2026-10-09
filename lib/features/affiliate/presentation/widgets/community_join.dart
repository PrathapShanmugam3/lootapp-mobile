import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'affiliate_design.dart';
import '../../../../core/widgets/app_toast.dart';

/// Official LootHat community channels.
class CommunityLinks {
  CommunityLinks._();

  static const telegram = 'https://t.me/+p03Tb_KqMwMwNWM1';
  static const whatsapp = 'https://www.whatsapp.com/channel/0029VaDmXVGLY6dGWlmmJC2k';
}

Future<void> openCommunityLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) showErrorToast(context, 'Could not open $url');
  }
}

/// "Join our community" card: a live pill plus animated Telegram and
/// WhatsApp join buttons that breathe out of phase to draw the eye.
class CommunityJoinCard extends StatelessWidget {
  const CommunityJoinCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AffCard(
      wash: const Color(0xFF25D366),
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Join our community', style: AffText.jakarta(15, FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AffColors.chipPink, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulseDot(color: AffColors.rose, size: 6),
                    const SizedBox(width: 5),
                    Text('LIVE DEALS', style: AffText.jakarta(9.5, FontWeight.w800, color: AffColors.rose, letterSpacing: 0.6)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Get the hottest loot offers & payout alerts before anyone else.', style: AffText.jakarta(11.5, FontWeight.w500, color: AffColors.inkMuted, height: 1.35)),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: JoinChannelButton(
                  icon: Icon(Icons.telegram, color: Color(0xFF0088CC), size: 22),
                  caption: 'Join on',
                  label: 'Telegram',
                  url: CommunityLinks.telegram,
                  colors: [Color(0xFF37BBFE), Color(0xFF0088CC)],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: JoinChannelButton(
                  icon: WhatsAppGlyph(color: Color(0xFF128C7E), size: 20),
                  caption: 'Join on',
                  label: 'WhatsApp',
                  url: CommunityLinks.whatsapp,
                  colors: [Color(0xFF3EE07A), Color(0xFF128C7E)],
                  phase: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Gradient pill button with a looping attention animation: a soft breathing
/// scale, an outward glow ring, a diagonal shine sweep and a small icon
/// wiggle. [phase] (0–1) offsets the loop so sibling buttons take turns.
class JoinChannelButton extends StatefulWidget {
  const JoinChannelButton({super.key, required this.icon, required this.caption, required this.label, required this.url, required this.colors, this.phase = 0});

  final Widget icon;
  final String caption;
  final String label;
  final String url;
  final List<Color> colors;
  final double phase;

  @override
  State<JoinChannelButton> createState() => _JoinChannelButtonState();
}

class _JoinChannelButtonState extends State<JoinChannelButton> with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final AnimationController _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 110), reverseDuration: const Duration(milliseconds: 260));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _press.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    HapticFeedback.lightImpact();
    await _press.forward();
    _press.reverse();
    if (mounted) await openCommunityLink(context, widget.url);
  }

  @override
  Widget build(BuildContext context) {
    final brand = widget.colors.last;
    return Semantics(
      button: true,
      label: '${widget.caption} ${widget.label}',
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapCancel: () => _press.reverse(),
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _press]),
          builder: (context, _) {
            final v = _reduceMotion ? 0.0 : (_loop.value + widget.phase) % 1;
            final breathe = (math.sin(v * 2 * math.pi) + 1) / 2; // 0 → 1 → 0
            final scale = (1 + 0.025 * breathe) * (1 - 0.06 * _press.value);
            // Glow ring and shine run in the first half of each cycle, then rest.
            final ring = Curves.easeOut.transform((v * 2).clamp(0.0, 1.0));
            final shine = Curves.easeInOut.transform((v * 2.2).clamp(0.0, 1.0));
            final wiggle = v < 0.25 ? math.sin(v * 4 * 2 * math.pi) * 0.14 : 0.0;

            return Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (!_reduceMotion)
                    Positioned.fill(
                      child: Transform.scale(
                        scaleX: 1 + 0.08 * ring,
                        scaleY: 1 + 0.28 * ring,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: brand.withValues(alpha: 0.55 * (1 - ring)), width: 2),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.colors),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: brand.withValues(alpha: 0.28 + 0.17 * breathe),
                          blurRadius: 10 + 8 * breathe,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Transform.rotate(
                                  angle: wiggle,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: widget.icon,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(widget.caption, maxLines: 1, style: AffText.jakarta(10, FontWeight.w600, color: Colors.white.withValues(alpha: 0.85), height: 1.1)),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(widget.label, maxLines: 1, style: AffText.jakarta(14.5, FontWeight.w800, color: Colors.white, letterSpacing: -0.2, height: 1.2)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.9), size: 16),
                              ],
                            ),
                          ),
                          if (!_reduceMotion && shine > 0 && shine < 1)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Align(
                                  alignment: Alignment(-2.2 + 4.4 * shine, 0),
                                  child: Transform.rotate(
                                    angle: 0.35,
                                    child: Container(
                                      width: 26,
                                      height: 110,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.45), Colors.white.withValues(alpha: 0)]),
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// WhatsApp-style mark (Material Icons has none): a ringed speech bubble with
/// a tail at the bottom-left and a handset inside.
class WhatsAppGlyph extends StatelessWidget {
  const WhatsAppGlyph({super.key, required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BubblePainter(color),
        child: Center(
          child: Icon(Icons.call_rounded, color: color, size: size * 0.48),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * u;
    canvas.drawCircle(Offset(12 * u, 11.5 * u), 8.6 * u, stroke);
    final tail = Path()
      ..moveTo(4.6 * u, 15.2 * u)
      ..lineTo(2.6 * u, 21.6 * u)
      ..lineTo(9.0 * u, 19.6 * u)
      ..close();
    canvas.drawPath(tail, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color;
}
