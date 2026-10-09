import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'custom_domains_providers.dart';
import '../../../../core/widgets/app_toast.dart';

// Mirrors the Next.js form's HTML5 pattern:
// ^(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.[A-Za-z0-9-]{1,63})+$
final _domainRegex = RegExp(
  r'^(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.[A-Za-z0-9-]{1,63})+$',
);

class CustomDomainsScreen extends ConsumerStatefulWidget {
  const CustomDomainsScreen({super.key});

  @override
  ConsumerState<CustomDomainsScreen> createState() => _CustomDomainsScreenState();
}

class _CustomDomainsScreenState extends ConsumerState<CustomDomainsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _domainCtrl = TextEditingController();
  bool _adding = false;
  Map<String, dynamic>? _pendingInstructions;

  @override
  void dispose() {
    _domainCtrl.dispose();
    super.dispose();
  }

  Future<void> _addDomain() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _adding = true);
    try {
      final result = await ref.read(customDomainsRepositoryProvider).addDomain(_domainCtrl.text.trim());
      if (!mounted) return;
      setState(() => _pendingInstructions = result);
      _domainCtrl.clear();
      ref.invalidate(customDomainsProvider);
    } on ApiException catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _verify(String id) async {
    try {
      final result = await ref.read(customDomainsRepositoryProvider).verifyDomain(id);
      if (!mounted) return;
      final verified = result['alreadyVerified'] == true || result['success'] == true;
      showToast(
        context,
        result['message']?.toString() ?? (verified ? 'Domain verified' : 'Verification pending'),
        type: verified ? ToastType.success : ToastType.warning,
      );
      ref.invalidate(customDomainsProvider);
    } on ApiException catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  Future<void> _remove(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove domain?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AffColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(customDomainsRepositoryProvider).deleteDomain(id);
      ref.invalidate(customDomainsProvider);
    } on ApiException catch (e) {
      if (mounted) showErrorToast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(customDomainsProvider);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: const AffHeader(title: 'Custom domains', subtitle: 'Use your own link domain'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customDomainsProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            AffCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connect a domain', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AffColors.ink)),
                  const SizedBox(height: 12),
                  Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _domainCtrl,
                      decoration: const InputDecoration(hintText: 'yourdomain.com'),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Required';
                        if (!_domainRegex.hasMatch(value)) return 'Enter a valid domain';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _adding ? null : _addDomain,
                    child: _adding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Add'),
                  ),
                ],
              ),
            ),
                ],
              ),
            ),
            if (_pendingInstructions != null) ...[
              const SizedBox(height: 16),
              _DnsInstructionsCard(instructions: _pendingInstructions!, onDismiss: () => setState(() => _pendingInstructions = null)),
            ],
            const SizedBox(height: 24),
            const AffSectionHeader(title: 'Your domains'),
            domainsAsync.when(
              loading: () => const SizedBox(height: 120, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(message: 'Failed to load domains.\n$e', onRetry: () => ref.invalidate(customDomainsProvider)),
              data: (domains) {
                if (domains.isEmpty) {
                  return const EmptyState(message: 'No custom domains yet', icon: Icons.public_off_outlined);
                }
                return Column(
                  children: [
                    for (final d in domains)
                      _DomainTile(
                        domain: d,
                        onVerify: () => _verify(d['id'].toString()),
                        onRemove: () => _remove(d['id'].toString()),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DnsInstructionsCard extends StatelessWidget {
  const _DnsInstructionsCard({required this.instructions, required this.onDismiss});

  final Map<String, dynamic> instructions;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final domain = instructions['domain']?.toString() ?? '';
    final token = instructions['verificationToken']?.toString() ?? '';
    return AffCard(
      padding: const EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AffIconChip(icon: Icons.dns_rounded, size: 36, solid: true),
                const SizedBox(width: 10),
                const Expanded(child: Text('Add this DNS TXT record', style: TextStyle(fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onDismiss),
              ],
            ),
            const SizedBox(height: 10),
            _DnsRow(label: 'Host', value: '_loothat.$domain'),
            const SizedBox(height: 6),
            _DnsRow(label: 'Value', value: token),
          ],
        ),
      ),
    );
  }
}

class _DnsRow extends StatelessWidget {
  const _DnsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(color: AffColors.inkMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(
          child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5)),
        ),
      ],
    );
  }
}

class _DomainTile extends StatelessWidget {
  const _DomainTile({required this.domain, required this.onVerify, required this.onRemove});

  final Map<String, dynamic> domain;
  final VoidCallback onVerify;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final verified = domain['verified'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AffCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AffIconChip(icon: Icons.language_rounded, color: verified ? AffColors.success : AffColors.warning, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(domain['domain']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AffColors.ink)),
                  const SizedBox(height: 5),
                  StatusChip(text: verified ? 'Verified' : 'Pending', color: verified ? AffColors.success : AffColors.warning),
                ],
              ),
            ),
            if (!verified) IconButton(icon: const Icon(Icons.refresh_rounded, color: AffColors.purpleEnd), tooltip: 'Check DNS', onPressed: onVerify),
            IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AffColors.danger), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
