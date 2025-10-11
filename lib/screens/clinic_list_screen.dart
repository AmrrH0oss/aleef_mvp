import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../services/auth_service.dart';
import '../data/edge/clinics_edge_service.dart';
import '../widgets/clinic_card.dart';
import '../widgets/custom_text_field.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  int _selectedIndex = 1; // center paw selected by default
  List<Clinic> _clinics = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userProfile;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndClinics();
  }

  Future<void> _loadUserProfileAndClinics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load user profile to get location preferences
      _userProfile = await AuthService.getUserProfile();

      // Set default city/district from user profile
      if (_userProfile != null) {
        _cityController.text = _userProfile!['city'] ?? '';
        _districtController.text = _userProfile!['district'] ?? '';
      }

      // Load clinics with user's location
      await _loadClinics();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _handleClinicError(e);
          _isLoading = false;
        });

        // If session expired, redirect to login
        if (e.toString().contains('No active session')) {
          _redirectToLogin();
        } else {
          _showErrorSnackBar(_error!);
        }
      }
    }
  }

  Future<void> _loadClinics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get filter parameters
      // Note: city and district filters removed - sorting now handled by Edge Function
      final search = _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim();
      final minPrice = _minPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_minPriceController.text.trim());
      final maxPrice = _maxPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_maxPriceController.text.trim());

      // Fetch clinics using new location-sorted edge service
      // This automatically sorts by user location on the server side
      final clinicsData =
          await ClinicsEdgeService.fetchClinicsSortedByUserLocation(
            search: search,
            priceMin: minPrice,
            priceMax: maxPrice,
          );

      // Convert to Clinic objects
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      // No need for client-side sorting - already sorted by Edge Function

      if (mounted) {
        setState(() {
          _clinics = clinics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _handleClinicError(e);
          _isLoading = false;
        });

        // If session expired, redirect to login
        if (e.toString().contains('No active session')) {
          _redirectToLogin();
        } else {
          _showErrorSnackBar(_error!);
        }
      }
    }
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadClinics,
        ),
      ),
    );
  }

  String _handleClinicError(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    }

    if (error.toString().contains('No active session')) {
      return 'Session expired. Please log in again.';
    }

    if (error.toString().contains('Failed to fetch clinics')) {
      return 'Unable to load clinics. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  // Note: Client-side sorting removed - now handled by Edge Function server-side
  // The fetchClinicsSortedByUserLocation() method automatically sorts clinics by:
  // 1. Same district as user (highest priority)
  // 2. Same city as user (medium priority)
  // 3. Others (lowest priority)
  // 4. Within each group, sorted alphabetically by name

  /// Redirects user to login screen when session expires
  void _redirectToLogin() {
    // Show a message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Session expired. Please log in again.'),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );

    // Navigate to login screen after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  Widget _buildLoadingState() {
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unable to load clinics',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadClinics,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearchQuery =
        _searchController.text.trim().isNotEmpty ||
        _cityController.text.trim().isNotEmpty ||
        _districtController.text.trim().isNotEmpty ||
        _minPriceController.text.trim().isNotEmpty ||
        _maxPriceController.text.trim().isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off : Icons.local_hospital_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery ? 'No search results' : 'No clinics yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery
                ? 'Try adjusting your search terms'
                : 'Clinics will appear here once they are added',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (hasSearchQuery) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _cityController.clear();
                _districtController.clear();
                _minPriceController.clear();
                _maxPriceController.clear();
                _loadClinics();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onBottomTap(int index) {
    if (index == 0) {
      // Navigate to home
      Navigator.of(context).pushReplacementNamed('/home');
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

  Widget _buildMobileListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      itemCount: _clinics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => ClinicCard(
        clinic: _clinics[index],
        onTap: () {
          Navigator.pushNamed(
            context,
            '/clinicProfile',
            arguments: _clinics[index],
          );
        },
      ),
    );
  }

  Widget _buildTabletDesktopGridView({
    required int crossAxisCount,
    required bool isWide,
    required bool isTablet,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isWide
            ? 2.2 // 4 columns on wide screens - much taller cards
            : (isTablet
                  ? 1.8 // 2 columns on tablet - much taller cards
                  : 1.6), // Mobile - much taller cards
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: _clinics.length,
      itemBuilder: (context, index) => ClinicCard(
        clinic: _clinics[index],
        onTap: () {
          Navigator.pushNamed(
            context,
            '/clinicProfile',
            arguments: _clinics[index],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clinics list'), centerTitle: false),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onBottomTap,
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
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            final bool isTablet = constraints.maxWidth >= 600;
            final bool isMobile = constraints.maxWidth < 600;
            final double maxWidth = isWide ? 1200 : constraints.maxWidth;
            final int crossAxisCount = isWide ? 4 : (isTablet ? 2 : 1);
            final double availableHeight =
                constraints.maxHeight - 80; // Account for search bar

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _searchController,
                              hint: 'Search clinics...',
                              prefixIcon: const Icon(Icons.search),
                              onChanged: (_) => _loadClinics(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _IconChip(
                            icon: Icons.swap_vert,
                            onPressed: () {},
                            tooltip: 'Sort',
                          ),
                          const SizedBox(width: 12),
                          _IconChip(
                            icon: _showFilters ? Icons.expand_less : Icons.tune,
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                            tooltip: 'Filter',
                          ),
                        ],
                      ),
                      if (_showFilters) _buildFiltersUI(),
                    ],
                  ),
                ),
                Flexible(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxWidth,
                        maxHeight: availableHeight,
                      ),
                      child: _isLoading
                          ? _buildLoadingState()
                          : _error != null
                          ? _buildErrorState()
                          : _clinics.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadClinics,
                              child: isMobile
                                  ? _buildMobileListView()
                                  : _buildTabletDesktopGridView(
                                      crossAxisCount: crossAxisCount,
                                      isWide: isWide,
                                      isTablet: isTablet,
                                    ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFiltersUI() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Location Filters
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _cityController,
                  hint: 'City',
                  prefixIcon: const Icon(Icons.location_city),
                  onChanged: (_) => _loadClinics(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _districtController,
                  hint: 'District',
                  prefixIcon: const Icon(Icons.location_on),
                  onChanged: (_) => _loadClinics(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price Range Filters
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _minPriceController,
                  hint: 'Min Price',
                  prefixIcon: const Icon(Icons.attach_money),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _loadClinics(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _maxPriceController,
                  hint: 'Max Price',
                  prefixIcon: const Icon(Icons.money_off),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _loadClinics(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clear Filters Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _cityController.clear();
                    _districtController.clear();
                    _minPriceController.clear();
                    _maxPriceController.clear();
                    _searchController.clear();
                    _loadClinics();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  const _IconChip({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 48, height: 48, child: Icon(icon)),
        ),
      ),
    );
  }
}
