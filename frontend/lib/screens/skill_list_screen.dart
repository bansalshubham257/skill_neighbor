import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'skill_detail_screen.dart';

class SkillListScreen extends StatefulWidget {
  final bool isNearby;
  final Position? currentPosition;

  const SkillListScreen({
    super.key,
    required this.isNearby,
    this.currentPosition,
  });

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen> {
  double radius = 2.0;
  List<dynamic> skills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSkills();
  }

  @override
  void didUpdateWidget(SkillListScreen old) {
    super.didUpdateWidget(old);
    if (old.isNearby != widget.isNearby ||
        old.currentPosition != widget.currentPosition) {
      loadSkills();
    }
  }

  Future<void> loadSkills() async {
    setState(() => isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);

    try {
      if (widget.isNearby) {
        final pos = widget.currentPosition;
        if (pos != null) {
          skills = await api.fetchNearbySkills(pos.latitude, pos.longitude, radius);
        } else {
          skills = [];
        }
      } else {
        final box = Hive.box('user_box');
        final societyId = box.get('society_id');
        if (societyId != null) {
          skills = await api.fetchSocietySkills(societyId);
        } else {
          skills = [];
        }
      }
    } catch (e) {
      skills = [];
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isNearby)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text("Radius: "),
                Expanded(
                  child: Slider(
                    value: radius,
                    min: 0.5,
                    max: 5.0,
                    divisions: 9,
                    label: "${radius.toStringAsFixed(1)} km",
                    onChanged: (val) {
                      setState(() => radius = val);
                      loadSkills();
                    },
                  ),
                ),
                Text("${radius.toStringAsFixed(1)} km"),
              ],
            ),
          ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : skills.isEmpty
                  ? Center(
                      child: Text(
                        widget.isNearby
                            ? 'No skills found nearby.'
                            : 'No skills in your society yet.\nAdd one from the Profile tab!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: skills.length,
                      itemBuilder: (context, index) {
                        final skill = skills[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(skill['category'] != null &&
                                      skill['category'].toString().isNotEmpty
                                  ? skill['category'][0]
                                  : '?'),
                            ),
                            title: Text(skill['title'] ?? 'Untitled'),
                            subtitle: Text(
                                '${skill['description'] ?? ''}\n\$${skill['hourly_rate'] ?? 'Negotiable'}/hr'),
                            isThreeLine: true,
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SkillDetailScreen(skill: skill),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
