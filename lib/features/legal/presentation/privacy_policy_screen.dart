import 'package:flutter/material.dart';

import '../../../core/widgets/common.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _headingStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
  static const _bodyStyle = TextStyle(fontSize: 13.5, height: 1.5, color: Colors.black87);

  @override
  Widget build(BuildContext context) {
    final bodyStyle = _bodyStyle.copyWith(color: Colors.grey.shade800);
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: const PortalHeader(title: 'Privacy Policy'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'At Loot Hat, we prioritize your privacy and are committed to protecting your personal information. '
              'This Privacy Policy outlines the types of information we may collect from you, how we use it, your '
              'options regarding its use, and whether we share it with any third parties. If you have any questions '
              'or concerns about this policy, please feel free to reach out to us.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'At Loot Hat, accessible from loothat.com, safeguarding the privacy of our visitors is a top priority. '
              'This Privacy Policy outlines the types of information collected and recorded by Loot Hat, and how we '
              'utilize it.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'If you have any questions or need further details about our Privacy Policy, please do not hesitate '
              'to contact us.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'Please note that this Privacy Policy applies exclusively to our online activities and is valid for '
              'visitors to our website concerning the information they share and/or collect on Loot Hat. It does '
              'not apply to any information collected offline or through channels other than this website.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Consent', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'By using our website, you consent to our Privacy Policy and agree to its terms.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Information we collect', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'When we request personal information from you, we will clearly explain the reasons for collecting '
              'it at that time.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'If you contact us directly, we may collect additional details such as your name, email address, '
              'phone number, the content of your message and any attachments, as well as any other information '
              'you choose to provide.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'When you register for an account, we may ask for contact information including your name, address, '
              'email address, and telephone number.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('How we use your information', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'We use the information we collect in various ways, including to:',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text('• Provide, operate, and maintain our website', style: bodyStyle),
            const SizedBox(height: 4),
            Text('• Improve, personalize, and expand our website', style: bodyStyle),
            const SizedBox(height: 4),
            Text('• Understand and analyze how you use our website', style: bodyStyle),
            const SizedBox(height: 4),
            Text('• Develop new products, services, features, and functionality', style: bodyStyle),
            const SizedBox(height: 4),
            Text(
              '• Communicate with you, either directly or through one of our partners, including for customer '
              'service, to provide you with updates and other information relating to the website, and for '
              'marketing and promotional purposes',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text('• Send you emails', style: bodyStyle),
            const SizedBox(height: 4),
            Text('• Find and prevent fraud', style: bodyStyle),
            const SizedBox(height: 20),

            Text('Log Files', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Loot Hat users a standard procedure of using log files to record visitors’ activity on our '
              'website. This practice is common among hosting companies and forms part of their analytics '
              'services. The information collected in these log files includes IP addresses, browser type, '
              'Internet Service Provider (ISP), date and time stamps, referring/exit pages, and potentially the '
              'number of clicks. This data is not linked to personally identifiable information. We use this '
              'information to analyze trends, administer the site, track user movements, and gather demographic '
              'insights.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Our Advertising Partners', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Some of the advertisers on our site may use cookies and web beacons. Each of our advertising '
              'partners has its own Privacy Policy governing the handling of user data. For your convenience, we '
              'have provided hyperlinks to their Privacy Policies below.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Advertising Partners Privacy Policies', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'You can consult the list below to find the Privacy Policy for each of our advertising partners.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'Third-party ad servers or ad networks may use technologies such as cookies, JavaScript, or web '
              'beacons in their advertisements and links on Loot Hat. These technologies are sent directly to '
              'your browser, which automatically receives your IP address. They are used to measure the '
              'effectiveness of advertising campaigns and/or to personalize the advertising content you see on '
              'various websites.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'Please note that Loot Hat has no access to or control over the cookies used by third-party '
              'advertisers.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Third Party Privacy Policies', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Loot Hat’s Privacy Policy does not apply to other advertisers or websites. We recommend '
              'consulting the Privacy Policies of these third-party ad servers for more detailed information on '
              'their practices and instructions on how to opt-out of certain options.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'You can choose to disable cookies through your browser settings. For detailed information on '
              'cookie management with specific web browsers, please visit the respective websites of those '
              'browsers.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('CCPA Privacy Rights (Do Not Sell My Personal Information)', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Under the California Consumer Privacy Act (CCPA), California residents have the following rights:',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '• Request Disclosure: You can request that we disclose the categories and specific pieces of '
              'personal data we have collected about you.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Request Deletion: You can request that we delete any personal data we have collected about you.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• Request to Opt-Out: You can request that we do not sell your personal data.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'If you make a request, we will respond within one month. To exercise any of these rights, please '
              'contact us.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('GDPR Data Protection Rights', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'We want to ensure you are fully aware of your data protection rights. Every user is entitled to '
              'the following:',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '• The Right to Access: You can request copies of your personal data. A small fee may apply for '
              'this service.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• The Right to Rectification: You can request that we correct any inaccurate information or '
              'complete information that you believe is incomplete.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• The Right to Erasure: You can request that we erase your personal data, under certain '
              'conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• The Right to Restrict Processing: You can request that we restrict the processing of your '
              'personal data, under certain conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• The Right to Object to Processing: You can object to our processing of your personal data, '
              'under certain conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '• The Right to Data Portability: You can request that we transfer your data to another '
              'organization or directly to you, under certain conditions.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Children’s Information', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'Ensuring the safety of children online is a top priority for us. We encourage parents and '
              'guardians to monitor, participate in, and guide their children’s online activities.',
              style: bodyStyle,
            ),
            const SizedBox(height: 12),
            Text(
              'Loot Hat does not knowingly collect personally identifiable information from children under the '
              'age of 13. If you believe your child has provided such information on our website, please contact '
              'us immediately. We will make every effort to promptly remove it from our records.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),

            Text('Contact Us', style: _headingStyle),
            const SizedBox(height: 8),
            Text(
              'If you have any questions, concerns, or requests regarding this Privacy Policy or your personal '
              'information, please contact us at support@loothat.com.',
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
    );
  }
}
