import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class RequestsSentScreen extends StatefulWidget {
  const RequestsSentScreen({super.key});

  @override
  State<RequestsSentScreen> createState() => _RequestsSentScreenState();
}

class _RequestsSentScreenState extends State<RequestsSentScreen> {
  List<dynamic> _requests = [];
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
      final list = await api.fetchSentRequests();
      setState(() { _requests = list; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests Sent')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No requests sent yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final r = _requests[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(r['skill_title']?[0] ?? '?')),
                          title: Text(r['skill_title'] ?? ''),
                          subtitle: Text('Status: ${r['status']}'),
                          trailing: _statusChip(r['status']),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _statusChip(String? status) {
    Color color;
    switch (status) {
      case 'accepted': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Text(status ?? 'pending', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
