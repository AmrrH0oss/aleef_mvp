import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../services/appointment_service.dart';
import '../services/booking_service.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Map<String, dynamic>? _appointment;
  bool _isLoading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get appointment data from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _appointment = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appointment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Appointment Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text(
            'No appointment data available',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Appointment Details',
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _buildAppointmentDetails(),
      bottomNavigationBar: _buildActionButtons(),
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
              'Error Loading Details',
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
              onPressed: () => Navigator.of(context).pop(),
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
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetails() {
    final clinicName = _appointment!['clinic_name'] ?? 'Unknown Clinic';
    final clinicDistrict = _appointment!['clinic_district'] ?? '';
    final clinicCity = _appointment!['clinic_city'] ?? '';
    final clinicPhone = _appointment!['clinic_phone'] ?? '';
    final clinicEmail = _appointment!['clinic_email'] ?? '';
    final bookingDate = _appointment!['booking_date'] ?? '';
    final bookingTime = _appointment!['booking_time'] ?? '';
    final status = _appointment!['status'] ?? 'confirmed';
    final bookingId = _appointment!['booking_id'] ?? '';
    final createdAt = _appointment!['created_at'] ?? '';

    final location = clinicDistrict.isNotEmpty && clinicCity.isNotEmpty
        ? '$clinicDistrict, $clinicCity'
        : 'Location not specified';

    final formattedDate = AppointmentService.formatDate(bookingDate);
    final formattedTime = AppointmentService.formatTime(bookingTime);
    final createdDate = _formatCreatedDate(createdAt);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Badge
          _buildStatusBadge(status),

          const SizedBox(height: 24),

          // Main Info Card
          _buildInfoCard(
            title: 'Appointment Information',
            children: [
              _buildDetailRow(
                Icons.calendar_today,
                'Date',
                formattedDate,
                isHighlighted: true,
              ),
              _buildDetailRow(
                Icons.access_time,
                'Time',
                formattedTime,
                isHighlighted: true,
              ),
              _buildDetailRow(
                Icons.confirmation_number,
                'Booking ID',
                bookingId,
              ),
              _buildDetailRow(Icons.schedule, 'Booked On', createdDate),
            ],
          ),

          const SizedBox(height: 20),

          // Clinic Info Card
          _buildInfoCard(
            title: 'Clinic Information',
            children: [
              _buildDetailRow(
                Icons.local_hospital,
                'Clinic Name',
                clinicName,
                isHighlighted: true,
              ),
              _buildDetailRow(Icons.location_on, 'Location', location),
              if (clinicPhone.isNotEmpty)
                _buildDetailRow(
                  Icons.phone,
                  'Phone',
                  clinicPhone,
                  isClickable: true,
                  onTap: () => _makePhoneCall(clinicPhone),
                ),
              if (clinicEmail.isNotEmpty)
                _buildDetailRow(
                  Icons.email,
                  'Email',
                  clinicEmail,
                  isClickable: true,
                  onTap: () => _sendEmail(clinicEmail),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Instructions Card
          _buildInfoCard(
            title: 'Important Information',
            children: [
              _buildInstructionItem(
                Icons.access_time,
                'Arrival Time',
                'Please arrive 15 minutes before your appointment time.',
              ),
              _buildInstructionItem(
                Icons.pets,
                'Bring Your Pet',
                'Make sure to bring your pet and any relevant medical records.',
              ),
              _buildInstructionItem(
                Icons.payment,
                'Payment',
                'Payment can be made at the clinic after the consultation.',
              ),
              if (status.toLowerCase() == 'confirmed')
                _buildInstructionItem(
                  Icons.info_outline,
                  'Changes',
                  'You can reschedule or cancel this appointment up to 2 hours before the scheduled time.',
                ),
            ],
          ),

          // Add bottom padding for action buttons
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'confirmed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Status: ${status.toUpperCase()}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
    bool isClickable = false,
    VoidCallback? onTap,
  }) {
    Widget content = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 18 : 16,
                    color: isHighlighted
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isHighlighted
                        ? FontWeight.bold
                        : FontWeight.w600,
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if (isClickable)
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
        ],
      ),
    );

    if (isClickable && onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }

  Widget _buildInstructionItem(
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final status = _appointment!['status'] ?? 'confirmed';
    final bookingDate = _appointment!['booking_date'] ?? '';
    final bookingTime = _appointment!['booking_time'] ?? '';

    // Check if appointment is in the future and can be modified
    final canModify = _canModifyAppointment(bookingDate, bookingTime, status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canModify) ...[
              // Reschedule Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _rescheduleAppointment(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.schedule, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Reschedule Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelAppointment(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Info message for past/cancelled appointments
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        status.toLowerCase() == 'cancelled'
                            ? 'This appointment has been cancelled.'
                            : 'This appointment cannot be modified.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _canModifyAppointment(
    String bookingDate,
    String bookingTime,
    String status,
  ) {
    if (status.toLowerCase() == 'cancelled') return false;

    try {
      final appointmentDateTime = DateTime.parse('$bookingDate $bookingTime');
      final now = DateTime.now();
      final twoHoursFromNow = now.add(const Duration(hours: 2));

      // Can modify if appointment is more than 2 hours away
      return appointmentDateTime.isAfter(twoHoursFromNow);
    } catch (e) {
      return false;
    }
  }

  String _formatCreatedDate(String createdAt) {
    try {
      final date = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return AppointmentService.formatDate(createdAt.split('T')[0]);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showErrorSnackBar('Could not launch phone app');
      }
    } catch (e) {
      _showErrorSnackBar('Error making phone call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not launch email app');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending email');
    }
  }

  void _rescheduleAppointment() async {
    final result = await Navigator.of(
      context,
    ).pushNamed('/rescheduleAppointment', arguments: _appointment);

    // If reschedule was successful, show success message and refresh data
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment rescheduled successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to appointments list to refresh data
      Navigator.of(context).pop();
    }
  }

  void _cancelAppointment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () => _confirmCancellation(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancellation() async {
    // Close the dialog first
    Navigator.of(context).pop();

    // Show loading state
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bookingId = _appointment!['booking_id'];

      if (bookingId == null) {
        throw Exception('Booking ID not found');
      }

      // Cancel the appointment
      await BookingService.cancelAppointment(bookingId: bookingId);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to appointments list to refresh data
        Navigator.of(context).pop(true); // Return true to indicate change
      }
    } catch (e) {
      print('❌ [APPOINTMENT-DETAILS] Error cancelling appointment: $e');

      if (mounted) {
        setState(() {
          _error = _handleCancellationError(e);
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_handleCancellationError(e)),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _handleCancellationError(dynamic error) {
    if (error.toString().contains('No authenticated user') ||
        error.toString().contains('Please log in')) {
      return 'Please log in to cancel appointments';
    } else if (error.toString().contains('not found') ||
        error.toString().contains('permission')) {
      return 'You don\'t have permission to cancel this appointment';
    } else if (error.toString().contains('Failed to cancel')) {
      return 'Failed to cancel appointment. Please try again.';
    } else {
      return 'An error occurred while cancelling the appointment';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }
}
