import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/common.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../legal/presentation/account_delete_screen.dart';
import '../../../legal/presentation/privacy_policy_screen.dart';
import '../../../legal/presentation/terms_screen.dart';
import '../../custom_domains/presentation/custom_domains_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../presentation/widgets/community_join.dart';
import '../../reports/presentation/reports_screen.dart';
import 'edit_account_screen.dart';
import 'profile_providers.dart';
import '../../../../core/widgets/app_toast.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(profileProvider);
    final sample = isSample(rawAsync);
    final profileAsync = withSample(rawAsync, SampleData.profile);

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
          data: (profile) => _ProfileBody(profile: profile, sample: sample, onRetry: () => ref.invalidate(profileProvider)),
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile, this.sample = false, this.onRetry});

  final Map<String, dynamic> profile;
  final bool sample;
  final VoidCallback? onRetry;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  void _openEdit() {
    if (widget.sample) {
      showWarningToast(context, 'Reconnect to the server to edit your account');
      return;
    }
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
        if (widget.sample) SampleDataBanner(onRetry: widget.onRetry),
        // --- Hero ---
        FadeSlideIn(
          child: AffHeroCard(
            radius: 24,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
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
              _RowTile(label: 'Reports', icon: Icons.insights_rounded, tint: const Color(0xFF0284C7), onTap: () => _push(const ReportsScreen())),
              const SizedBox(height: 9),
              _RowTile(label: 'Custom domains', icon: Icons.public_rounded, tint: const Color(0xFFDB2777), onTap: () => _push(const CustomDomainsScreen())),
              const SizedBox(height: 9),
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
            ],
          ),
        ),
        const SizedBox(height: 14),
        const FadeSlideIn(index: 3, child: CommunityJoinCard()),
        const SizedBox(height: 18),
        FadeSlideIn(
          index: 4,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FooterLink(label: 'Rate us', onTap: () => _openExternal('https://play.google.com/store/apps/details?id=com.camp.loothat')),
              const _FooterDot(),
              _FooterLink(label: 'Privacy', onTap: () => _push(const PrivacyPolicyScreen())),
              const _FooterDot(),
              _FooterLink(label: 'Terms', onTap: () => _push(const TermsScreen())),
              const _FooterDot(),
              _FooterLink(label: 'Delete account', danger: true, onTap: () => _push(const AccountDeleteScreen())),
            ],
          ),
        ),
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
  const _RowTile({required this.label, required this.onTap, this.value, this.color = AffColors.ink, this.icon, this.tint = AffColors.purpleEnd});
  final IconData? icon;
  final Color tint;
  final String label;
  final String? value;
  final Color color;
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
          Expanded(child: Text(label, style: AffText.jakarta(13, FontWeight.w700, color: color))),
          if (value != null) Text('$value ›', style: AffText.jakarta(13, FontWeight.w700, color: AffColors.inkFaint))
          else if (color == AffColors.ink) Text('›', style: AffText.jakarta(13, FontWeight.w700, color: AffColors.inkFaint)),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap, this.danger = false});
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(label, style: AffText.jakarta(12, FontWeight.w600, color: danger ? AffColors.danger : AffColors.inkMuted)),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) => Text('·', style: AffText.jakarta(12, FontWeight.w800, color: AffColors.inkHint));
}
