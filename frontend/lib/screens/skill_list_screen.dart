import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'skill_detail_screen.dart';

class SkillListScreen extends StatefulWidget {
  final bool isNearby;
  final Position? currentPosition;
  final int? userSocietyId;
  final String? categoryFilter;

  const SkillListScreen({
    super.key,
    required this.isNearby,
    this.currentPosition,
    this.userSocietyId,
    this.categoryFilter,
  });

  @override
  State<SkillListScreen> createState() => _SkillListScreenState();
}

class _SkillListScreenState extends State<SkillListScreen> {
  double radius = 2.0;
  List<dynamic> skills = [];
  List<dynamic> filteredSkills = [];
  bool isLoading = true;
  Set<int> likedSkillIds = {};
  final TextEditingController _searchCtrl = TextEditingController();

  Future<void> _toggleLike(int skillId) async {
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final result = await api.likeSkill(skillId);
      setState(() {
        if (result['status'] == 'liked') {
          likedSkillIds.add(skillId);
        } else {
          likedSkillIds.remove(skillId);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  double _distance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000;
    final dlat = _rad(lat2 - lat1);
    final dlng = _rad(lng2 - lng1);
    final a = math.sin(dlat / 2) * math.sin(dlat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dlng / 2) * math.sin(dlng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _rad(double deg) => deg * math.pi / 180;

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
    } else if (old.categoryFilter != widget.categoryFilter) {
      _filter();
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
      likedSkillIds.clear();
      for (final s in skills) {
        if (s['is_liked'] == true) {
          likedSkillIds.add(s['id']);
        }
      }
      _filter();
    } catch (e) {
      skills = [];
    }
    setState(() => isLoading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      filteredSkills = skills.where((s) {
        if (q.isNotEmpty) {
          final title = (s['title'] ?? '').toString().toLowerCase();
          final desc = (s['description'] ?? '').toString().toLowerCase();
          final cat = (s['category'] ?? '').toString().toLowerCase();
          if (!title.contains(q) && !desc.contains(q) && !cat.contains(q)) {
            return false;
          }
        }
        if (widget.categoryFilter != null) {
          final cat = (s['category'] ?? '').toString().toLowerCase();
          if (cat != widget.categoryFilter!.toLowerCase()) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: AppStrings.get('search_hint', lang: context.read<SettingsService>().language),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
            ),
            onChanged: (_) => _filter(),
          ),
        ),
        if (widget.isNearby)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              : filteredSkills.isEmpty
                  ? Center(
                      child: Text(
                        skills.isEmpty
                            ? (widget.isNearby
                                ? AppStrings.get('no_skills_nearby', lang: context.read<SettingsService>().language)
                                : '${AppStrings.get('no_skills_society', lang: context.read<SettingsService>().language)}\nAdd one from the Profile tab!')
                            : 'No skills match your search.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredSkills.length,
                      itemBuilder: (context, index) {
                        final skill = filteredSkills[index];
                        final societyName = skill['society_name'];
                        final skillSocietyId = skill['society_id'];
                        final isSameSociety = widget.userSocietyId != null &&
                            skillSocietyId != null &&
                            widget.userSocietyId == skillSocietyId;

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
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(skill['title'] ?? 'Untitled',
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (isSameSociety)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.home,
                                            size: 12,
                                            color: Colors.orange.shade800),
                                        const SizedBox(width: 2),
                                        Text('Same Society',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange.shade800)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${skill['description'] ?? ''}'),
                                Row(
                                  children: [
                                    Text('\$${skill['hourly_rate'] ?? 'Negotiable'}/hr',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const Spacer(),
                                    if (societyName != null)
                                    Icon(Icons.groups,
                                        size: 12,
                                        color: Colors.grey.shade600),
                                    if (societyName != null)
                                      Text(' $societyName',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600)),
                                    if (!isSameSociety &&
                                        widget.currentPosition != null &&
                                        skill['user_lat'] != null &&
                                        skill['user_lng'] != null)
                                      Text(
                                        ' · ${(_distance(
                                          widget.currentPosition!.latitude,
                                          widget.currentPosition!.longitude,
                                          (skill['user_lat'] as num).toDouble(),
                                          (skill['user_lng'] as num).toDouble(),
                                        ) / 1000).toStringAsFixed(1)} km',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    likedSkillIds.contains(skill['id'])
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: likedSkillIds.contains(skill['id'])
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleLike(skill['id']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
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
