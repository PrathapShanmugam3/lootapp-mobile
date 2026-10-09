import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/input_formatters.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'profile_providers.dart';
import '../../../../core/widgets/app_toast.dart';

/// Edit account — account info (read-only) plus the editable payout details
/// and the change-password action, all in one place.
class EditAccountScreen extends ConsumerStatefulWidget {
  const EditAccountScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends ConsumerState<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _upiCtrl;
  late final TextEditingController _accNoCtrl;
  late final TextEditingController _ifscCtrl;
  bool _saving = false;

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

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final result = await ref.read(profileRepositoryProvider).updatePayoutDetails(upi: _upiCtrl.text, accNo: _accNoCtrl.text, ifsc: _ifscCtrl.text);
      if (!mounted) return;
      ref.invalidate(profileProvider);
      showSuccessToast(context, result['message']?.toString() ?? 'Payout details updated');
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p['name']?.toString() ?? '';
    final mobile = p['mobile']?.toString() ?? '';
    final initials = name.trim().isNotEmpty ? name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: const AffHeader(title: 'Edit account', subtitle: 'Payout details and security'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          FadeSlideIn(
            child: AffCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AffColors.gradient),
                    child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'Affiliate', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AffColors.ink)),
                        const SizedBox(height: 2),
                        Text(p['email']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AffColors.inkMuted)),
                        if (mobile.isNotEmpty) Text(mobile, style: const TextStyle(fontSize: 12.5, color: AffColors.inkMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.lock_outline_rounded, size: 18, color: AffColors.inkFaint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const FadeSlideIn(index: 1, child: AffSectionHeader(title: 'Payout details')),
          FadeSlideIn(
            index: 2,
            child: AffCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('UPI ID'),
                    TextFormField(
                      controller: _upiCtrl,
                      inputFormatters: InputRules.noSpaces(50),
                      decoration: const InputDecoration(hintText: 'name@bank', prefixIcon: Icon(Icons.qr_code_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+$').hasMatch(v.trim())) ? null : 'Enter a valid UPI ID',
                    ),
                    const SizedBox(height: 16),
                    _label('Bank account number'),
                    TextFormField(
                      controller: _accNoCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: InputRules.digits(18),
                      decoration: const InputDecoration(hintText: 'Account number', prefixIcon: Icon(Icons.account_balance_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[0-9]{9,18}$').hasMatch(v.trim())) ? null : 'Enter a valid account number',
                    ),
                    const SizedBox(height: 16),
                    _label('IFSC code'),
                    TextFormField(
                      controller: _ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: InputRules.alphanumericUpper(11),
                      decoration: const InputDecoration(hintText: 'e.g. HDFC0001234', prefixIcon: Icon(Icons.pin_rounded)),
                      validator: (v) => (v == null || v.trim().isEmpty || RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.trim().toUpperCase())) ? null : 'Enter a valid IFSC code',
                    ),
                    const SizedBox(height: 20),
                    GradientButton(label: 'Save payout details', icon: Icons.check_rounded, loading: _saving, onPressed: _save),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const FadeSlideIn(index: 3, child: AffSectionHeader(title: 'Security')),
          FadeSlideIn(
            index: 4,
            child: AffCard(
              padding: EdgeInsets.zero,
              onTap: () => showChangePasswordSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const AffIconChip(icon: Icons.lock_outline_rounded, size: 40),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Change password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AffColors.ink)),
                          SizedBox(height: 2),
                          Text('Keep your account secure', style: TextStyle(fontSize: 11.5, color: AffColors.inkFaint)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AffColors.inkFaint),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AffColors.ink)),
      );
}

void showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => const _ChangePasswordSheet(),
  );
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
      showToast(
        context,
        result['message']?.toString() ?? (success ? 'Password changed' : 'Failed to change password'),
        type: success ? ToastType.success : ToastType.error,
      );
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
