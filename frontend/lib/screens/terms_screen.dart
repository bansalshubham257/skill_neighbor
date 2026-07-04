import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          term('1. Acceptance',
            'By using SkillNeighbor, you agree to these terms. If you do not agree, do not use the app.'),
          term('2. User Conduct',
            'You agree to: (a) provide accurate information, (b) not misuse the platform, '
            '(c) respect other users, (d) comply with all applicable laws.'),
          term('3. Skill Listings',
            'You are solely responsible for the skills you list. We do not verify qualifications, '
            'certifications, or claims. Users should exercise caution.'),
          term('4. Transactions',
            'All transactions, payments, and service agreements are between users. '
            'SkillNeighbor is not a party to any user agreement.'),
          term('5. Limitation of Liability',
            'SkillNeighbor is provided "as is" without warranties. We are not liable for any '
            'damages arising from use of the platform, including but not limited to disputes between users.'),
          term('6. Privacy',
            'Your use is governed by our Privacy Policy. We respect your data and do not share it without consent.'),
          term('7. Changes',
            'We may update these terms. Continued use after changes constitutes acceptance.'),
        ],
      ),
    );
  }

  Widget term(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
