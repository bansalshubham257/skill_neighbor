import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'add_skill_screen.dart';
import 'my_skills_screen.dart';
import 'settings_screen.dart';

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
    final settings = context.watch<SettingsService>();
    final lang = settings.language;
    final api = Provider.of<ApiService>(context);
    final userId = api.userId;
    final box = Hive.box('user_box');
    final email = box.get('email', defaultValue: '');
    final username = box.get('username', defaultValue: 'User');
    final societyId = box.get('society_id');
    final societyName = box.get('society_name');
    final hasSociety = societyId != null;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('profile', lang: lang))),
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
          if (hasSociety)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Society: $societyName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange)),
            ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: Text(AppStrings.get('add_skill', lang: lang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddSkillScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: Text(AppStrings.get('my_skills', lang: lang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MySkillsScreen())),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
              'Society',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_home_outlined),
            title: Text(hasSociety ? 'Change Society' : 'Create / Join Society'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.pushNamed(context, '/add-society'),
          ),
          if (hasSociety)
            ListTile(
              leading: _isLeaving
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.exit_to_app, color: Colors.red),
              title: Text('Leave $societyName',
                  style: const TextStyle(color: Colors.red)),
              onTap: _isLeaving ? null : _leaveSociety,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppStrings.get('settings', lang: lang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(AppStrings.get('logout', lang: lang),
                style: const TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
