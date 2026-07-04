import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtl.dispose();
    super.dispose();
  }

  Future<void> _createSociety() async {
    final name = _nameCtl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      final api = Provider.of<ApiService>(context, listen: false);
      await api.createSociety(
        name: name,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Society created! You are now a member.')),
        );
        Navigator.pop(context);
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Create a new society for your apartment complex or neighborhood.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtl,
              decoration: const InputDecoration(
                labelText: 'Society / Community Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createSociety,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Society',
                          style: TextStyle(fontSize: 18)),
                    ),
                  ),
            const SizedBox(height: 16),
            Text(
              'Note: Your current location will be used as the society center.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
