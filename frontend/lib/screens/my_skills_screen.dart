import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'add_skill_screen.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key});

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  List<dynamic> _skills = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.fetchMySkills();
      setState(() { _skills = list; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(dynamic skill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: Text('Delete "${skill['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Provider.of<ApiService>(context, listen: false).deleteSkill(skill['id']);
      _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data?['detail'] ?? e.message}')),
        );
      }
    }
  }

  void _edit(dynamic skill) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => AddSkillScreen(existingSkill: skill, onSkillAdded: _load),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Skills')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _skills.isEmpty
              ? const Center(child: Text('No skills yet. Add one!', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _skills.length,
                    itemBuilder: (context, index) {
                      final s = _skills[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(s['category'] != null
                              ? s['category'].toString()[0] : '?')),
                          title: Text(s['title'] ?? ''),
                          subtitle: Text('${s['category']} \· \$${s['hourly_rate'] ?? 'Negotiable'}/hr'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') _edit(s);
                              if (v == 'delete') _delete(s);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(
                                leading: Icon(Icons.edit), title: Text('Edit'), dense: true)),
                              const PopupMenuItem(value: 'delete', child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
