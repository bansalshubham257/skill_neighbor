import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import 'skill_list_screen.dart';
import 'add_skill_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool showNearby = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission needed for nearby search')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentPosition = pos);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildExplore(),
      AddSkillScreen(onSkillAdded: () => setState(() => _currentIndex = 0)),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: _currentIndex == 0
          ? AppBar(
              title: const Text('SkillNeighbor'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    setState(() => _currentIndex = 2);
                  },
                ),
              ],
            )
          : null,
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.explore), label: AppStrings.get('explore', lang: context.watch<SettingsService>().language)),
          NavigationDestination(icon: const Icon(Icons.add_circle), label: AppStrings.get('add_skill', lang: context.watch<SettingsService>().language)),
          NavigationDestination(icon: const Icon(Icons.person), label: AppStrings.get('profile', lang: context.watch<SettingsService>().language)),
        ],
      ),
    );
  }

  Widget _buildExplore() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                  value: true,
                  label: Text(AppStrings.get('nearby', lang: context.watch<SettingsService>().language)),
                  icon: const Icon(Icons.map)),
              ButtonSegment(
                  value: false,
                  label: Text(AppStrings.get('my_society', lang: context.watch<SettingsService>().language)),
                  icon: const Icon(Icons.home)),
            ],
            selected: {showNearby},
            onSelectionChanged: (val) {
              setState(() => showNearby = val.first);
            },
          ),
        ),
        if (_currentPosition != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '📍 ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        Expanded(
          child: SkillListScreen(
            isNearby: showNearby,
            currentPosition: _currentPosition,
            userSocietyId: Hive.box('user_box').get('society_id'),
          ),
        ),
      ],
    );
  }
}
