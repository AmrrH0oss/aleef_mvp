import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/clinic.dart';
import '../services/auth_service.dart';
import '../data/edge/clinics_edge_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  List<Clinic> _clinics = [];
  bool _isLoadingClinics = false;
  String? _clinicsError;
  Map<String, dynamic>? _userProfile;
  int _selectedIndex = 0; // Home tab selected by default

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadClinics();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user profile to get both name and location preferences
      _userProfile = await AuthService.getUserProfile();

      if (_userProfile != null && _userProfile!['Full_name'] != null) {
        setState(() {
          _userName = _userProfile!['Full_name']
              .toString()
              .split(' ')
              .first; // Get first name only
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Keep default 'User' name if error occurs
    }
  }

  Future<void> _loadClinics() async {
    try {
      setState(() {
        _isLoadingClinics = true;
        _clinicsError = null;
      });

      // Fetch clinics using the same Edge Function as clinics list screen
      // This automatically sorts by user location on the server side
      final clinicsData =
          await ClinicsEdgeService.fetchClinicsSortedByUserLocation();

      // Convert to Clinic objects
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      setState(() {
        _clinics = clinics
            .take(2)
            .toList(); // Show only first 2 clinics on home page
        _isLoadingClinics = false;
      });
    } catch (e) {
      print('Error loading clinics: $e');
      setState(() {
        _clinicsError = _handleClinicError(e);
        _isLoadingClinics = false;
      });

      // If session expired, redirect to login
      if (e.toString().contains('No active session')) {
        _redirectToLogin();
      }
    }
  }

  String _handleClinicError(dynamic error) {
    if (error.toString().contains('No active session')) {
      return 'Session expired. Please log in again.';
    } else if (error.toString().contains('Failed to fetch')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Unable to load clinics. Please try again.';
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Navigate to clinics list
      Navigator.of(context).pushNamed('/clinics');
    } else if (index == 2) {
      // Profile tab - show logout dialog
      _showLogoutDialog();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting and notification
                _buildHeader(),

                const SizedBox(height: 24),

                // Add Your Pet Card
                _buildAddPetCard(),

                const SizedBox(height: 32),

                // Clinics Section
                _buildClinicsSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Profile picture and greeting
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: ClipOval(
                child: Icon(Icons.person, color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $_userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'How is Your Pet Health?',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // Notification bell
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPetCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF3C4), // Light yellow
            Color(0xFFFFF8DC), // Cream
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Your Pet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can now save you furr friend\'s information',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add pet feature coming soon!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Add pet',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Pet images
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 120, // Fixed height for the stack
              child: Stack(
                children: [
                  // Dog image (background)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.brown,
                        size: 40,
                      ),
                    ),
                  ),
                  // Cat image (foreground)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: const Icon(
                        Icons.pets,
                        color: Colors.orange,
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicsSection() {
    return Column(
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Clinics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/clinics');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Clinics list
        if (_isLoadingClinics)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_clinicsError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
                const SizedBox(height: 8),
                Text(
                  'Failed to load clinics',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clinicsError!,
                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _loadClinics, child: const Text('Retry')),
              ],
            ),
          )
        else if (_clinics.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No clinics available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _clinics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final clinic = _clinics[index];
              return _buildClinicCard(clinic);
            },
          ),
      ],
    );
  }

  Widget _buildClinicCard(Clinic clinic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/clinicProfile', arguments: clinic);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Clinic image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: clinic.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        clinic.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.local_hospital,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.local_hospital,
                      color: AppColors.primary,
                      size: 32,
                    ),
            ),

            const SizedBox(width: 16),

            // Clinic details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinic.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Rating
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        clinic.rating != null
                            ? clinic.rating!.toStringAsFixed(1)
                            : 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Location/Distance info
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        clinic.distanceInfo ?? _getLocationLabel(clinic),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Price
                      Icon(Icons.attach_money, color: Colors.green, size: 16),
                      Text(
                        '${clinic.examinationPrice?.toInt() ?? 300}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocationLabel(Clinic clinic) {
    // Show actual district and city instead of relationship labels
    if (clinic.district != null && clinic.city != null) {
      return '${clinic.district}, ${clinic.city}';
    } else if (clinic.location.isNotEmpty) {
      return clinic.location;
    } else {
      return 'Location not specified';
    }
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onBottomNavTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.pets_outlined),
          selectedIcon: Icon(Icons.pets),
          label: '',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: '',
        ),
      ],
    );
  }
}
