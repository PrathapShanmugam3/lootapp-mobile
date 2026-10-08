import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../legal/presentation/account_delete_screen.dart';
import '../../../legal/presentation/privacy_policy_screen.dart';
import '../../../legal/presentation/terms_screen.dart';
import '../../custom_domains/presentation/custom_domains_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../reports/presentation/reports_screen.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Profile',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_outlined,
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
  late final TextEditingController _upiCtrl;
  late final TextEditingController _accNoCtrl;
  late final TextEditingController _ifscCtrl;
  bool _savingPayout = false;

  @override
  void initState() {
    super.initState();
    _upiCtrl = TextEditingController(text: widget.profile['upi']?.toString() ?? '');
    _accNoCtrl = TextEditingController(text: widget.profile['accNo']?.toString() ?? '');
    _ifscCtrl = TextEditingController(text: widget.profile['ifsc']?.toString() ?? '');
  }

  @override
  void dispose() {
    _upiCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p['name']?.toString() ?? '';
    final initials = name.trim().isNotEmpty ? name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase() : '?';
    final mobile = p['mobile']?.toString() ?? '';
    final maskedMobile = mobile.length > 4 ? '+91 ${mobile.substring(0, 2)}${'•' * (mobile.length - 4).clamp(0, 6)}${mobile.substring(mobile.length - 2)}' : mobile;
    final wallet = p['balance'] ?? p['wallet'] ?? 0;
    final refLinks = p['refLinks'] ?? p['referralLinks'] ?? 0;
    final tier = p['tier']?.toString() ?? 'Bronze';
    final userId = p['userId'] ?? p['id'] ?? p['user_id'];
    final payoutMethod = (p['upi']?.toString().isNotEmpty ?? false) ? 'UPI' : (p['accNo']?.toString().isNotEmpty ?? false ? 'Bank' : '—');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        FadeSlideIn(
          child: AffHeroCard(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AffColors.goldSoft, AffColors.gold, Color(0xFFE08A1E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AffColors.midnight),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(height: 14),
                Text(name.isNotEmpty ? name : 'Affiliate', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                const SizedBox(height: 3),
                Text(p['email']?.toString() ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12.5)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AffColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AffColors.gold.withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, size: 14, color: AffColors.gold),
                      const SizedBox(width: 5),
                      Text('$tier member', style: const TextStyle(color: AffColors.goldSoft, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _HeroStat(label: 'WALLET', value: '₹${wallet.toString()}', highlight: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _HeroStat(label: 'REF LINKS', value: refLinks.toString())),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideIn(index: 1, child: AffSectionHeader(title: 'Account details')),
        FadeSlideIn(
          index: 2,
          child: AffCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              children: [
                _DetailRow(label: 'Full name', value: name.isNotEmpty ? name : '—'),
                _DetailRow(label: 'Email', value: p['email']?.toString() ?? '—'),
                _DetailRow(label: 'Mobile', value: maskedMobile.isNotEmpty ? maskedMobile : '—'),
                _DetailRow(label: 'User ID', value: userId?.toString() ?? '—'),
                _DetailRow(label: 'Payout method', value: payoutMethod, last: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideIn(index: 3, child: AffSectionHeader(title: 'Manage')),
        FadeSlideIn(
          index: 4,
          child: AffCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuRow(icon: Icons.account_balance_wallet_outlined, label: 'Payout details', subtitle: 'UPI or bank account', onTap: () => _showPayoutSheet(context)),
                const _MenuDivider(),
                _MenuRow(icon: Icons.lock_outline_rounded, label: 'Change password', subtitle: 'Keep your account secure', onTap: () => _showChangePasswordSheet(context)),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.insights_rounded,
                  label: 'Reports',
                  subtitle: 'Clicks, conversions and earnings',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                ),
                const _MenuDivider(),
                _MenuRow(
                  icon: Icons.public_rounded,
                  label: 'Custom domains',
                  subtitle: 'Use your own link domain',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomDomainsScreen())),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const FadeSlideIn(index: 5, child: AffSectionHeader(title: 'Community')),
        FadeSlideIn(
          index: 6,
          child: Row(
            children: [
              Expanded(
                child: _CommunityTile(
                  icon: Icons.send_rounded,
                  label: 'Telegram',
                  color: const Color(0xFF229ED9),
                  onTap: () => _openExternal(context, 'https://t.me/+p03Tb_KqMwMwNWM1'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CommunityTile(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25A244),
                  onTap: () => _openExternal(context, 'https://www.whatsapp.com/channel/0029VaDmXVGLY6dGWlmmJC2k'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          index: 7,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: AffColors.danger.withValues(alpha: 0.10),
                foregroundColor: AffColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Log out'),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 8,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FooterLink(label: 'Rate us', onTap: () => _openExternal(context, 'https://play.google.com/store/apps/details?id=com.camp.loothat')),
              const _FooterDot(),
              _FooterLink(label: 'Privacy', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
              const _FooterDot(),
              _FooterLink(label: 'Terms', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsScreen()))),
              const _FooterDot(),
              _FooterLink(
                label: 'Delete account',
                danger: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountDeleteScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openExternal(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  void _showPayoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payout details', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID')),
                const SizedBox(height: 12),
                TextField(controller: _accNoCtrl, decoration: const InputDecoration(labelText: 'Account number')),
                const SizedBox(height: 12),
                TextField(controller: _ifscCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'IFSC code')),
                const SizedBox(height: 16),
                GradientButton(label: 'Save payout details', loading: _savingPayout, onPressed: _savePayout),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePayout() async {
    setState(() => _savingPayout = true);
    try {
      final result = await ref.read(profileRepositoryProvider).updatePayoutDetails(upi: _upiCtrl.text, accNo: _accNoCtrl.text, ifsc: _ifscCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Payout details updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _savingPayout = false);
    }
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: highlight ? AffColors.gold : Colors.white),
            ),
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
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 12, top: 0),
      margin: EdgeInsets.only(bottom: last ? 0 : 12),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AffColors.hairline))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AffColors.inkMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: AffColors.ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 70, endIndent: 16, color: AffColors.hairline);
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, required this.onTap, this.subtitle});
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AffIconChip(icon: icon, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AffColors.ink)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AffColors.inkFaint)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AffColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AffCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          AffIconChip(icon: icon, color: color, size: 38, solid: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AffColors.ink)),
                const Text('Join channel', style: TextStyle(fontSize: 11, color: AffColors.inkFaint)),
              ],
            ),
          ),
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
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: danger ? AffColors.danger.withValues(alpha: 0.85) : AffColors.inkMuted),
        ),
      ),
    );
  }
}

class _FooterDot extends StatelessWidget {
  const _FooterDot();

  @override
  Widget build(BuildContext context) => const Text('·', style: TextStyle(color: AffColors.inkFaint, fontWeight: FontWeight.w800));
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Change password', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Update password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(profileRepositoryProvider).changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
      if (!mounted) return;
      final success = result['success'] == true;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (success ? 'Password changed' : 'Failed to change password')),
          backgroundColor: success ? AffColors.success : AffColors.danger,
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
