import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import 'custom_domains_providers.dart';

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _verify(String id) async {
    try {
      final result = await ref.read(customDomainsRepositoryProvider).verifyDomain(id);
      if (!mounted) return;
      final verified = result['alreadyVerified'] == true || result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? (verified ? 'Domain verified' : 'Verification pending'))),
      );
      ref.invalidate(customDomainsProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(customDomainsRepositoryProvider).deleteDomain(id);
      ref.invalidate(customDomainsProvider);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(customDomainsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: const PortalHeader(title: 'Custom Domains'),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(customDomainsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            if (_pendingInstructions != null) ...[
              const SizedBox(height: 16),
              _DnsInstructionsCard(instructions: _pendingInstructions!, onDismiss: () => setState(() => _pendingInstructions = null)),
            ],
            const SizedBox(height: 24),
            const SectionHeader(title: 'Your domains'),
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
    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dns_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
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
        SizedBox(width: 50, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.language, color: verified ? AppColors.success : Colors.grey),
        title: Text(domain['domain']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: StatusChip(text: verified ? 'Verified' : 'Pending', color: verified ? AppColors.success : AppColors.warning),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!verified)
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Check DNS', onPressed: onVerify),
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
