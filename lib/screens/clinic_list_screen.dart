import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../services/clinics_service.dart';
import '../services/auth_service.dart';
import '../widgets/clinic_card.dart';
import '../widgets/custom_text_field.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});

  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 1; // center paw selected by default
  List<Clinic> _clinics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final clinics = await ClinicsService.fetchClinics();

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

        // Show error SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadClinics,
            ),
          ),
        );
      }
    }
  }

  String _handleClinicError(dynamic error) {
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    }

    if (error.toString().contains('Failed to fetch clinics')) {
      return 'Unable to load clinics. Please try again.';
    }

    return 'Something went wrong. Please try again.';
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
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

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
                setState(() {});
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomTap(int index) {
    if (index == 2) {
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
      itemCount: _filteredClinics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          ClinicCard(clinic: _filteredClinics.elementAt(index)),
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
      itemCount: _filteredClinics.length,
      itemBuilder: (context, index) =>
          ClinicCard(clinic: _filteredClinics.elementAt(index)),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _searchController,
                          hint: 'Search clinics...',
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (_) => setState(() {}),
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
                        icon: Icons.tune,
                        onPressed: () {},
                        tooltip: 'Filter',
                      ),
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
                          : _filteredClinics.isEmpty
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

  Iterable<Clinic> get _filteredClinics {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _clinics;
    return _clinics.where(
      (c) =>
          c.name.toLowerCase().contains(q) ||
          (c.specialty?.toLowerCase().contains(q) ?? false) ||
          c.location.toLowerCase().contains(q),
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
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.swap_vert),
          ),
        ),
      ),
    );
  }
}
