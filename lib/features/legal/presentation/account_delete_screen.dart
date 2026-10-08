import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../affiliate/presentation/widgets/affiliate_design.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/recaptcha_dialog.dart';
import '../../affiliate/profile/presentation/profile_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/account_delete_repository.dart';

final accountDeleteRepositoryProvider = Provider<AccountDeleteRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return AccountDeleteRepository(client);
});

class AccountDeleteScreen extends ConsumerStatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  ConsumerState<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends ConsumerState<AccountDeleteScreen> {
  final _formKey = GlobalKey<FormState>();
  String _accountEmail = '';
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete your account?',
      message: 'This is permanent. Your account and all associated data will be deleted and cannot be recovered.',
      confirmLabel: 'Yes, delete',
      cancelLabel: 'Keep account',
      icon: Icons.delete_forever_rounded,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final recaptchaToken = await showRecaptchaDialog(context);
    if (recaptchaToken == null || recaptchaToken.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(accountDeleteRepositoryProvider).requestAccountDeletion(
            email: _accountEmail,
            reason: _reasonCtrl.text.trim(),
            recaptchaToken: recaptchaToken,
          );
      if (mounted) setState(() => _submitted = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The deletion request is always for the signed-in account: take its
    // email from the session, falling back to the profile API.
    final sessionEmail = ref.watch(authControllerProvider).user?.email;
    final profileEmail = ref.watch(profileProvider).valueOrNull?['email']?.toString();
    final accountEmail = (sessionEmail != null && sessionEmail.isNotEmpty) ? sessionEmail : (profileEmail ?? '');
    _accountEmail = accountEmail;

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: const AffHeader(title: 'Delete account', subtitle: 'Permanently remove your data'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: _submitted ? const _SubmittedState() : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return AffCard(
      padding: const EdgeInsets.all(18),
      child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AffColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AffColors.danger, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'This action is irreversible. Your account and all associated data will be permanently deleted.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Account email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(_accountEmail),
            initialValue: _accountEmail,
            readOnly: true,
            enableInteractiveSelection: false,
            style: const TextStyle(color: AffColors.inkMuted, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Loading your account email…',
              prefixIcon: Icon(Icons.mail_outline),
              suffixIcon: Icon(Icons.lock_outline_rounded, size: 18),
              helperText: 'Deletion applies to the account you are signed in with',
            ),
            validator: (_) => _accountEmail.isEmpty ? 'Could not load your account email — go back and try again' : null,
          ),
          const SizedBox(height: 16),
          const Text('Reason for leaving *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _reasonCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Tell us why you want to delete your account (required)'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AffColors.danger, minimumSize: const Size(64, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit deletion request'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Need help? support@loothat.com',
              style: const TextStyle(color: AffColors.inkMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _SubmittedState extends StatelessWidget {
  const _SubmittedState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AffColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: AffColors.success, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Request submitted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            "We've received your account deletion request and will process it shortly.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AffColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
