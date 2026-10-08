import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../legal/presentation/privacy_policy_screen.dart';
import '../profile/presentation/profile_screen.dart';

/// Account menu opened from the [PortalHeaderAvatar] — mirrors the Next.js
/// header's profile dropdown (My Profile / Join Telegram / Join WhatsApp /
/// Rate Us / Privacy Policy / Logout) at lootapp-ui's AppHeader.js, so the
/// community links aren't lost in the Flutter port.
Future<void> showProfileMenuSheet(BuildContext context, WidgetRef ref, {required String initials, required String name}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ProfileMenuSheet(initials: initials, name: name, ref: ref),
  );
}

class _ProfileMenuSheet extends StatelessWidget {
  const _ProfileMenuSheet({required this.initials, required this.name, required this.ref});

  final String initials;
  final String name;
  final WidgetRef ref;

  static const _telegramUrl = 'https://t.me/+p03Tb_KqMwMwNWM1';
  static const _whatsappUrl = 'https://www.whatsapp.com/channel/0029VaDmXVGLY6dGWlmmJC2k';
  static const _rateUsUrl = 'https://play.google.com/store/apps/details?id=com.camp.loothat';

  Future<void> _open(BuildContext context, String url) async {
    Navigator.of(context).pop();
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppColors.softShadow(1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: AppColors.ink,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Text(initials, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'Account', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        const Text('Account menu', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SettingsRow(
              icon: Icons.person_outline,
              chipColor: AppColors.inkMuted,
              label: 'My Profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.send_outlined,
              chipColor: AppColors.inkMuted,
              label: 'Join Telegram',
              onTap: () => _open(context, _telegramUrl),
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.chat_bubble_outline,
              chipColor: AppColors.inkMuted,
              label: 'Join WhatsApp',
              onTap: () => _open(context, _whatsappUrl),
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.star_outline,
              chipColor: AppColors.inkMuted,
              label: 'Rate Us',
              onTap: () => _open(context, _rateUsUrl),
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.privacy_tip_outlined,
              chipColor: AppColors.inkMuted,
              label: 'Privacy Policy',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
              },
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.logout,
              chipColor: AppColors.danger,
              label: 'Logout',
              labelColor: AppColors.danger,
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
