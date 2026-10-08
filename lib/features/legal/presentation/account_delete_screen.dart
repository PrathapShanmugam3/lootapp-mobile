import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/recaptcha_dialog.dart';
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
  final _emailCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final recaptchaToken = await showRecaptchaDialog(context);
    if (recaptchaToken == null || recaptchaToken.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(accountDeleteRepositoryProvider).requestAccountDeletion(
            email: _emailCtrl.text.trim(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: const PortalHeader(title: 'Delete Account'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _submitted ? const _SubmittedState() : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
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
          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your account email', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          const Text('Reason for leaving', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _reasonCtrl,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(hintText: 'Tell us why you want to delete your account'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please tell us why' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit deletion request'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Need help? support@loothat.com',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
            ),
          ),
        ],
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
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
          ),
          const SizedBox(height: 20),
          const Text('Request submitted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            "We've received your account deletion request and will process it shortly.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
