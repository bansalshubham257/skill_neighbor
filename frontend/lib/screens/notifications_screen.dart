import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
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
      final list = await api.fetchNotifications();
      setState(() { _notifications = list; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsService>().language;

    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Text(
                    'No notifications yet.\nLike someone\'s skill to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
                        ),
                        title: Text('${n['liked_by_username']} liked your skill'),
                        subtitle: Text('"${n['skill_title']}"'),
                        trailing: Text(
                          _timeAgo(n['created_at']),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'now';
  }
}
