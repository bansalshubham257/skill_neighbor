import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class ChooseSocietyScreen extends StatefulWidget {
  const ChooseSocietyScreen({super.key});

  @override
  State<ChooseSocietyScreen> createState() => _ChooseSocietyScreenState();
}

class _ChooseSocietyScreenState extends State<ChooseSocietyScreen> {
  List<dynamic> _societies = [];
  bool _loading = true;
  bool _joining = false;
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.fetchSocieties();
      setState(() {
        _societies = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _join(int societyId, String name) async {
    setState(() => _joining = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.joinSociety(societyId);
      final box = Hive.box('user_box');
      box.put('society_id', result['society_id']);
      box.put('society_name', result['name']);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['detail'] ?? 'Error joining society')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchCtl.text.isEmpty
        ? _societies
        : _societies.where((s) =>
            (s['name'] as String).toLowerCase().contains(_searchCtl.text.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Society')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.orange.shade50,
            child: Column(
              children: [
                Icon(Icons.groups, size: 48, color: Colors.orange.shade400),
                const SizedBox(height: 12),
                const Text(
                  'Select your neighborhood society',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Skills are shared within your society.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtl,
              decoration: const InputDecoration(
                hintText: 'Search society...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/add-society'),
                            icon: const Icon(Icons.add),
                            label: const Text("Can't find yours? Create a new society"),
                          ),
                        );
                      }
                      final s = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Text((s['name'] as String)[0],
                              style: const TextStyle(color: Colors.orange)),
                        ),
                        title: Text(s['name'] as String),
                        trailing: _joining
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : ElevatedButton(
                                onPressed: () => _join(s['id'] as int, s['name'] as String),
                                child: const Text('Join'),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
