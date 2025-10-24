import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/appointment_service.dart';
import '../services/booking_service.dart';

class RescheduleAppointmentScreen extends StatefulWidget {
  const RescheduleAppointmentScreen({super.key});

  @override
  State<RescheduleAppointmentScreen> createState() =>
      _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState
    extends State<RescheduleAppointmentScreen> {
  Map<String, dynamic>? _appointment;
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isRescheduling = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get appointment data from route arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _appointment = args;
      // Set initial date to current appointment date + 1 day (can't reschedule to same day)
      final currentDate = DateTime.parse(_appointment!['booking_date']);
      _selectedDate = currentDate.add(const Duration(days: 1));
      _loadAvailableSlots();
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedDate == null || _appointment == null) return;

    setState(() {
      _isLoadingSlots = true;
      _error = null;
      _selectedTime = null; // Reset selected time when date changes
    });

    try {
      // Get clinic info from appointment data
      final clinicName = _appointment!['clinic_name'];
      final clinicCity = _appointment!['clinic_city'];
      final clinicDistrict = _appointment!['clinic_district'];

      print(
        '🔍 [RESCHEDULE] Looking up clinic: $clinicName in $clinicDistrict, $clinicCity',
      );

      if (clinicName == null) {
        throw Exception('Clinic name not found in appointment data');
      }

      // First, get the clinic_id by looking up the clinic
      String? clinicId = await _getClinicId(
        clinicName,
        clinicCity,
        clinicDistrict,
      );

      if (clinicId == null) {
        throw Exception('Could not find clinic ID for $clinicName');
      }

      final dateString = _selectedDate!.toIso8601String().split('T')[0];

      print(
        '🔄 [RESCHEDULE] Loading slots for clinic: $clinicId, date: $dateString',
      );

      final slots = await BookingService.getAvailableSlots(
        clinicId,
        dateString,
      );

      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _isLoadingSlots = false;
        });
      }

      print('✅ [RESCHEDULE] Loaded ${slots.length} available slots');
    } catch (e) {
      print('❌ [RESCHEDULE] Error loading slots: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load available time slots. Please try again.';
          _availableSlots = [];
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<String?> _getClinicId(
    String clinicName,
    String? clinicCity,
    String? clinicDistrict,
  ) async {
    try {
      // Query the Clinic table to get clinic_id by name and location
      var query = Supabase.instance.client
          .from('Clinic')
          .select('clinic_id')
          .eq('name', clinicName);

      if (clinicCity != null) {
        query = query.eq('city', clinicCity);
      }
      if (clinicDistrict != null) {
        query = query.eq('district', clinicDistrict);
      }

      final results = await query;

      if (results.isNotEmpty) {
        return results.first['clinic_id'] as String;
      }

      return null;
    } catch (e) {
      print('❌ [RESCHEDULE] Error getting clinic ID: $e');
      return null;
    }
  }

  Future<void> _rescheduleAppointment() async {
    if (_selectedDate == null ||
        _selectedTime == null ||
        _appointment == null) {
      return;
    }

    setState(() {
      _isRescheduling = true;
      _error = null;
    });

    try {
      final bookingId = _appointment!['booking_id'];
      final dateString = _selectedDate!.toIso8601String().split('T')[0];

      print('🔄 [RESCHEDULE] Rescheduling appointment: $bookingId');
      print('📅 [RESCHEDULE] New date: $dateString, time: $_selectedTime');

      // Call the actual reschedule API
      await BookingService.rescheduleAppointment(
        bookingId: bookingId,
        newDate: dateString,
        newTime: _selectedTime!,
      );

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to appointment details
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      print('❌ [RESCHEDULE] Error rescheduling appointment: $e');
      setState(() {
        _error = 'Failed to reschedule appointment. Please try again.';
        _isRescheduling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appointment == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reschedule Appointment'),
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
          'Reschedule Appointment',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current appointment info
            _buildCurrentAppointmentCard(),

            const SizedBox(height: 24),

            // New date selection
            _buildDateSelectionCard(),

            const SizedBox(height: 20),

            // Available time slots
            _buildTimeSelectionCard(),

            const SizedBox(height: 20),

            // Error message
            if (_error != null) _buildErrorMessage(),

            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildRescheduleButton(),
    );
  }

  Widget _buildCurrentAppointmentCard() {
    final clinicName = _appointment!['clinic_name'] ?? 'Unknown Clinic';
    final currentDate = _appointment!['booking_date'] ?? '';
    final currentTime = _appointment!['booking_time'] ?? '';

    final formattedDate = AppointmentService.formatDate(currentDate);
    final formattedTime = AppointmentService.formatTime(currentTime);

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Appointment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.local_hospital, 'Clinic', clinicName),
          _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
          _buildInfoRow(Icons.access_time, 'Time', formattedTime),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionCard() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select New Date',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Calendar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
              ),
              child: _buildCustomCalendar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelectionCard() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select New Time',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedDate == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Please select a date first to see available time slots.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else if (_isLoadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.schedule, color: Colors.orange.shade600, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'No available times',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This clinic is closed or fully booked on the selected date',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            _buildTimeSlotGrid(),
        ],
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _availableSlots.length,
        itemBuilder: (context, index) {
          final slot = _availableSlots[index];
          final isSelected = _selectedTime == slot;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTime = slot;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    AppointmentService.formatTime(slot),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRescheduleButton() {
    final canReschedule =
        _selectedDate != null &&
        _selectedTime != null &&
        !_isLoadingSlots &&
        !_isRescheduling;

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
            if (_selectedDate != null && _selectedTime != null) ...[
              // Summary of new appointment
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Appointment Time:',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${AppointmentService.formatDate(_selectedDate!.toIso8601String().split('T')[0])} at ${AppointmentService.formatTime(_selectedTime!)}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],

            // Reschedule button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canReschedule ? _rescheduleAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canReschedule
                      ? AppColors.primary
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRescheduling
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Rescheduling...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Confirm Reschedule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCalendar() {
    final now = DateTime.now();
    final firstDate = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ); // Start from tomorrow

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select New Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMiniCalendar(firstDate),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(DateTime firstDate) {
    final startOfMonth = DateTime(firstDate.year, firstDate.month, 1);
    final daysInMonth = DateTime(firstDate.year, firstDate.month + 1, 0).day;
    final startWeekday = startOfMonth.weekday % 7;

    // Calculate how many weeks we need
    final totalCells = startWeekday + daysInMonth;
    final weeksNeeded = (totalCells / 7).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Day headers
        Container(
          height: 24,
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Calendar rows
        ...List.generate(weeksNeeded, (weekIndex) {
          return Container(
            height: 32,
            child: Row(
              children: List.generate(7, (dayIndex) {
                final cellIndex = weekIndex * 7 + dayIndex;
                final dayNumber = cellIndex - startWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(
                  firstDate.year,
                  firstDate.month,
                  dayNumber,
                );

                // Only allow dates from tomorrow onwards
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                final isSelectable = date.isAfter(
                  DateTime(tomorrow.year, tomorrow.month, tomorrow.day - 1),
                );

                final isSelected =
                    _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                final isToday =
                    date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Expanded(
                  child: GestureDetector(
                    onTap: isSelectable
                        ? () {
                            setState(() {
                              _selectedDate = date;
                            });
                            _loadAvailableSlots();
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isSelectable
                                ? AppColors.textPrimary
                                : Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }
}
