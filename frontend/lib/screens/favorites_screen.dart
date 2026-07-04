import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'skill_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('bookmarks_box').listenable(),
        builder: (context, box, _) {
          final skills = box.values.toList();
          return skills.isEmpty
              ? const Center(child: Text('No favorite skills yet.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final s = skills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(s['title'] ?? ''),
                        subtitle: Text(s['category'] ?? ''),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SkillDetailScreen(skill: s))),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }
}
