import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../profile_menu_sheet.dart';
import 'affiliate_design.dart';

/// Header avatar for the signed-in user — initials come from the auth
/// session (never a placeholder) and tapping opens the account sheet.
class AffUserAvatar extends ConsumerWidget {
  const AffUserAvatar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).user?.name.trim() ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '•';
    return AffHeaderAvatar(
      initials: initials,
      onTap: () => showProfileMenuSheet(context, ref, initials: initials, name: name),
    );
  }
}
