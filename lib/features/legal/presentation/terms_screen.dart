import 'package:flutter/material.dart';

import '../../affiliate/presentation/widgets/affiliate_design.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _headingStyle = TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: AffColors.ink, letterSpacing: -0.2);
  static const _bodyStyle = TextStyle(fontSize: 13.5, height: 1.5, color: Colors.black87);

  @override
  Widget build(BuildContext context) {
    final bodyStyle = _bodyStyle.copyWith(color: AffColors.inkMuted);
    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: const AffHeader(title: 'Terms & Conditions', subtitle: 'Please read carefully'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            AffCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Text(
              'These Terms and Conditions govern your use of Loot Hat, accessible from loothat.com. By creating '
              'an account or using our website, you agree to be bound by these Terms in full. If you disagree '
              'with any part of these Terms, please do not use our website.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Accounts', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'When you create an account with us, you must provide accurate, complete, and current information '
              'at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate '
              'suspension or termination of your account.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'You are responsible for safeguarding the password you use to access the service and for any '
              'activities or actions under your password. You agree not to disclose your password to any third '
              'party.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Eligibility', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'You must be at least 13 years of age to use this website. By using Loot Hat, you represent and '
              'warrant that you meet this age requirement.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Offers and Rewards', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'By participating in offers, tasks, and reward programs on Loot Hat, you agree that:',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '• Rewards are credited only after an offer is verified as successfully completed by the offer '
              'provider.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Loot Hat is not responsible for delays, rejections, or non-crediting of rewards caused by '
              'third-party offer providers.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Any attempt to defraud, exploit, or abuse an offer, including the use of bots, multiple '
              'accounts, VPNs to bypass restrictions, or fake information, will result in forfeiture of rewards '
              'and account termination.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Loot Hat reserves the right to modify, suspend, or discontinue any offer at any time without '
              'prior notice.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Payments and Withdrawals', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Withdrawal requests are processed subject to verification of your account and activity. Loot Hat '
              'reserves the right to hold, delay, or decline a withdrawal if fraudulent activity is suspected.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'Minimum withdrawal thresholds, processing times, and available payment methods may change at any '
              'time and will be reflected on the withdrawal page.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Prohibited Conduct', style: _headingStyle),
            const SizedBox(height: 8),
            Text('You agree not to:', style: bodyStyle),
            const SizedBox(height: 8),
            Text(
              '• Create multiple accounts to claim the same offer, bonus, or referral reward more than once.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Use automated scripts, bots, emulators, or any tool to interact with the website or complete '
              'offers.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Provide false, misleading, or fraudulent information during signup or offer completion.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Attempt to gain unauthorized access to any part of the website, other accounts, or our systems.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Referral Program', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Referral rewards are credited only when the referred user completes the required qualifying '
              'actions. Loot Hat reserves the right to revoke referral rewards obtained through self-referral, '
              'fake accounts, or any other abuse of the program.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Intellectual Property', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Unless otherwise stated, Loot Hat and/or its licensors own the intellectual property rights for '
              'all material on this website. All intellectual property rights are reserved. You may access this '
              'from Loot Hat for your own personal use, subject to restrictions set in these Terms.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Termination', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'We may suspend or terminate your account and access to the service immediately, without prior '
              'notice, for conduct that we believe violates these Terms, is fraudulent, or is harmful to other '
              'users, us, or third parties.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Limitation of Liability', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Loot Hat, its directors, employees, and affiliates will not be held liable for any indirect, '
              'incidental, or consequential damages arising from your use of, or inability to use, the website, '
              'including but not limited to loss of rewards, data, or earnings.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Changes to These Terms', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'We reserve the right to modify these Terms at any time. Changes take effect immediately upon '
              'posting to this page. Your continued use of the website after changes are posted constitutes '
              'acceptance of the revised Terms.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Governing Law', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'These Terms shall be governed by and construed in accordance with the laws of India, without '
              'regard to its conflict of law provisions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Contact Us', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'If you have any questions about these Terms and Conditions, please contact us at '
              'support@loothat.com.',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Address: Nadia, West Bengal, India, 741152',
              style: bodyStyle,
            ),
          ],
        ),
            ),
          ],
        ),
      ),
    );
  }
}
