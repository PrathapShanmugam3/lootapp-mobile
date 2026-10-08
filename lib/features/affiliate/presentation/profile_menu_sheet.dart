import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/presentation/auth_providers.dart';
import '../profile/presentation/profile_screen.dart';

/// Quick account sheet opened from the header avatar — just the essentials
/// (view profile, log out). Community links, legal pages and the rest live
/// on the Profile tab so they aren't duplicated here.
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.softShadow(1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: const BoxDecoration(gradient: AppColors.midnightGradient),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.gold,
                    child: Text(initials, style: const TextStyle(color: AppColors.midnight, fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'Account', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const Text('LootHat Affiliate', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SettingsRow(
              icon: Icons.person_outline_rounded,
              chipColor: AppColors.primary,
              label: 'View profile',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
            const RowDivider(),
            SettingsRow(
              icon: Icons.logout_rounded,
              chipColor: AppColors.danger,
              label: 'Log out',
              labelColor: AppColors.danger,
              onTap: () async {
                if (!await confirmLogout(context)) return;
                if (!context.mounted) return;
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
