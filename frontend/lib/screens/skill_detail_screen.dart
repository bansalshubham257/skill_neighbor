import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class SkillDetailScreen extends StatefulWidget {
  final dynamic skill;
  const SkillDetailScreen({super.key, required this.skill});

  @override
  State<SkillDetailScreen> createState() => _SkillDetailScreenState();
}

class _SkillDetailScreenState extends State<SkillDetailScreen> {
  bool phoneUnlocked = false;
  bool isWatchingAd = false;

  Future<void> unlockPhone() async {
    setState(() => isWatchingAd = true);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      await api.claimReward('CONTACT');
      bool success = await api.consumeReward('CONTACT');
      if (success) {
        setState(() => phoneUnlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number unlocked!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to unlock. Try again.")),
      );
    } finally {
      setState(() => isWatchingAd = false);
    }
  }

  Future<void> _sendRequest(BuildContext context) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.sendRequest(widget.skill['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request sent!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final societyName = skill['society_name'];

    return Scaffold(
      appBar: AppBar(title: Text(skill['title'])),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(skill['category'],
              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(skill['description'], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          if (societyName != null)
            Row(
              children: [
                Icon(Icons.groups, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(societyName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          const SizedBox(height: 20),
          Text("Price: ${skill['hourly_rate'] ?? 'Negotiable'} / hr",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),

          // Disclaimer card
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We do not verify any person. Please use your own judgment before booking or sharing contact.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Center(
            child: isWatchingAd
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: phoneUnlocked ? null : unlockPhone,
                    icon: const Icon(Icons.phone),
                    label: Text(phoneUnlocked ? "Contact Available" : "Watch Ad to see Phone"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: phoneUnlocked ? Colors.grey : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
          ),

          if (phoneUnlocked)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  skill['phone_number'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          // Only show request button if skill doesn't belong to current user
          if (skill['user_id'] != Provider.of<ApiService>(context).userId)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _sendRequest(context),
                  icon: const Icon(Icons.handshake),
                  label: const Text("Send Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
