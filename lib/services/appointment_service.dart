import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  static final _supabase = Supabase.instance.client;

  /// Fetches all appointments for the current user with optional filtering
  static Future<List<Map<String, dynamic>>> getAllAppointments({
    String? status, // 'upcoming', 'past', 'cancelled', or null for all
    int? limit,
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      print(
        '🔍 [APPOINTMENT-SERVICE] Fetching all appointments for user: ${user.email}',
      );

      // Get user's pet_owner_id
      final petOwnerResponse = await _supabase
          .from('PetOwners')
          .select('pet_owner_id')
          .eq('user_id', user.id)
          .single();

      final petOwnerId = petOwnerResponse['pet_owner_id'];
      print('📋 [APPOINTMENT-SERVICE] Pet owner ID: $petOwnerId');

      // Build base query
      var query = _supabase
          .from('Booking')
          .select('''
            booking_id,
            booking_date,
            booking_time,
            status,
            created_at,
            clinic_id,
            Clinic!inner(
              name,
              city,
              district,
              phone,
              email
            )
          ''')
          .eq('owner_id', petOwnerId);

      // Apply status filtering
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (status == 'upcoming') {
        query = query
            .neq('status', 'cancelled')
            .gte('booking_date', today.toIso8601String().split('T')[0]);
      } else if (status == 'past') {
        query = query
            .neq('status', 'cancelled')
            .lt('booking_date', today.toIso8601String().split('T')[0]);
      } else if (status == 'cancelled') {
        query = query.eq('status', 'cancelled');
      }
      // If status is null, get all appointments

      // Apply ordering and limit
      var orderedQuery = query
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);

      if (limit != null) {
        orderedQuery = orderedQuery.limit(limit);
      }

      final appointmentsResponse = await orderedQuery;

      print(
        '📅 [APPOINTMENT-SERVICE] Found ${appointmentsResponse.length} appointments',
      );

      // Transform the data for easier use
      final appointments = appointmentsResponse.map((appointment) {
        final clinic = appointment['Clinic'];
        return {
          'booking_id': appointment['booking_id'],
          'booking_date': appointment['booking_date'],
          'booking_time': appointment['booking_time'],
          'status': appointment['status'],
          'created_at': appointment['created_at'],
          'clinic_name': clinic['name'],
          'clinic_city': clinic['city'],
          'clinic_district': clinic['district'],
          'clinic_phone': clinic['phone'],
          'clinic_email': clinic['email'],
        };
      }).toList();

      print('✅ [APPOINTMENT-SERVICE] Successfully fetched appointments');
      return appointments;
    } catch (e) {
      print('❌ [APPOINTMENT-SERVICE] Error fetching appointments: $e');
      rethrow;
    }
  }

  /// Fetches upcoming appointments for the current user (for home screen)
  static Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    return getAllAppointments(status: 'upcoming', limit: 3);
  }

  /// Formats booking date for display (e.g., "2024-01-15" -> "Monday, Jan 15")
  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) {
        return 'Today';
      } else if (targetDate == tomorrow) {
        return 'Tomorrow';
      } else if (targetDate == yesterday) {
        return 'Yesterday';
      } else {
        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        const weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ];

        final weekday = weekdays[date.weekday - 1];
        final month = months[date.month - 1];

        return '$weekday, $month ${date.day}';
      }
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  /// Formats booking time for display (e.g., "14:30" -> "2:30 PM")
  static String formatTime(String time24) {
    try {
      final parts = time24.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];

      if (hour == 0) {
        return '12:$minute AM';
      } else if (hour < 12) {
        return '$hour:$minute AM';
      } else if (hour == 12) {
        return '12:$minute PM';
      } else {
        return '${hour - 12}:$minute PM';
      }
    } catch (e) {
      return time24; // Return original if parsing fails
    }
  }

  /// Gets relative date description (e.g., "Today", "Tomorrow", "Jan 15")
  static String getRelativeDate(String dateStr) {
    try {
      final appointmentDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final appointmentDay = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );

      if (appointmentDay == today) {
        return 'Today';
      } else if (appointmentDay == tomorrow) {
        return 'Tomorrow';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[appointmentDate.month - 1]} ${appointmentDate.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}
