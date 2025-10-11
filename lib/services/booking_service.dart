import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  static final _supabase = Supabase.instance.client;

  /// Get available time slots for a specific clinic and date
  static Future<Map<String, dynamic>> getAvailableSlots(
    String clinicId,
    DateTime date,
  ) async {
    try {
      print(
        '📅 [BOOKING-SERVICE] Fetching available slots for clinic: $clinicId',
      );
      print(
        '📅 [BOOKING-SERVICE] Date: ${date.toIso8601String().split('T')[0]}',
      );

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final response = await _supabase.functions.invoke(
        'booking-availability',
        body: {
          'clinic_id': clinicId,
          'booking_date': date.toIso8601String().split(
            'T',
          )[0], // YYYY-MM-DD format
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final availableSlots = List<Map<String, dynamic>>.from(
          response.data['available_slots'] ?? [],
        );

        print(
          '✅ [BOOKING-SERVICE] Found ${availableSlots.length} available slots',
        );

        return {
          'available_slots': availableSlots,
          'clinic_hours': response.data['clinic_hours'],
          'total_slots': response.data['total_slots'] ?? 0,
          'booked_slots': response.data['booked_slots'] ?? 0,
          'success': true,
        };
      } else {
        throw Exception(
          response.data?['error'] ?? 'Failed to fetch available slots',
        );
      }
    } catch (e) {
      print('❌ [BOOKING-SERVICE] Error fetching available slots: $e');
      rethrow;
    }
  }

  /// Create a new booking
  static Future<Map<String, dynamic>> createBooking({
    required String clinicId,
    required DateTime date,
    required String time, // 24-hour format (HH:MM:SS)
    String? petId,
  }) async {
    try {
      print('📝 [BOOKING-SERVICE] Creating booking...');
      print('📝 [BOOKING-SERVICE] Clinic: $clinicId');
      print(
        '📝 [BOOKING-SERVICE] Date: ${date.toIso8601String().split('T')[0]}',
      );
      print('📝 [BOOKING-SERVICE] Time: $time');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final response = await _supabase.functions.invoke(
        'create-booking',
        body: {
          'clinic_id': clinicId,
          'booking_date': date.toIso8601String().split('T')[0],
          'booking_time': time,
          if (petId != null) 'pet_id': petId,
        },
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        print('✅ [BOOKING-SERVICE] Booking created successfully');
        return {
          'booking': response.data['booking'],
          'clinic': response.data['clinic'],
          'message': response.data['message'],
          'success': true,
        };
      } else {
        final errorCode = response.data?['code'];
        final errorMessage =
            response.data?['error'] ?? 'Failed to create booking';

        if (errorCode == 'SLOT_UNAVAILABLE') {
          throw BookingException(
            'This time slot is no longer available. Please select another time.',
            code: 'SLOT_UNAVAILABLE',
          );
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ [BOOKING-SERVICE] Error creating booking: $e');
      rethrow;
    }
  }

  /// Get user's bookings
  static Future<List<Map<String, dynamic>>> getUserBookings() async {
    try {
      print('📋 [BOOKING-SERVICE] Fetching user bookings...');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      // Get user's pet_owner_id first
      final petOwner = await _supabase
          .from('PetOwners')
          .select('pet_owner_id')
          .eq('user_id', session.user.id)
          .single();

      // Get bookings with clinic details
      final bookings = await _supabase
          .from('Booking')
          .select('''
            booking_id,
            booking_date,
            booking_time,
            status,
            created_at,
            clinic_id,
            pet_id,
            Clinic!inner(
              name,
              city,
              district,
              phone,
              profile_image
            ),
            pet(
              name,
              species
            )
          ''')
          .eq('owner_id', petOwner['pet_owner_id'])
          .order('booking_date', ascending: false)
          .order('booking_time', ascending: false);

      print('✅ [BOOKING-SERVICE] Found ${bookings.length} bookings');
      return List<Map<String, dynamic>>.from(bookings);
    } catch (e) {
      print('❌ [BOOKING-SERVICE] Error fetching user bookings: $e');
      rethrow;
    }
  }

  /// Cancel a booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      print('❌ [BOOKING-SERVICE] Cancelling booking: $bookingId');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      await _supabase
          .from('Booking')
          .update({'status': 'cancelled'})
          .eq('booking_id', bookingId);

      print('✅ [BOOKING-SERVICE] Booking cancelled successfully');
      return true;
    } catch (e) {
      print('❌ [BOOKING-SERVICE] Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Format time for display (convert 24h to 12h format)
  static String formatTimeForDisplay(String time24h) {
    try {
      final parts = time24h.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final displayHour = hour == 0
          ? 12
          : hour > 12
          ? hour - 12
          : hour;
      final ampm = hour >= 12 ? 'PM' : 'AM';

      return '$displayHour:${minute.toString().padLeft(2, '0')} $ampm';
    } catch (e) {
      return time24h; // Return original if parsing fails
    }
  }

  /// Format date for display
  static String formatDateForDisplay(DateTime date) {
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Custom exception for booking-specific errors
class BookingException implements Exception {
  final String message;
  final String? code;

  BookingException(this.message, {this.code});

  @override
  String toString() => message;
}
