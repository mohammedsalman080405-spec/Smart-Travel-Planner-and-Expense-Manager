import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/loading_widget.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<TripProvider>().fetchTrips();
      }
    });
  }

  void _showCreateTripDialog() {
    final nameCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();
    DateTime start = DateTime.now().add(const Duration(days: 14));
    DateTime end = DateTime.now().add(const Duration(days: 20));
    int travellers = 2;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final fmt = DateFormat('yyyy-MM-dd');

          return AlertDialog(
            backgroundColor: AppTheme.cardNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Create New Trip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Trip Name (e.g. Royal Hyderabad Tour)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: destCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Destination (e.g. Hyderabad, Paris, Bali)'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: budgetCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _IndianCurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Total Trip Budget (₹)',
                        hintText: 'Enter your estimated trip budget',
                        prefixText: '₹ ',
                        helperText: 'Maximum amount planned for the entire trip.',
                      ),
                      validator: (value) {
                        final amount = int.tryParse((value ?? '').replaceAll(',', ''));
                        return amount == null || amount <= 0
                            ? 'Enter a budget greater than ₹0'
                            : null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: start,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (d != null) {
                                setDialogState(() {
                                  start = d;
                                  if (!end.isAfter(start)) end = start.add(const Duration(days: 3));
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'Start Date'),
                              child: Text(fmt.format(start), style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: end,
                                firstDate: start,
                                lastDate: DateTime.now().add(const Duration(days: 730)),
                              );
                              if (d != null) setDialogState(() => end = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(labelText: 'End Date'),
                              child: Text(fmt.format(end), style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Number of Travellers:', style: TextStyle(color: Colors.white70)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.accentCyan),
                              onPressed: travellers > 1 ? () => setDialogState(() => travellers--) : null,
                            ),
                            Text('$travellers', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.accentCyan),
                              onPressed: () => setDialogState(() => travellers++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() == true) {
                    final success = await context.read<TripProvider>().createTrip(
                      tripName: nameCtrl.text.trim(),
                      destination: destCtrl.text.trim(),
                      startDate: fmt.format(start),
                      endDate: fmt.format(end),
                      totalTripBudget: double.parse(budgetCtrl.text.replaceAll(',', '')),
                      travellerCount: travellers,
                    );
                    if (success && mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Trip created successfully!')),
                      );
                    }
                  }
                },
                child: const Text('Create Trip'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tripProvider = context.watch<TripProvider>();

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'MY TRAVEL TRIPS & ITINERARIES',
          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          if (auth.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create New Trip'),
                onPressed: _showCreateTripDialog,
              ),
            ),
        ],
      ),
      body: !auth.isAuthenticated
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flight_takeoff, color: AppTheme.textMuted, size: 52),
                  const SizedBox(height: 16),
                  const Text('Sign in to create itineraries and manage trip expenses', style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
                ],
              ),
            )
          : tripProvider.isLoading
              ? const LoadingWidget(message: 'Loading trips and budgets...')
              : tripProvider.trips.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flight_takeoff, color: AppTheme.textMuted, size: 52),
                          const SizedBox(height: 16),
                          const Text('No trips created yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Start planning your luxury vacation and track your budgets seamlessly.', style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create Your First Trip'),
                            onPressed: _showCreateTripDialog,
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        padding: const EdgeInsets.all(24),
                        child: ListView.separated(
                          itemCount: tripProvider.trips.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final trip = tripProvider.trips[index];

                            return Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: AppTheme.cardNavy,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.borderNavy),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentCyan.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.flight_takeoff, color: AppTheme.accentCyan, size: 22),
                                          ),
                                          const SizedBox(width: 14),
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                              Text(
                                                trip.tripName,
                                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${trip.destination} • ${trip.startDate} to ${trip.endDate} • ${trip.travellerCount} Travellers',
                                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                              ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentBlue.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          trip.status.toUpperCase(),
                                          style: const TextStyle(color: AppTheme.accentCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 18),
                                  Builder(
                                    builder: (context) {
                                      final totalBudget = trip.totalTripBudget > 0
                                          ? trip.totalTripBudget
                                          : (trip.budget?.totalBudget ?? 0);
                                      final spent = trip.expenses.fold<double>(
                                        0,
                                        (sum, expense) => sum + expense.amount,
                                      );
                                      return Wrap(
                                        spacing: 24,
                                        runSpacing: 10,
                                        children: [
                                          _tripMoney('Total budget', totalBudget),
                                          _tripMoney('Amount spent', spent),
                                          _tripMoney('Remaining', totalBudget - spent),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: AppTheme.borderNavy, height: 1),
                                  const SizedBox(height: 14),

                                  // Action links: Itinerary, Budget & Expenses
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.event_note, size: 16),
                                        label: const Text('Itinerary & Activities'),
                                        onPressed: () {
                                          context.push('/itinerary/${trip.tripId}');
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.account_balance_wallet, size: 16),
                                        label: const Text('Budget & Expense Tracker'),
                                        onPressed: () {
                                          context.push('/budget/${trip.tripId}');
                                        },
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                                        tooltip: 'Delete Trip',
                                        onPressed: () async {
                                          final c = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: AppTheme.cardNavy,
                                              title: const Text('Delete Trip?', style: TextStyle(color: Colors.white)),
                                              content: Text('Are you sure you want to delete "${trip.tripName}"?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRose),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (c == true && mounted) {
                                            context.read<TripProvider>().deleteTrip(trip.tripId);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
    );
  }

  Widget _tripMoney(String label, num amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount),
          style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _IndianCurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _format = NumberFormat.decimalPattern('en_IN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    if (digits.length > 10) return oldValue;
    final formatted = _format.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
