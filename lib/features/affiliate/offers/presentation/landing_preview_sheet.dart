import 'package:flutter/material.dart';

import '../../presentation/widgets/affiliate_design.dart';

/// Shows a native re-creation of the real landing page (classic / minimal /
/// bold — mirrors lootapp-ui's `/leads` page) with the offer's actual data,
/// as a tall modal sheet. No network call and no WebView: the data is
/// already loaded on the offer detail screen, and the three themes are
/// drawn directly in Flutter, so this never depends on a reachable site.
Future<void> showLandingPreviewSheet(
  BuildContext context, {
  required String themeKey,
  required String label,
  required String name,
  required String title,
  required String? logoUrl,
  required String? bannerUrl,
  required String category,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LandingPreviewSheet(
      themeKey: themeKey,
      label: label,
      name: name,
      title: title,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      category: category,
    ),
  );
}

class _LandingPreviewSheet extends StatelessWidget {
  const _LandingPreviewSheet({
    required this.themeKey,
    required this.label,
    required this.name,
    required this.title,
    required this.logoUrl,
    required this.bannerUrl,
    required this.category,
  });

  final String themeKey;
  final String label;
  final String name;
  final String title;
  final String? logoUrl;
  final String? bannerUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    final bg = switch (themeKey) {
      'minimal' => const Color(0xFFF8F8FB),
      'bold' => const Color(0xFF0A0A0A),
      _ => null, // classic: gradient, drawn below
    };
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: const Color(0xFF111111),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: bg,
                      decoration: themeKey != 'minimal' && themeKey != 'bold'
                          ? const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E1B4B),
                                  Color(0xFF1E3A8A),
                                  Color(0xFF581C87),
                                ],
                              ),
                            )
                          : null,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: switch (themeKey) {
                            'minimal' => _MinimalCard(
                              name: name,
                              title: title,
                              logoUrl: logoUrl,
                            ),
                            'bold' => _BoldCard(
                              name: name,
                              title: title,
                              logoUrl: logoUrl,
                            ),
                            _ => _ClassicCard(
                              name: name,
                              title: title,
                              logoUrl: logoUrl,
                              bannerUrl: bannerUrl,
                              category: category,
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _logoCircle(String? logoUrl, {double size = 80}) => ClipOval(
  child: Container(
    width: size,
    height: size,
    color: Colors.white.withValues(alpha: 0.2),
    child: logoUrl != null
        ? Image.network(
            logoUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        : null,
  ),
);

Widget _formPreview({
  required Color fieldFill,
  required Color fieldBorder,
  required Color labelColor,
  required Gradient? buttonGradient,
  required Color? buttonColor,
  required Color buttonTextColor,
}) {
  Widget field(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AffText.jakarta(11.5, FontWeight.w700, color: labelColor),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: fieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorder),
          ),
        ),
      ],
    ),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      field('UPI ID to receive payout'),
      field('Telegram User ID (Optional)'),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: buttonGradient,
          color: buttonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          'Continue to Offer',
          style: AffText.jakarta(14, FontWeight.w800, color: buttonTextColor),
        ),
      ),
    ],
  );
}

class _ClassicCard extends StatelessWidget {
  const _ClassicCard({
    required this.name,
    required this.title,
    required this.logoUrl,
    required this.bannerUrl,
    required this.category,
  });

  final String name;
  final String title;
  final String? logoUrl;
  final String? bannerUrl;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                ],
              ),
            ),
            child: Column(
              children: [
                _logoCircle(logoUrl),
                const SizedBox(height: 16),
                Text(
                  title.isEmpty ? name : title,
                  textAlign: TextAlign.center,
                  style: AffText.jakarta(
                    20,
                    FontWeight.w800,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                if (category.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: AffText.jakarta(
                        11,
                        FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Where should we send your money?',
                  textAlign: TextAlign.center,
                  style: AffText.jakarta(
                    15,
                    FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                _formPreview(
                  fieldFill: Colors.white,
                  fieldBorder: const Color(0xFFE2E8F0),
                  labelColor: const Color(0xFF64748B),
                  buttonGradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  buttonColor: null,
                  buttonTextColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalCard extends StatelessWidget {
  const _MinimalCard({
    required this.name,
    required this.title,
    required this.logoUrl,
  });

  final String name;
  final String title;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _logoCircle(logoUrl),
          const SizedBox(height: 14),
          Text(
            title.isEmpty ? name : title,
            textAlign: TextAlign.center,
            style: AffText.jakarta(
              19,
              FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete the steps to receive your reward.',
            textAlign: TextAlign.center,
            style: AffText.jakarta(
              12,
              FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),
          _formPreview(
            fieldFill: const Color(0xFFF8FAFC),
            fieldBorder: const Color(0xFFCBD5E1),
            labelColor: const Color(0xFF334155),
            buttonGradient: null,
            buttonColor: const Color(0xFF0F172A),
            buttonTextColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _BoldCard extends StatelessWidget {
  const _BoldCard({
    required this.name,
    required this.title,
    required this.logoUrl,
  });

  final String name;
  final String title;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _logoCircle(logoUrl, size: 90),
        const SizedBox(height: 18),
        Text(
          title.isEmpty ? name : title,
          textAlign: TextAlign.center,
          style: AffText.jakarta(
            28,
            FontWeight.w900,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Join thousands of users earning real cash today.',
          textAlign: TextAlign.center,
          style: AffText.jakarta(13, FontWeight.w500, color: Colors.white60),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2E2E2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Claim Your Reward',
                style: AffText.jakarta(
                  16,
                  FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              _formPreview(
                fieldFill: Colors.black,
                fieldBorder: const Color(0xFF3F3F46),
                labelColor: const Color(0xFF9CA3AF),
                buttonGradient: null,
                buttonColor: const Color(0xFFEAB308),
                buttonTextColor: Colors.black,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
