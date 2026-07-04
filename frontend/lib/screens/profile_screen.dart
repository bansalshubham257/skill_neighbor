import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'add_skill_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLeaving = false;

  void _logout(BuildContext context) {
    Hive.box('user_box').clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _leaveSociety() async {
    setState(() => _isLeaving = true);
    try {
      await Provider.of<ApiService>(context, listen: false).leaveSociety();
      await Hive.box('user_box').delete('society_id');
      await Hive.box('user_box').delete('society_name');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left society')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final userId = api.userId;
    final box = Hive.box('user_box');
    final email = box.get('email', defaultValue: '');
    final username = box.get('username', defaultValue: 'User');
    final societyName = box.get('society_name');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(username.toString()[0].toUpperCase()),
          ),
          const SizedBox(height: 16),
          Text('@$username',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (email != null && email.toString().isNotEmpty)
            Text('$email',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          Text('User ID: $userId',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
          if (societyName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Society: $societyName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange)),
            ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add a Skill'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddSkillScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.add_home_outlined),
            title: const Text('Create / Join Society'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/add-society'),
          ),
          if (societyName != null)
            ListTile(
              leading: _isLeaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Leave $societyName',
                  style: const TextStyle(color: Colors.red)),
              onTap: _isLeaving ? null : _leaveSociety,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
