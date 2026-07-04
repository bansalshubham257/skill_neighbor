import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AddSocietyScreen extends StatefulWidget {
  const AddSocietyScreen({super.key});

  @override
  State<AddSocietyScreen> createState() => _AddSocietyScreenState();
}

class _AddSocietyScreenState extends State<AddSocietyScreen> {
  final _nameCtl = TextEditingController();
  final _searchCtl = TextEditingController();
  bool _isSubmitting = false;
  List<dynamic> _societies = [];
  List<dynamic> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSocieties() async {
    setState(() => _loading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.fetchSocieties();
      setState(() {
        _societies = list;
        _filtered = List.from(list);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_societies);
      } else {
        _filtered = _societies.where((s) =>
          (s['name'] as String).toLowerCase().contains(q.toLowerCase())
        ).toList();
      }
    });
  }

  Future<void> _joinSociety(dynamic society) async {
    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.joinSociety(society['id']);
      final box = Hive.box('user_box');
      box.put('society_id', result['society_id']);
      box.put('society_name', result['name']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${result['name']}')),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data?['detail'] ?? e.message}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createSociety() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission needed to create a society')),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.createSociety(
        name: name,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      final box = Hive.box('user_box');
      box.put('society_id', result['society_id']);
      box.put('society_name', result['name']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society created! You are now a member.')),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.response?.data ?? e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create / Join Society')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Join an existing society or create a new one.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtl,
            decoration: InputDecoration(
              hintText: 'Search nearby societies...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No societies found. Create one below!', style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...List.generate(_filtered.length, (i) {
              final s = _filtered[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 3),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.groups)),
                  title: Text(s['name'] ?? ''),
                  trailing: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline, color: Colors.orange),
                  onTap: () => _joinSociety(s),
                ),
              );
            }),
          const Divider(height: 32),
          const Text(
            'Create a new society for your apartment complex or neighborhood.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtl,
            decoration: const InputDecoration(
              labelText: 'Society / Community Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _createSociety,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Create Society', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Note: Your current location will be used as the society center.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
