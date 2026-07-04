import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'skill_list_screen.dart';
import 'add_skill_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool showNearby = true;
  Position? _currentPosition;
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadNotifCount();
  }

  Future<void> _loadNotifCount() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final count = await api.fetchNotificationCount();
      if (mounted) setState(() => _notifCount = count);
    } catch (_) {}
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
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _loadNotifCount());
                      },
                    ),
                    if (_notifCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '$_notifCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
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
       bottomNavigationBar: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           if (AdService().bannerAd != null)
             Container(
               alignment: Alignment.center,
               width: AdSize.banner.width.toDouble(),
               height: AdSize.banner.height.toDouble(),
               child: AdWidget(ad: AdService().bannerAd!),
             ),
           NavigationBar(
             selectedIndex: _currentIndex,
             onDestinationSelected: (i) => setState(() => _currentIndex = i),
             destinations: [
               NavigationDestination(icon: const Icon(Icons.explore), label: AppStrings.get('explore', lang: context.watch<SettingsService>().language)),
               NavigationDestination(icon: const Icon(Icons.add_circle), label: AppStrings.get('add_skill', lang: context.watch<SettingsService>().language)),
               NavigationDestination(icon: const Icon(Icons.person), label: AppStrings.get('profile', lang: context.watch<SettingsService>().language)),
             ],
           ),
         ],
       ),
    );
  }

  String? _selectedCategory;

  List<Map<String, dynamic>> get _topCategories => [
    {'name': null, 'icon': Icons.grid_view, 'label': 'All'},
    {'name': 'Tutor', 'icon': Icons.school},
    {'name': 'Music', 'icon': Icons.music_note},
    {'name': 'Technology', 'icon': Icons.computer},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Cooking', 'icon': Icons.restaurant},
    {'name': 'Art', 'icon': Icons.palette},
  ];

  Widget _buildExplore() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/skill_banner.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _topCategories.map((cat) {
              final name = cat['name'] as String?;
              final label = cat['label'] as String? ?? name;
              final selected = _selectedCategory == name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16),
                  label: Text(label ?? '', style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (val) {
                    setState(() => _selectedCategory = val ? name : null);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        Expanded(
          child: SkillListScreen(
            isNearby: showNearby,
            currentPosition: _currentPosition,
            userSocietyId: Hive.box('user_box').get('society_id'),
            categoryFilter: _selectedCategory,
          ),
        ),
      ],
    );
  }
}
