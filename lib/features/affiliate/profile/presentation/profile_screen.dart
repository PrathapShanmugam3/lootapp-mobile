import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../legal/presentation/account_delete_screen.dart';
import '../../../legal/presentation/privacy_policy_screen.dart';
import '../../../legal/presentation/terms_screen.dart';
import '../../custom_domains/presentation/custom_domains_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../presentation/widgets/community_join.dart';
import 'edit_account_screen.dart';
import 'profile_providers.dart';
import '../../../../core/widgets/app_toast.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(profileProvider);
    final profileAsync = rawAsync;

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Profile',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(profileProvider.future),
        child: profileAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load profile.\n$e', onRetry: () => ref.invalidate(profileProvider)),
          data: (profile) => _ProfileBody(profile: profile),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final Map<String, dynamic> profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  void _openEdit() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditAccountScreen(profile: widget.profile)));
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p['name']?.toString() ?? '';
    final trimmed = name.trim();
    final initials = trimmed.isNotEmpty ? trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase() : '?';
    final mobile = p['mobile']?.toString() ?? '';
    final maskedMobile = mobile.length > 4 ? '+91 ${mobile.substring(0, 2)}${'•' * (mobile.length - 4).clamp(0, 6)}${mobile.substring(mobile.length - 2)}' : mobile;
    final wallet = p['balance'] ?? p['wallet'] ?? 0;
    final refLinks = p['refLinks'] ?? p['referralLinks'] ?? 0;
    final tier = p['tier']?.toString() ?? '';
    final userId = p['userId'] ?? p['id'] ?? p['user_id'];
    final hasUpi = p['upi']?.toString().isNotEmpty ?? false;
    final hasBank = p['accNo']?.toString().isNotEmpty ?? false;
    final payoutMethod = hasUpi ? 'UPI' : (hasBank ? 'Bank' : '—');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        // --- Hero ---
        FadeSlideIn(
          child: AffHeroCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _RotatingRingAvatar(
                  child: Container(
                    width: 74,
                    height: 74,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
                    ),
                    child: Text(initials, style: AffText.number(24, FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(name.isNotEmpty ? name : 'Affiliate', style: AffText.jakarta(20, FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text(p['email']?.toString() ?? '', style: AffText.jakarta(12, FontWeight.w500, color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _HeroStat(label: 'WALLET', value: _rupees(wallet), countTo: num.tryParse(wallet.toString()), prefix: '₹')),
                    const SizedBox(width: 10),
                    Expanded(child: _HeroStat(label: 'REF LINKS', value: refLinks.toString(), countTo: num.tryParse(refLinks.toString()))),
                    if (tier.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(child: _HeroStat(label: 'TIER', value: tier)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- Account details ---
        FadeSlideIn(
          index: 1,
          child: AffCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Account details', style: AffText.jakarta(14.5, FontWeight.w800)),
                    GestureDetector(onTap: _openEdit, child: Text('Edit →', style: AffText.jakarta(11, FontWeight.w600, color: AffColors.purpleEnd))),
                  ],
                ),
                const SizedBox(height: 11),
                _DetailRow(label: 'Full name', value: name.isNotEmpty ? name : '—'),
                _DetailRow(label: 'Email', value: p['email']?.toString() ?? '—'),
                _DetailRow(label: 'Mobile', value: maskedMobile.isNotEmpty ? maskedMobile : '—'),
                _DetailRow(label: 'User ID', value: userId?.toString() ?? '—'),
                _DetailRow(label: 'Payout method', value: payoutMethod, last: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- Rows ---
        FadeSlideIn(
          index: 2,
          child: Column(
            children: [
              _RowTile(label: 'Edit account', icon: Icons.manage_accounts_rounded, tint: AffColors.purpleEnd, value: 'Payout & password', onTap: _openEdit),
              const SizedBox(height: 9),
              _RowTile(label: 'Custom domains', icon: Icons.public_rounded, tint: const Color(0xFFDB2777), onTap: () => _push(const CustomDomainsScreen())),
              const SizedBox(height: 9),
              const _AppearanceTile(),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const FadeSlideIn(index: 3, child: AffSectionHeader(title: 'About & support')),
        FadeSlideIn(
          index: 3,
          child: Column(
            children: [
              _RowTile(
                label: 'Rate us',
                icon: Icons.star_rounded,
                tint: AffColors.amber,
                value: 'Play Store',
                onTap: () => _openExternal('https://play.google.com/store/apps/details?id=com.camp.loothat'),
              ),
              const SizedBox(height: 9),
              _RowTile(label: 'Privacy policy', icon: Icons.privacy_tip_rounded, tint: const Color(0xFF0284C7), onTap: () => _push(const PrivacyPolicyScreen())),
              const SizedBox(height: 9),
              _RowTile(label: 'Terms & conditions', icon: Icons.gavel_rounded, tint: const Color(0xFF4F46E5), onTap: () => _push(const TermsScreen())),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          index: 4,
          child: Column(
            children: [
              _RowTile(
                label: 'Log out',
                icon: Icons.logout_rounded,
                tint: AffColors.danger,
                color: AffColors.danger,
                onTap: () async {
                  if (!await confirmLogout(context)) return;
                  if (!mounted) return;
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 9),
              _RowTile(
                label: 'Delete account',
                icon: Icons.delete_forever_rounded,
                tint: AffColors.danger,
                color: AffColors.danger,
                onTap: () => _push(const AccountDeleteScreen()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const FadeSlideIn(index: 5, child: CommunityJoinCard()),
      ],
    );
  }

  String _rupees(dynamic v) => '₹$v';

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showErrorToast(context, 'Could not open $url');
    }
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, this.countTo, this.prefix = ''});
  final String label;
  final String value;
  final num? countTo;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final style = AffText.number(18, FontWeight.w700, color: Colors.white);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: AffText.jakarta(9.5, FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 0.76)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: countTo != null
                ? AnimatedCount(value: countTo!, format: (n) => '$prefix${countTo == countTo!.roundToDouble() ? n.round() : n.toStringAsFixed(2)}', style: style)
                : Text(value, style: style),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.last = false});
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkFaint)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(12.5, FontWeight.w700))),
        ],
      ),
    );
  }
}

/// White rounded-16 row from the design: bold label, muted value + chevron.
class _RowTile extends StatelessWidget {
  const _RowTile({required this.label, required this.onTap, this.value, this.color, this.icon, this.tint = AffColors.violet});
  final IconData? icon;
  final Color tint;
  final String label;
  final String? value;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AffCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          if (icon != null) ...[
            AffIconChip(icon: icon!, color: tint, size: 32, solid: true),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(label, style: AffText.jakarta(13, FontWeight.w700, color: color ?? AffColors.ink))),
          if (value != null) Text('$value ›', style: AffText.jakarta(13, FontWeight.w700, color: AffColors.inkFaint))
          else if (color == null) Text('›', style: AffText.jakarta(13, FontWeight.w700, color: AffColors.inkFaint)),
        ],
      ),
    );
  }
}

/// Avatar with a dashed white ring spinning around it once every 9s — same as
/// the PHP profile page's `.lh-prof-avatar-ring`.
class _RotatingRingAvatar extends StatefulWidget {
  const _RotatingRingAvatar({required this.child});

  final Widget child;

  @override
  State<_RotatingRingAvatar> createState() => _RotatingRingAvatarState();
}

class _RotatingRingAvatarState extends State<_RotatingRingAvatar> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _spin,
            child: CustomPaint(size: const Size(90, 90), painter: _DashedRingPainter(color: Colors.white.withValues(alpha: 0.55))),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 24;
    const gapFraction = 0.45;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    final ring = rect.deflate(1);
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(ring, i * sweep, sweep * (1 - gapFraction), false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

/// Dark mode on/off — light by default, saved on the device by
/// [ThemeController].
class _AppearanceTile extends ConsumerWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeModeProvider) == ThemeMode.dark;
    void toggle() => ref.read(themeModeProvider.notifier).set(dark ? ThemeMode.light : ThemeMode.dark);

    return AffCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      onTap: toggle,
      child: Row(
        children: [
          AffIconChip(icon: dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: dark ? const Color(0xFF4F46E5) : AffColors.amber, size: 32, solid: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dark mode', style: AffText.jakarta(13, FontWeight.w700)),
                Text(dark ? 'On' : 'Off', style: AffText.jakarta(11, FontWeight.w500, color: AffColors.inkFaint)),
              ],
            ),
          ),
          _DayNightSwitch(value: dark, onTap: toggle),
        ],
      ),
    );
  }
}

/// Sun/moon toggle: a sky-blue track with a sun knob that slides over to a
/// night-violet track with a moon and stars.
class _DayNightSwitch extends StatelessWidget {
  const _DayNightSwitch({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  static const _w = 64.0;
  static const _h = 34.0;
  static const _knob = 26.0;
  static const _duration = Duration(milliseconds: 380);
  static const _curve = Cubic(0.34, 1.4, 0.5, 1);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Dark mode',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeOut,
          width: _w,
          height: _h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_h),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: value ? const [Color(0xFF1E1B4B), Color(0xFF4C1D95)] : const [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
            ),
            boxShadow: [BoxShadow(color: (value ? const Color(0xFF4C1D95) : const Color(0xFF38BDF8)).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Stack(
            children: [
              // Stars (night) / cloud (day) behind the knob.
              AnimatedOpacity(
                duration: _duration,
                opacity: value ? 1 : 0,
                child: const Stack(
                  children: [
                    Positioned(left: 10, top: 8, child: _Dot(3)),
                    Positioned(left: 20, top: 18, child: _Dot(2)),
                    Positioned(left: 28, top: 7, child: _Dot(2)),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: _duration,
                opacity: value ? 0 : 1,
                child: Align(
                  alignment: const Alignment(0.62, 0.15),
                  child: Icon(Icons.cloud_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ),
              AnimatedAlign(
                duration: _duration,
                curve: _curve,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: _duration,
                    width: _knob,
                    height: _knob,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? const Color(0xFFE0E7FF) : const Color(0xFFFACC15),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: AnimatedSwitcher(
                      duration: _duration,
                      transitionBuilder: (child, anim) => RotationTransition(turns: Tween(begin: 0.5, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child)),
                      child: Icon(
                        value ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        key: ValueKey(value),
                        size: 16,
                        color: value ? const Color(0xFF4C1D95) : const Color(0xFFEA580C),
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

class _Dot extends StatelessWidget {
  const _Dot(this.size);

  final double size;

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle));
}

