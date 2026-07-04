import 'package:flutter/material.dart';
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

  final List<String> _categories = [
    'Tutoring',
    'Fitness',
    'Music',
    'Cooking',
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Photography',
    'Gardening',
    'Pet Care',
    'IT Support',
    'Other',
  ];

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
      appBar: AppBar(title: const Text('Add a Skill')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtl,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Visible after ad unlock',
              ),
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
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
                decoration: const InputDecoration(
                  labelText: 'Hourly Rate (\$)',
                ),
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
                    child: const Text('Publish Skill',
                        style: TextStyle(fontSize: 18)),
                  ),
          ],
        ),
      ),
    );
  }
}
