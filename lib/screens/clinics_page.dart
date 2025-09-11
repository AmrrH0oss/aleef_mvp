import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';
import '../services/clinics_service.dart';

/// Simple Clinics Page with automatic location-based sorting
///
/// This page automatically sorts clinics by the logged-in user's location:
/// 1. Same district first
/// 2. Same city second
/// 3. Others last
///
/// The sorting happens automatically on login - no user interaction required.
class ClinicsPage extends StatefulWidget {
  const ClinicsPage({super.key});

  @override
  State<ClinicsPage> createState() => _ClinicsPageState();
}

class _ClinicsPageState extends State<ClinicsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 2,
        actions: [
          // Add logout button for testing
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    // Check if user is logged in first
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return _buildNotLoggedInState(context);
    }

    // User is logged in, show clinics
    return FutureBuilder<List<Clinic>>(
      future: ClinicsService.fetchClinics(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading clinics...',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load clinics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Trigger rebuild to retry
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Success state
        final clinics = snapshot.data ?? [];

        if (clinics.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_hospital_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No clinics found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Trigger rebuild to refresh data
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: clinics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return _buildClinicListTile(context, clinic);
            },
          ),
        );
      },
    );
  }

  /// Build a ListTile for each clinic with the requested format:
  /// - Title: clinic.name
  /// - Subtitle: clinic.district, clinic.city
  /// - Trailing: examination price and average rating
  Widget _buildClinicListTile(BuildContext context, Clinic clinic) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Title: clinic.name
        title: Text(
          clinic.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),

        // Subtitle: clinic.district, clinic.city
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _buildLocationString(clinic),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (clinic.distanceInfo != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLocationPriorityColor(clinic.locationPriority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  clinic.distanceInfo!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),

        // Trailing: examination price and average rating
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Examination price
            if (clinic.examinationPrice != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${clinic.examinationPrice!.toInt()} EGP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),

            const SizedBox(height: 4),

            // Average rating or "No rating"
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: clinic.rating != null ? Colors.amber : Colors.grey,
                ),
                const SizedBox(width: 2),
                Text(
                  clinic.rating != null
                      ? '${clinic.rating!.toStringAsFixed(1)}'
                      : 'No rating',
                  style: TextStyle(
                    fontSize: 12,
                    color: clinic.rating != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                if (clinic.reviewsCount != null && clinic.reviewsCount! > 0)
                  Text(
                    ' (${clinic.reviewsCount})',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),

        // Optional: Add onTap to navigate to clinic details
        onTap: () {
          // Navigate to clinic profile or details page
          // Navigator.pushNamed(context, '/clinic-details', arguments: clinic);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tapped on ${clinic.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  /// Build location string from district and city
  String _buildLocationString(Clinic clinic) {
    final parts = <String>[];

    if (clinic.district != null && clinic.district!.isNotEmpty) {
      parts.add(clinic.district!);
    }

    if (clinic.city != null && clinic.city!.isNotEmpty) {
      parts.add(clinic.city!);
    }

    if (parts.isEmpty) {
      return 'Location not specified';
    }

    return parts.join(', ');
  }

  /// Get color based on location priority for the distance info badge
  Color _getLocationPriorityColor(int? priority) {
    switch (priority) {
      case 3: // Same district
        return Colors.green;
      case 2: // Same city
        return Colors.blue;
      default: // Other locations
        return Colors.grey;
    }
  }

  /// Build the "Not Logged In" state
  Widget _buildNotLoggedInState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Please log in to see clinics',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'You need to be logged in to view and book appointments with veterinary clinics.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/create-account');
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
