import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'add_skill_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) async {
    await GoogleSignIn().signOut();
    Hive.box('user_box').clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final userId = api.userId;
    final box = Hive.box('user_box');
    final email = box.get('email', defaultValue: 'Not set');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(email.toString()[0].toUpperCase()),
          ),
          const SizedBox(height: 16),
          Text('User ID: $userId',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
          Text('Email: $email',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
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
