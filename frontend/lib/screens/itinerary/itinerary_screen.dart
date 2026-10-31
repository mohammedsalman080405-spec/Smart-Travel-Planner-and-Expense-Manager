import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../providers/trip_provider.dart';
import '../../services/trip_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class ItineraryScreen extends StatefulWidget {
  final int tripId;

  const ItineraryScreen({super.key, required this.tripId});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  late Future<Trip> _tripFuture;

  @override
  void initState() {
    super.initState();
    _tripFuture = TripService.getTrip(widget.tripId);
  }

  Future<void> _refresh() async {
    setState(() {
      _tripFuture = TripService.getTrip(widget.tripId);
    });
  }

  void _showAddActivityDialog(Trip trip) {
    final nameCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10:00');
    DateTime actDate = DateTime.tryParse(trip.startDate) ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final fmt = DateFormat('yyyy-MM-dd');

          return AlertDialog(
            backgroundColor: AppTheme.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Add Day-Wise Activity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Activity Name (e.g. Palace Historian Tour)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: actDate,
                              firstDate: DateTime.tryParse(trip.startDate) ?? DateTime.now(),
                              lastDate: DateTime.tryParse(trip.endDate) ?? DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setDialogState(() => actDate = d);
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date'),
                            child: Text(fmt.format(actDate), style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Time (e.g. 10:00)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Location / Landmark'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Notes & Recommendations'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    await context.read<TripProvider>().addActivity(
                      tripId: trip.tripId,
                      activityName: nameCtrl.text.trim(),
                      activityDate: fmt.format(actDate),
                      startTime: timeCtrl.text.trim(),
                      location: locCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _refresh();
                    }
                  }
                },
                child: const Text('Add Activity'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openGoogleMapsLocation(String location) async {
    final query = Uri.encodeComponent(location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'SMART DAY-WISE TRIP ITINERARY',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: FutureBuilder<Trip>(
        future: _tripFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading itinerary schedule...');
          }
          if (snapshot.hasError) {
            return CustomErrorWidget(message: 'Failed to load itinerary: ${snapshot.error}', onRetry: _refresh);
          }

          final trip = snapshot.data!;

          // Group activities by date
          final Map<String, List<TripActivity>> dateGroups = {};
          for (var act in trip.activities) {
            dateGroups.putIfAbsent(act.activityDate, () => []).add(act);
          }

          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 960),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ListView(
                children: [
                  // Trip Header Banner
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF132347), Color(0xFF1B3162)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.tripName,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Destination: ${trip.destination} • ${trip.startDate} to ${trip.endDate} • ${trip.travellerCount} Travellers',
                              style: const TextStyle(color: AppTheme.accentCyan, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Activity'),
                          onPressed: () => _showAddActivityDialog(trip),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (trip.activities.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.event_available, color: AppTheme.textMuted, size: 48),
                          const SizedBox(height: 14),
                          const Text('No activities scheduled yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Day 1 Activities'),
                            onPressed: () => _showAddActivityDialog(trip),
                          ),
                        ],
                      ),
                    )
                  else
                    ...dateGroups.entries.map((group) {
                      final dateStr = group.key;
                      final activities = group.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.cardNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderNavy),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.accentCyan, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Schedule for $dateStr',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              separatorBuilder: (_, __) => const Divider(color: AppTheme.borderNavy, height: 20),
                              itemBuilder: (context, idx) {
                                final act = activities[idx];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF13203C),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        act.startTime ?? '09:00',
                                        style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            act.activityName,
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          if (act.location != null && act.location!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            InkWell(
                                              onTap: () => _openGoogleMapsLocation(act.location!),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.pin_drop, color: AppTheme.accentBlue, size: 14),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${act.location} (Open in Google Maps)',
                                                    style: const TextStyle(color: AppTheme.accentBlue, fontSize: 13, decoration: TextDecoration.underline),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          if (act.notes != null && act.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(act.notes!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                                      onPressed: () async {
                                        await context.read<TripProvider>().deleteActivity(act.activityId, trip.tripId);
                                        _refresh();
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
