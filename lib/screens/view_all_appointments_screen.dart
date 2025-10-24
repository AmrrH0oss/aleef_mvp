import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/appointment_service.dart';
import '../widgets/appointment_reminder_card.dart';

class ViewAllAppointmentsScreen extends StatefulWidget {
  const ViewAllAppointmentsScreen({super.key});

  @override
  State<ViewAllAppointmentsScreen> createState() =>
      _ViewAllAppointmentsScreenState();
}

class _ViewAllAppointmentsScreenState extends State<ViewAllAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _upcomingAppointments = [];
  List<Map<String, dynamic>> _pastAppointments = [];
  List<Map<String, dynamic>> _cancelledAppointments = [];

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all appointment types in parallel
      final results = await Future.wait([
        AppointmentService.getAllAppointments(), // All appointments
        AppointmentService.getAllAppointments(status: 'upcoming'),
        AppointmentService.getAllAppointments(status: 'past'),
        AppointmentService.getAllAppointments(status: 'cancelled'),
      ]);

      setState(() {
        _allAppointments = results[0];
        _upcomingAppointments = results[1];
        _pastAppointments = results[2];
        _cancelledAppointments = results[3];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = _handleError(e);
        _isLoading = false;
      });

      // If session expired, redirect to login
      if (e.toString().contains('No authenticated user') ||
          e.toString().contains('No active session')) {
        _redirectToLogin();
      }
    }
  }

  String _handleError(dynamic error) {
    if (error.toString().contains('No authenticated user') ||
        error.toString().contains('No active session')) {
      return 'Session expired. Please log in again.';
    } else if (error.toString().contains('Pet owner profile not found')) {
      return 'Profile not found. Please complete your profile.';
    } else if (error.toString().contains('Failed to fetch')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Unable to load appointments. Please try again.';
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: 'All (${_allAppointments.length})'),
            Tab(text: 'Upcoming (${_upcomingAppointments.length})'),
            Tab(text: 'Past (${_pastAppointments.length})'),
            Tab(text: 'Cancelled (${_cancelledAppointments.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsList(_allAppointments, 'all'),
                _buildAppointmentsList(_upcomingAppointments, 'upcoming'),
                _buildAppointmentsList(_pastAppointments, 'past'),
                _buildAppointmentsList(_cancelledAppointments, 'cancelled'),
              ],
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load appointments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadAppointments,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Map<String, dynamic>> appointments,
    String type,
  ) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentReminderCard(
            appointment: appointment,
            onTap: () => _navigateToAppointmentDetails(appointment),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String message;
    IconData icon;

    switch (type) {
      case 'upcoming':
        title = 'No Upcoming Appointments';
        message =
            'You don\'t have any upcoming appointments. Book one with a nearby clinic!';
        icon = Icons.calendar_today_outlined;
        break;
      case 'past':
        title = 'No Past Appointments';
        message =
            'You haven\'t had any appointments yet. Your appointment history will appear here.';
        icon = Icons.history;
        break;
      case 'cancelled':
        title = 'No Cancelled Appointments';
        message = 'You don\'t have any cancelled appointments.';
        icon = Icons.cancel_outlined;
        break;
      default:
        title = 'No Appointments';
        message =
            'You don\'t have any appointments yet. Book your first appointment!';
        icon = Icons.calendar_today_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey.shade400, size: 80),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (type == 'upcoming' || type == 'all') ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/clinics');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Find Clinics',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToAppointmentDetails(Map<String, dynamic> appointment) async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/appointmentDetails', arguments: appointment);

    // If appointment was modified (cancelled/rescheduled), refresh the list
    if (result == true) {
      _loadAppointments();
    }
  }
}
