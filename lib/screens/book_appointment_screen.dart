import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import '../services/booking_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedTimeSlot; // Changed to store full slot data
  List<Map<String, dynamic>> _availableSlots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;

  /// Load available time slots for the selected date
  Future<void> _loadAvailableSlots(String clinicId, DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedTimeSlot = null; // Reset selected time when date changes
    });

    try {
      final result = await BookingService.getAvailableSlots(clinicId, date);
      List<Map<String, dynamic>> allSlots = List<Map<String, dynamic>>.from(
        result['available_slots'] ?? [],
      );

      // Filter out past time slots if the selected date is today
      final now = DateTime.now();
      final isToday =
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      if (isToday) {
        final currentTimeInMinutes = now.hour * 60 + now.minute;
        allSlots = allSlots.where((slot) {
          final slotMinutes = slot['minutes_from_midnight'] as int;
          return slotMinutes > currentTimeInMinutes;
        }).toList();
      }

      setState(() {
        _availableSlots = allSlots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _availableSlots = [];
        _slotsError = e.toString();
        _isLoadingSlots = false;
      });
    }
  }

  /// Build minimal table calendar
  Widget _buildCustomCalendar(BuildContext context, Clinic clinic) {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Date',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildMiniCalendar(context, clinic, firstDate),
        ],
      ),
    );
  }

  Widget _buildMiniCalendar(
    BuildContext context,
    Clinic clinic,
    DateTime firstDate,
  ) {
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
                final isSelectable = date.isAfter(
                  firstDate.subtract(const Duration(days: 1)),
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
                            _loadAvailableSlots(clinic.clinicId, date);
                          }
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primary.withValues(alpha: 0.1)
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

  String _getDayName(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  @override
  Widget build(BuildContext context) {
    final clinic = ModalRoute.of(context)?.settings.arguments as Clinic?;

    if (clinic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: Text('No clinic data found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  clinic.imageUrl != null
                      ? Image.network(
                          clinic.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(context),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoadingPlaceholder(context);
                          },
                        )
                      : _buildPlaceholderImage(context),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Title overlay
                  const Positioned(
                    top: 60,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Book appointment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bottom Sheet Style Calendar
                  _buildCalendarBottomSheet(context, clinic),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.local_hospital_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCalendarBottomSheet(BuildContext context, Clinic clinic) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
                Text(
                  'calendar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 48), // Balance the close button
              ],
            ),

            const SizedBox(height: 20),

            // Calendar Widget
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: Colors.white,
                    dayBackgroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.primary;
                      }
                      return Colors.transparent;
                    }),
                    dayForegroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      if (states.contains(WidgetState.disabled)) {
                        return Colors.grey.shade400;
                      }
                      return AppColors.textPrimary;
                    }),
                    todayBackgroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      return Colors.transparent;
                    }),
                    todayForegroundColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      return AppColors.primary;
                    }),
                    dayOverlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.primary.withValues(alpha: 0.1);
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
                child: _buildCustomCalendar(context, clinic),
              ),
            ),

            const SizedBox(height: 20),

            // Available Time Section
            Text(
              'Available time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            // Time Slots
            _buildTimeSlots(context, clinic),

            const SizedBox(height: 32),

            // Book Appointment Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Book an appointment',
                onPressed: _selectedDate != null && _selectedTimeSlot != null
                    ? () => _bookAppointment(context, clinic)
                    : null,
                backgroundColor: AppColors.primary,
                height: 56,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlots(BuildContext context, Clinic clinic) {
    // Show loading state
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (_slotsError != null) {
      return Container(
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
              'Failed to load available times',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _slotsError!,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _selectedDate != null
                  ? () => _loadAvailableSlots(clinic.clinicId, _selectedDate!)
                  : null,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show message if no date selected
    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Please select a date to see available times',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Show message if no slots available
    if (_availableSlots.isEmpty) {
      return Container(
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
              style: TextStyle(color: Colors.orange.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show available time slots
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _availableSlots.length,
        itemBuilder: (context, index) {
          final slot = _availableSlots[index];
          final isSelected = _selectedTimeSlot?['time_24h'] == slot['time_24h'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTimeSlot = slot;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    slot['time_display'] ?? slot['time_24h'],
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

  Future<void> _bookAppointment(BuildContext context, Clinic clinic) async {
    if (_selectedDate == null || _selectedTimeSlot == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Booking appointment...'),
          ],
        ),
      ),
    );

    try {
      final result = await BookingService.createBooking(
        clinicId: clinic.clinicId,
        date: _selectedDate!,
        time: _selectedTimeSlot!['time_24h'],
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (result['success'] == true) {
        final timeDisplay =
            _selectedTimeSlot!['time_display'] ??
            _selectedTimeSlot!['time_24h'];
        final dateDisplay = BookingService.formatDateForDisplay(_selectedDate!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Appointment booked for $timeDisplay on $dateDisplay with ${clinic.name}',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );

        // Navigate back after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      String errorMessage = 'Failed to book appointment';
      if (e.toString().contains('SLOT_UNAVAILABLE')) {
        errorMessage =
            'This time slot is no longer available. Please select another time.';
        // Refresh available slots
        _loadAvailableSlots(clinic.clinicId, _selectedDate!);
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
}
