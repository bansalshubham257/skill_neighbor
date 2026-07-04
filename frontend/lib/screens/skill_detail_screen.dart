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
      // Step 1: Claim token via ad simulation
      await api.claimReward('CONTACT');
      
      // Step 2: Consume token to unlock
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.skill['title'])),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.skill['category'], style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(widget.skill['description'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            Text("Price: ${widget.skill['hourly_rate'] ?? 'Negotiable'} / hr", 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            
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
                    widget.skill['phone_number'],
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
