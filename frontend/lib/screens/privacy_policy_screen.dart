import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          section('Information We Collect',
            'We collect basic profile information (name, email), location data for nearby search, and skills you choose to list.'),
          section('How We Use Information',
            'Your information is used to connect you with neighbors for skill exchange. Location data enables nearby search.'),
          section('Data Sharing',
            'Your phone number is only visible to users who watch an ad to unlock it. We do not sell your data.'),
          section('User Responsibility',
            'We do not verify the identity, credentials, or background of any user. All interactions are at your own risk. '
            'SkillNeighbor is a platform for connection only and is not responsible for any disputes, damages, '
            'or issues arising from user interactions.'),
          Card(
            color: Colors.red.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We do not verify any person on this platform. '
                      'Users interact at their own risk. SkillNeighbor is not responsible '
                      'for any disputes, damages, or issues.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          section('Contact', 'Email: support@skillneighbor.app'),
        ],
      ),
    );
  }

  Widget section(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
