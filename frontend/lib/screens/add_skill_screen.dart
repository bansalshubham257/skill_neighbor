import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AddSkillScreen extends StatefulWidget {
  final VoidCallback? onSkillAdded;
  const AddSkillScreen({super.key, this.onSkillAdded});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _rateCtl = TextEditingController();

  String _category = 'Tutoring';
  String _priceType = 'Negotiable';
  bool _isSubmitting = false;

  List<dynamic> _societies = [];
  int? _selectedSocietyId;
  bool _loadingSocieties = true;

  final List<String> _categories = [
    'Tutoring', 'Fitness', 'Music', 'Cooking', 'Plumbing',
    'Electrical', 'Cleaning', 'Photography', 'Gardening',
    'Pet Care', 'IT Support', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final box = Hive.box('user_box');
    _selectedSocietyId = box.get('society_id');
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final list = await api.fetchSocieties();
      if (mounted) setState(() {
        _societies = list;
        _loadingSocieties = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSocieties = false);
    }
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _descCtl.dispose();
    _phoneCtl.dispose();
    _rateCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);

      if (_selectedSocietyId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select or join a society first')),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      await api.createSkill(
        title: _titleCtl.text.trim(),
        description: _descCtl.text.trim(),
        category: _category,
        priceType: _priceType,
        hourlyRate: _priceType == 'Fixed'
            ? double.tryParse(_rateCtl.text.trim())
            : null,
        phoneNumber: _phoneCtl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skill published!')),
        );
        setState(() {
          _titleCtl.clear();
          _descCtl.clear();
          _phoneCtl.clear();
          _rateCtl.clear();
        });
        widget.onSkillAdded?.call();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data?['detail'] ?? e.message}')),
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
    final box = Hive.box('user_box');
    final currentSocietyName = box.get('society_name');

    return Scaffold(
      appBar: AppBar(title: const Text('Add a Skill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_loadingSocieties)
              const LinearProgressIndicator()
            else ...[
              if (currentSocietyName != null) ...[
                Card(
                  color: Colors.orange.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.home, color: Colors.orange),
                    title: Text('Your Society: $currentSocietyName'),
                    subtitle: const Text('Skills will be listed under this society'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<int>(
                  value: _selectedSocietyId,
                  decoration: const InputDecoration(
                    labelText: 'Choose a Society *',
                    prefixIcon: Icon(Icons.groups),
                  ),
                  hint: const Text('Select your society'),
                  items: _societies.map((s) => DropdownMenuItem<int>(
                    value: s['id'] as int,
                    child: Text(s['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedSocietyId = v),
                  validator: (v) => v == null ? 'Select a society' : null,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/add-society'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Can't find yours? Create a new society"),
                ),
              ],
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Visible after ad unlock',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _priceType,
              decoration: const InputDecoration(labelText: 'Price Type'),
              items: const [
                DropdownMenuItem(value: 'Negotiable', child: Text('Negotiable')),
                DropdownMenuItem(value: 'Fixed', child: Text('Fixed')),
              ],
              onChanged: (v) => setState(() => _priceType = v!),
            ),
            if (_priceType == 'Fixed') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateCtl,
                decoration: const InputDecoration(labelText: 'Hourly Rate (\$)'),
                keyboardType: TextInputType.number,
              ),
            ],
            const SizedBox(height: 32),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Publish Skill', style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}
