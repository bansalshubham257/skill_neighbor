import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class RequestsReceivedScreen extends StatefulWidget {
  const RequestsReceivedScreen({super.key});

  @override
  State<RequestsReceivedScreen> createState() => _RequestsReceivedScreenState();
}

class _RequestsReceivedScreenState extends State<RequestsReceivedScreen> {
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
      final list = await api.fetchReceivedRequests();
      setState(() { _requests = list; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _respond(int requestId, String status) async {
    try {
      await Provider.of<ApiService>(context, listen: false).respondRequest(requestId, status);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests Received')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No requests received.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final r = _requests[index];
                      final isPending = r['status'] == 'pending';
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(child: Text(r['from_username']?[0] ?? '?')),
                          title: Text('${r['from_username']} wants ${r['skill_title']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['message']?.isNotEmpty == true ? r['message'] : 'Status: ${r['status']}'),
                              if (r['requester_phone'] != null)
                                Text('Contact: ${r['requester_phone']}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: isPending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () => _respond(r['id'], 'accepted'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => _respond(r['id'], 'rejected'),
                                    ),
                                  ],
                                )
                              : _statusChip(r['status']),
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
