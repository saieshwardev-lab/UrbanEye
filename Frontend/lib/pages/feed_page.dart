import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Incident {
  final String id;
  final String title;
  final String location;
  final DateTime time;
  final String imageUrl;
  final String status;
  int votes;

  Incident({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.imageUrl,
    this.status = 'pending',
    this.votes = 0,
  });
}

// sample data (move to a service or backend later)
final List<Incident> sampleIncidents = [
  Incident(
    id: '1',
    title: 'Pothole - Large',
    location: 'Sector 12, Main Road',
    time: DateTime.now().subtract(Duration(hours: 3)),
    imageUrl: 'https://picsum.photos/seed/pothole/800/400',
    status: 'pending',
    votes: 5,
  ),
  Incident(
    id: '2',
    title: 'Broken Streetlight',
    location: 'Park Avenue, Near Gate 2',
    time: DateTime.now().subtract(Duration(days: 1, hours: 2)),
    imageUrl: 'https://picsum.photos/seed/light/800/400',
    status: 'in_progress',
    votes: 12,
  ),
  Incident(
    id: '3',
    title: 'Overflowing Drain',
    location: 'Riverside Lane',
    time: DateTime.now().subtract(Duration(days: 2, hours: 5)),
    imageUrl: 'https://picsum.photos/seed/drain/800/400',
    status: 'done',
    votes: 20,
  ),
];

class FeedPage extends StatefulWidget {
  const FeedPage({Key? key}) : super(key: key);

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Incident> _incidents = List.from(sampleIncidents);
  String _query = '';
  bool _showOnlyOpen = false;

  String _friendlyTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('dd MMM').format(t);
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  Future<void> _refresh() async {
    // placeholder for real refresh logic
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      // In real app you'd re-fetch data here
      _incidents = List.from(_incidents);
    });
  }

  void _upvote(Incident inc) {
    setState(() => inc.votes += 1);
    // optional: optimistic UI then call backend
    final snack = SnackBar(content: Text('Thanks — vote added'));
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  void _openDetail(Incident inc) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => IncidentDetail(incident: inc)));
  }

  List<Incident> get _filtered {
    var list = _incidents;
    if (_showOnlyOpen) list = list.where((i) => i.status != 'done').toList();
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((i) => i.title.toLowerCase().contains(q) || i.location.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => b.votes.compareTo(a.votes)); // popular first
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showOnlyOpen = !_showOnlyOpen);
            },
            icon: Icon(_showOnlyOpen ? Icons.visibility_off : Icons.visibility),
            tooltip: _showOnlyOpen ? 'Show all' : 'Show open only',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchField(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: LayoutBuilder(builder: (context, constraints) {
          final isLarge = constraints.maxWidth > 700;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final inc = _filtered[index];
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isLarge ? 720 : double.infinity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _IncidentCard(
                      incident: inc,
                      onUpvote: () => _upvote(inc),
                      onView: () => _openDetail(inc),
                      statusColor: _statusColor(inc.status),
                      friendlyTime: _friendlyTime(inc.time),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // navigate to report page
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Report'),
      ),
    );
  }

  Widget _buildSearchField() {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Search by title or location',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => setState(() => _query = ''),
          )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onUpvote;
  final VoidCallback onView;
  final Color statusColor;
  final String friendlyTime;
  const _IncidentCard({
    Key? key,
    required this.incident,
    required this.onUpvote,
    required this.onView,
    required this.statusColor,
    required this.friendlyTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: Column(
        children: [
          // image with graceful loading/fallback
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 1.6,
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png', // add a small placeholder in assets or replace with a Container below
                  image: incident.imageUrl,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image))),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.white70),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(incident.location, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 10, color: statusColor),
                      const SizedBox(width: 6),
                      Text(incident.status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // content row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(incident.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.black45),
                      const SizedBox(width: 6),
                      Text(DateFormat.yMMMd().add_jm().format(incident.time), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ]),
                  ]),
                ),

                // actions column
                Column(
                  children: [
                    // animated vote count
                    InkWell(
                      onTap: onUpvote,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.thumb_up_alt_outlined),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                            child: Text('${incident.votes}', key: ValueKey<int>(incident.votes), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: onView, child: const Text('View')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentDetail extends StatelessWidget {
  final Incident incident;
  const IncidentDetail({Key? key, required this.incident}) : super(key: key);

  Color _chipColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green.shade100;
      case 'in_progress':
        return Colors.orange.shade100;
      default:
        return Colors.red.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident')),
      body: ListView(
        children: [
          // hero-ready image (optional)
          Image.network(incident.imageUrl, height: 260, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 260, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image)))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(incident.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                Chip(label: Text(incident.status.toUpperCase()), backgroundColor: _chipColor(incident.status)),
              ]),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Expanded(child: Text(incident.location, style: const TextStyle(fontSize: 16)))]),
              const SizedBox(height: 12),
              Row(children: [const Icon(Icons.schedule), const SizedBox(width: 8), Text(DateFormat.yMMMd().add_jm().format(incident.time))]),
              const SizedBox(height: 18),
              const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('Community reported issue. Please coordinate with local maintenance authorities. Upvote to show impact and priority.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.map), label: const Text('View on map'))),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share), label: const Text('Share')),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
