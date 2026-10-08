import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

/// Create/edit offer form — covers the exact column list used by
/// createOffer()/updateOffer() in adminOfferService.js: offer_name,
/// offer_title, category, type, steps, offer_benefits, offer_fees_charges,
/// terms, advertiser, advertiser_po, offer_url, logo, banner_image, 5 event
/// groups (eve_N, eve_N_name, eve_N_user_po, eve_N_refer_po, eve_N_pay_time),
/// 3 input groups (input_N, input_N_type), conversion_event, caps, pay_time,
/// pay_method, pay_method1, gateway_user, gateway_refer, visibility,
/// offer_status, manual_event, offer_comm, pay_limit.
class AdminOfferFormScreen extends ConsumerStatefulWidget {
  const AdminOfferFormScreen({super.key, this.offId});

  final String? offId;

  @override
  ConsumerState<AdminOfferFormScreen> createState() => _AdminOfferFormScreenState();
}

class _AdminOfferFormScreenState extends ConsumerState<AdminOfferFormScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _offerStatus = 'inactive';
  String _visibility = 'all';
  List<Map<String, dynamic>> _gateways = [];

  static const _textFields = [
    'offer_name', 'offer_title', 'category', 'type', 'steps', 'offer_benefits',
    'offer_fees_charges', 'terms', 'advertiser', 'advertiser_po', 'offer_url',
    'logo', 'banner_image', 'conversion_event', 'caps', 'pay_time',
    'pay_method', 'pay_method1', 'gateway_user', 'gateway_refer',
    'manual_event', 'offer_comm', 'pay_limit',
  ];

  static const _eventNums = [1, 2, 3, 4, 5];
  static const _inputNums = [1, 2, 3];

  bool get isEdit => widget.offId != null;

  @override
  void initState() {
    super.initState();
    for (final f in _textFields) {
      _controllers[f] = TextEditingController();
    }
    for (final n in _eventNums) {
      _controllers['eve_$n'] = TextEditingController();
      _controllers['eve_${n}_name'] = TextEditingController();
      _controllers['eve_${n}_user_po'] = TextEditingController();
      _controllers['eve_${n}_refer_po'] = TextEditingController();
      _controllers['eve_${n}_pay_time'] = TextEditingController();
    }
    for (final n in _inputNums) {
      _controllers['input_$n'] = TextEditingController();
      _controllers['input_${n}_type'] = TextEditingController();
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _gateways = await ref.read(adminRepositoryProvider).getOfferGateways();
      if (isEdit) {
        final offer = await ref.read(adminRepositoryProvider).getOfferDetail(widget.offId!);
        offer.forEach((key, value) {
          if (_controllers.containsKey(key) && value != null) {
            _controllers[key]!.text = value.toString();
          }
        });
        _offerStatus = offer['offer_status']?.toString() ?? 'inactive';
        _visibility = offer['visibility']?.toString() ?? 'all';
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _collectFields() {
    final fields = <String, dynamic>{};
    _controllers.forEach((key, ctrl) => fields[key] = ctrl.text);
    fields['offer_status'] = _offerStatus;
    fields['visibility'] = _visibility;
    return fields;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = isEdit ? await repo.updateOffer(widget.offId!, _collectFields()) : await repo.createOffer(_collectFields());
      if (!mounted) return;
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (success ? 'Saved' : 'Failed to save')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
      if (success) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicate() async {
    if (!isEdit) return;
    try {
      final result = await ref.read(adminRepositoryProvider).duplicateOffer(widget.offId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Duplicated')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete() async {
    if (!isEdit) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete offer?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRepositoryProvider).deleteOffer(widget.offId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(
        title: isEdit ? 'Edit offer' : 'New offer',
        actions: isEdit
            ? [
                IconButton(icon: const Icon(Icons.copy_outlined), tooltip: 'Duplicate', onPressed: _duplicate),
                IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: _delete),
              ]
            : null,
      ),
      body: _loading
          ? const LoadingState()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    const SectionHeader(title: 'Basics'),
                    _field('offer_name', 'Offer name'),
                    _field('offer_title', 'Offer title'),
                    _field('category', 'Category'),
                    _field('type', 'Type'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _offerStatus,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: const ['live', 'inactive', 'paused'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _offerStatus = v ?? _offerStatus),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _visibility,
                            decoration: const InputDecoration(labelText: 'Visibility'),
                            items: const ['all', 'hidden'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (v) => setState(() => _visibility = v ?? _visibility),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Content'),
                    _field('steps', 'Steps', maxLines: 3),
                    _field('offer_benefits', 'Benefits', maxLines: 3),
                    _field('offer_fees_charges', 'Fees & charges', maxLines: 3),
                    _field('terms', 'Terms', maxLines: 3),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Media & links'),
                    _field('advertiser', 'Advertiser'),
                    _field('advertiser_po', 'Advertiser payout'),
                    _field('offer_url', 'Offer URL'),
                    _field('logo', 'Logo URL'),
                    _field('banner_image', 'Banner image URL'),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Payout routing'),
                    _field('pay_method', 'User pay method'),
                    _gatewayPicker('gateway_user', 'User gateway'),
                    _field('pay_method1', 'Refer pay method'),
                    _gatewayPicker('gateway_refer', 'Refer gateway'),
                    _field('pay_time', 'Pay time'),
                    _field('pay_limit', 'Pay limit'),
                    _field('caps', 'Caps'),
                    _field('conversion_event', 'Conversion event'),
                    _field('manual_event', 'Manual event'),
                    _field('offer_comm', 'Offer commission'),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Events'),
                    for (final n in _eventNums) _eventGroup(n),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Inputs'),
                    for (final n in _inputNums) _inputGroup(n),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEdit ? 'Save changes' : 'Create offer'),
                    ),
                  ],
                ),
    );
  }

  Widget _field(String key, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: _controllers[key], maxLines: maxLines, decoration: InputDecoration(labelText: label)),
    );
  }

  Widget _gatewayPicker(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _controllers[key]!.text.isEmpty ? null : _controllers[key]!.text,
        decoration: InputDecoration(labelText: label),
        items: _gateways
            .map((g) => DropdownMenuItem(value: g['id'].toString(), child: Text('${g['gname']} (${g['gtype']})')))
            .toList(),
        onChanged: (v) => setState(() => _controllers[key]!.text = v ?? ''),
      ),
    );
  }

  Widget _eventGroup(int n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event $n', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _field('eve_$n', 'Event $n key'),
            _field('eve_${n}_name', 'Event $n name'),
            Row(
              children: [
                Expanded(child: _field('eve_${n}_user_po', 'User payout')),
                const SizedBox(width: 10),
                Expanded(child: _field('eve_${n}_refer_po', 'Refer payout')),
              ],
            ),
            _field('eve_${n}_pay_time', 'Pay time (disabled if total = ₹1)'),
          ],
        ),
      ),
    );
  }

  Widget _inputGroup(int n) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input $n', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _field('input_$n', 'Label'),
            _field('input_${n}_type', 'Type'),
          ],
        ),
      ),
    );
  }
}
