import 'package:flutter/material.dart';
import '../widgets/authenticated_clinics_list.dart';
import '../data/edge/clinics_edge_service.dart';
import '../models/clinic.dart';

/// Example implementation showing how to use the authenticated clinics service
/// right after user login
class PostLoginExample extends StatelessWidget {
  const PostLoginExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here are the available clinics in your area:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade600),
                ),
              ],
            ),
          ),

          // Clinics list
          const Expanded(child: AuthenticatedClinicsList()),
        ],
      ),
    );
  }
}

/// Alternative implementation with manual FutureBuilder
/// This shows how to implement it yourself if you need more control
class ManualFutureBuilderExample extends StatefulWidget {
  const ManualFutureBuilderExample({super.key});

  @override
  State<ManualFutureBuilderExample> createState() =>
      _ManualFutureBuilderExampleState();
}

class _ManualFutureBuilderExampleState
    extends State<ManualFutureBuilderExample> {
  late Future<List<Clinic>> _clinicsFuture;

  @override
  void initState() {
    super.initState();
    _clinicsFuture = _loadClinics();
  }

  Future<List<Clinic>> _loadClinics() async {
    try {
      // Call the authenticated edge function
      final clinicsData = await ClinicsEdgeService.fetchClinicsAuthenticated();

      // Convert to Clinic objects
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      // Sort by rating (highest first), then by name
      clinics.sort((a, b) {
        // First sort by rating (highest first)
        if (a.rating != null && b.rating != null) {
          final ratingComparison = b.rating!.compareTo(a.rating!);
          if (ratingComparison != 0) return ratingComparison;
        }

        // If ratings are equal or null, sort by name
        return a.name.compareTo(b.name);
      });

      return clinics;
    } catch (e) {
      // Rethrow the error to be handled by FutureBuilder
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinics (Manual FutureBuilder)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _clinicsFuture = _loadClinics();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Clinic>>(
        future: _clinicsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching clinics from server...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load clinics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _clinicsFuture = _loadClinics();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    'No clinics available',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final clinics = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _clinicsFuture = _loadClinics();
              });
              await _clinicsFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: clinics.length,
              itemBuilder: (context, index) {
                final clinic = clinics[index];
                return _buildClinicCard(clinic);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildClinicCard(Clinic clinic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to clinic details
          Navigator.pushNamed(context, '/clinicProfile', arguments: clinic);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Clinic Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinic Name
                    Text(
                      clinic.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocationString(clinic),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Price and Rating
                    Row(
                      children: [
                        // Examination Price
                        if (clinic.examinationPrice != null) ...[
                          Icon(
                            Icons.attach_money,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                          Text(
                            '${clinic.examinationPrice!.toStringAsFixed(0)} EGP',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],

                        // Rating
                        if (clinic.rating != null) ...[
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            clinic.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.amber.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (clinic.reviewsCount != null) ...[
                            Text(
                              ' (${clinic.reviewsCount})',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationString(Clinic clinic) {
    final parts = <String>[];

    if (clinic.district?.isNotEmpty == true) {
      parts.add(clinic.district!);
    }

    if (clinic.city?.isNotEmpty == true) {
      parts.add(clinic.city!);
    }

    if (parts.isEmpty && clinic.location.isNotEmpty) {
      return clinic.location;
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Location not specified';
  }
}
