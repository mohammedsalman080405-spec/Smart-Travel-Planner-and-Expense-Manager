import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/trip_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final tripCount = context.watch<TripProvider>().trips.length;
    final bookingCount = context.watch<BookingProvider>().bookings.length;

    if (!auth.isAuthenticated || user == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkNavy,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view your profile.', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1224),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('TRAVELER PROFILE', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.accentRose),
            tooltip: 'Log Out',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              // Avatar & Name Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderNavy),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                      child: user.profileImage == null ? const Icon(Icons.person, size: 46) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppTheme.accentCyan, fontSize: 14)),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(user.phone!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat('Active Trips', '$tripCount', () => context.push('/trips')),
                        Container(width: 1, height: 36, color: AppTheme.borderNavy),
                        _buildStat('Hotel Bookings', '$bookingCount', () => context.push('/bookings')),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              ListTile(
                tileColor: AppTheme.cardNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.borderNavy)),
                leading: const Icon(Icons.public, color: AppTheme.accentCyan),
                title: const Text('Interactive 3D Globe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => context.go('/'),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: AppTheme.cardNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.borderNavy)),
                leading: const Icon(Icons.map_outlined, color: AppTheme.accentCyan),
                title: const Text('My Trips & Itineraries', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => context.push('/trips'),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: AppTheme.cardNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.borderNavy)),
                leading: const Icon(Icons.bookmark_outline, color: AppTheme.accentCyan),
                title: const Text('Hotel Reservations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => context.push('/bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
