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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSocieties();
  }

  @override
  void dispose() {
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

  Future<void> _createSociety(String name) async {
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
      final result = await api.createSociety(name: name, lat: pos.latitude, lng: pos.longitude);

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
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
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
    final q = _searchCtl.text.trim();
    final exactMatch = q.isNotEmpty && _filtered.any((s) =>
      (s['name'] as String).toLowerCase() == q.toLowerCase()
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Join / Create Society')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchCtl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search or type a society name...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _filter,
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_filtered.isNotEmpty)
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
          if (_filtered.isEmpty && q.isNotEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No society named "$q" found.',
                      style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : () => _createSociety(q),
                      icon: const Icon(Icons.add_home),
                      label: const Text('Create this society'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
