import 'package:flutter/material.dart';
import '../data/edge/clinics_edge_service.dart';
import '../models/clinic.dart';

/// Widget that fetches and displays clinics using authenticated edge function
///
/// This widget should be used after user login to display available clinics.
/// It automatically calls the edge function and handles loading/error states.
class AuthenticatedClinicsList extends StatelessWidget {
  const AuthenticatedClinicsList({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ClinicsEdgeService.fetchClinicsAuthenticated(),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Clinics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Trigger rebuild to retry
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Success state with data
        if (snapshot.hasData && snapshot.data != null) {
          final clinicsData = snapshot.data!;

          // Convert to Clinic objects and sort
          final clinics = clinicsData
              .map((data) => Clinic.fromMap(data))
              .toList();

          // Sort clinics by name alphabetically
          clinics.sort((a, b) => a.name.compareTo(b.name));

          // Empty state
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
                    'No Clinics Available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No clinics found in your area.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Display clinics in ListView
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clinics.length,
            itemBuilder: (context, index) {
              final clinic = clinics[index];
              return _ClinicListItem(clinic: clinic);
            },
          );
        }

        // Fallback empty state
        return const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey),
          ),
        );
      },
    );
  }
}

/// Individual clinic item widget for the list
class _ClinicListItem extends StatelessWidget {
  final Clinic clinic;

  const _ClinicListItem({required this.clinic});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to clinic details or handle tap
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tapped on ${clinic.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Name
              Text(
                clinic.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Location Info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _buildLocationText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Price and Rating Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Examination Price
                  if (clinic.examinationPrice != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          Text(
                            '${clinic.examinationPrice!.toStringAsFixed(0)} EGP',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Average Rating
                  if (clinic.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            clinic.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if (clinic.reviewsCount != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${clinic.reviewsCount})',
                              style: TextStyle(
                                color: Colors.amber.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationText() {
    final List<String> locationParts = [];

    if (clinic.district != null && clinic.district!.isNotEmpty) {
      locationParts.add(clinic.district!);
    }

    if (clinic.city != null && clinic.city!.isNotEmpty) {
      locationParts.add(clinic.city!);
    }

    // Fallback to location field if city/district not available
    if (locationParts.isEmpty && clinic.location.isNotEmpty) {
      return clinic.location;
    }

    return locationParts.isNotEmpty
        ? locationParts.join(', ')
        : 'Location not specified';
  }
}

/// Example usage in a screen after login
class ClinicsScreen extends StatelessWidget {
  const ClinicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Clinics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const AuthenticatedClinicsList(),
    );
  }
}
