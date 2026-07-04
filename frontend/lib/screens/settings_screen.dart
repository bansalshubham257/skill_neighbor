import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final lang = settings.language;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('settings', lang: lang))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              AppStrings.get('language', lang: lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'hi', label: Text('हिन्दी')),
              ],
              selected: {lang},
              onSelectionChanged: (v) => settings.setLanguage(v.first),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(
              AppStrings.get('theme', lang: lang),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'light', label: Text(AppStrings.get('light', lang: lang))),
                ButtonSegment(value: 'dark', label: Text(AppStrings.get('dark', lang: lang))),
                ButtonSegment(value: 'system', label: Text(AppStrings.get('system', lang: lang))),
              ],
              selected: {_themeKey(settings.themeMode)},
              onSelectionChanged: (v) => settings.setTheme(v.first),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text(AppStrings.get('privacy', lang: lang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(AppStrings.get('terms', lang: lang)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
          ),
        ],
      ),
    );
  }

  String _themeKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
      default: return 'system';
    }
  }
}
