import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart' show AppColors;
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/payout_validators.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../profile/presentation/edit_account_screen.dart';
import '../../profile/presentation/profile_providers.dart';
import 'wallet_providers.dart';
import '../../../../core/widgets/app_toast.dart';

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'upi';
  final _amountCtrl = TextEditingController();
  bool _submitting = false;

  /// Payout details saved under Profile → Edit account. They're shown
  /// read-only here — changing them happens on the profile page only.
  String _upi = '';
  String _accNo = '';
  String _ifsc = '';
  Map<String, dynamic>? _profile;
  bool _profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayoutDetails(chooseType: true);
  }

  Future<void> _loadPayoutDetails({bool chooseType = false}) async {
    setState(() => _profileLoading = true);
    try {
      final p = await ref.read(profileProvider.future);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _upi = p['upi']?.toString().trim() ?? '';
        _accNo = p['accNo']?.toString().trim() ?? '';
        _ifsc = p['ifsc']?.toString().trim().toUpperCase() ?? '';
        // Open on Bank when that's the only method saved.
        if (chooseType && _upi.isEmpty && _accNo.isNotEmpty) _type = 'bank';
      });
    } catch (_) {
      // Offline / not loaded — treated as "nothing saved".
    } finally {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  /// Saved details exist for the chosen method and pass the same checks as
  /// Edit account (older accounts may have invalid values saved).
  bool get _hasDetailsForType => _hasDetails(_type);

  bool _hasDetails(String type) =>
      type == 'upi' ? PayoutValidators.isValidUpi(_upi) : (PayoutValidators.isValidAccount(_accNo) && PayoutValidators.isValidIfsc(_ifsc));

  Future<void> _openEditAccount() async {
    final profile = _profile;
    if (profile == null) {
      showWarningToast(context, 'Could not load your profile. Please try again.');
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditAccountScreen(profile: profile)));
    if (!mounted) return;
    ref.invalidate(profileProvider);
    await _loadPayoutDetails();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gatewayAsync = ref.watch(gatewayStatusProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: gatewayAsync.when(
            loading: () => const SizedBox(height: 200, child: LoadingState(compact: true)),
            error: (e, _) => ErrorState(message: 'Could not load withdrawal options.\n$e'),
            data: (activeTypes) {
              if (!activeTypes.contains(_type) && activeTypes.isNotEmpty) {
                _type = activeTypes.first;
              }
              return Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                    ),
                    Text('Withdraw funds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: AffColors.ink)),
                    const SizedBox(height: 16),
                    if (activeTypes.isEmpty)
                      const EmptyState(message: 'Withdrawals are currently unavailable', icon: Icons.block)
                    else ...[
                      _PayoutTypeToggle(
                        activeTypes: activeTypes,
                        selected: _type,
                        // Only gray out an unset-up method once the other one
                        // actually has saved details — a brand-new account
                        // with nothing saved yet should still show both as
                        // tappable so the warning card below can guide setup.
                        enabledTypes: _profileLoading || !activeTypes.any(_hasDetails) ? activeTypes : activeTypes.where(_hasDetails).toList(),
                        onSelect: (t) => setState(() => _type = t),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [InputRules.amount(max: 50000)],
                        decoration: const InputDecoration(labelText: 'Amount (₹10 - ₹50,000)'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 10 || n > 50000) return 'Enter an amount between ₹10 and ₹50,000';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _PayoutDetailsCard(
                        type: _type,
                        upi: _upi,
                        accNo: _accNo,
                        ifsc: _ifsc,
                        loading: _profileLoading,
                        onChange: _openEditAccount,
                      ),
                      const SizedBox(height: 20),
                      GradientButton(label: 'Submit request', loading: _submitting, onPressed: _hasDetailsForType ? () => _submit(context) : null),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_hasDetailsForType) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(walletRepositoryProvider).withdraw(
            type: _type,
            amount: double.parse(_amountCtrl.text),
            upiId: _type == 'upi' ? _upi : null,
            accountNo: _type == 'bank' ? _accNo : null,
            ifscCode: _type == 'bank' ? _ifsc : null,
          );
      if (!context.mounted) return;
      final success = result['success'] == true;
      Navigator.pop(context);
      showToast(
        context,
        result['message']?.toString() ?? (success ? 'Withdrawal requested' : 'Withdrawal failed'),
        type: success ? ToastType.success : ToastType.error,
        title: success ? 'Withdrawal requested' : null,
      );
    } catch (e) {
      if (context.mounted) {
        showErrorToast(context, e);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// UPI/Bank toggle where a method the user hasn't saved details for shows
/// greyed-out and ignores taps, instead of looking selectable like the rest.
class _PayoutTypeToggle extends StatelessWidget {
  const _PayoutTypeToggle({required this.activeTypes, required this.selected, required this.enabledTypes, required this.onSelect});

  final List<String> activeTypes;
  final String selected;
  final List<String> enabledTypes;
  final ValueChanged<String> onSelect;

  static const _labels = {'upi': ('UPI', Icons.qr_code_rounded), 'bank': ('Bank', Icons.account_balance_rounded)};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AffColors.fieldBorder)),
      child: Row(
        children: [
          for (final type in activeTypes) ...[
            if (type != activeTypes.first) const SizedBox(width: 4),
            Expanded(child: _segment(type)),
          ],
        ],
      ),
    );
  }

  Widget _segment(String type) {
    final isSelected = type == selected;
    final isEnabled = enabledTypes.contains(type);
    final (label, icon) = _labels[type] ?? (type, Icons.payment_rounded);
    final fg = !isEnabled ? AffColors.inkHint : (isSelected ? Colors.white : AffColors.inkLabel);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? () => onSelect(type) : null,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: 42,
          decoration: BoxDecoration(
            color: isSelected && isEnabled ? AffColors.purpleEnd : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: fg),
              const SizedBox(width: 6),
              Text(label, style: AffText.jakarta(13.5, FontWeight.w700, color: fg)),
              if (!isEnabled) ...[const SizedBox(width: 5), Icon(Icons.lock_rounded, size: 12, color: fg)],
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only "Paying to" summary of the saved UPI / bank details, with a
/// Change link to Edit account. When nothing is saved for the chosen method
/// it asks the user to add it there instead.
class _PayoutDetailsCard extends StatelessWidget {
  const _PayoutDetailsCard({
    required this.type,
    required this.upi,
    required this.accNo,
    required this.ifsc,
    required this.loading,
    required this.onChange,
  });

  final String type;
  final String upi;
  final String accNo;
  final String ifsc;
  final bool loading;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AffColors.fieldBorder)),
        child: const BrandSpinner(size: 20),
      );
    }

    final isUpi = type == 'upi';
    final saved = isUpi ? upi.isNotEmpty : (accNo.isNotEmpty && ifsc.isNotEmpty);
    final valid = isUpi ? PayoutValidators.isValidUpi(upi) : (PayoutValidators.isValidAccount(accNo) && PayoutValidators.isValidIfsc(ifsc));

    if (!saved || !valid) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.warningMuted, borderRadius: BorderRadius.circular(16), border: Border.all(color: AffColors.warning.withValues(alpha: 0.35))),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AffColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                !saved
                    ? (isUpi ? 'No UPI ID saved yet. Add it in your profile to withdraw.' : 'No bank account saved yet. Add it in your profile to withdraw.')
                    : (isUpi ? 'Your saved UPI ID ($upi) is not valid. Update it in your profile to withdraw.' : 'Your saved bank details are not valid. Update them in your profile to withdraw.'),
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AffColors.inkLabel, height: 1.35),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: onChange, child: Text(saved ? 'Update' : 'Add')),
          ],
        ),
      );
    }

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: [
              SizedBox(width: 78, child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AffColors.inkFaint))),
              Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AffColors.ink))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AffColors.fieldBorder)),
      child: Row(
        children: [
          AffIconChip(icon: isUpi ? Icons.qr_code_rounded : Icons.account_balance_rounded, size: 38, solid: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('PAYING TO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AffColors.inkFaint)),
                    const SizedBox(width: 6),
                    Icon(Icons.lock_rounded, size: 11, color: AffColors.inkFaint),
                  ],
                ),
                const SizedBox(height: 4),
                if (isUpi) row('UPI ID', upi) else ...[row('Account', accNo), row('IFSC', ifsc)],
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}
