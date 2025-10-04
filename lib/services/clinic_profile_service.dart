import 'package:supabase_flutter/supabase_flutter.dart';

class ClinicProfileService {
  static final _supabase = Supabase.instance.client;

  // Fetch complete clinic details
  static Future<Map<String, dynamic>?> fetchClinicDetails(
    String clinicId,
  ) async {
    try {
      print('🏥 [CLINIC-PROFILE] Fetching details for clinic: $clinicId');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final response = await _supabase.functions.invoke(
        'clinic-details',
        body: {'clinic_id': clinicId},
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        print('✅ [CLINIC-PROFILE] Successfully fetched clinic details');
        return response.data['clinic'];
      } else {
        throw Exception('Failed to fetch clinic details');
      }
    } catch (e) {
      print('❌ [CLINIC-PROFILE] Error fetching clinic details: $e');
      rethrow;
    }
  }

  // Fetch clinic services
  static Future<List<Map<String, dynamic>>> fetchClinicServices(
    String clinicId,
  ) async {
    try {
      print('🛠️ [CLINIC-PROFILE] Fetching services for clinic: $clinicId');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final response = await _supabase.functions.invoke(
        'clinic-services',
        body: {'clinic_id': clinicId},
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final services = List<Map<String, dynamic>>.from(
          response.data['services'] ?? [],
        );
        print(
          '✅ [CLINIC-PROFILE] Successfully fetched ${services.length} services',
        );
        return services;
      } else {
        throw Exception('Failed to fetch clinic services');
      }
    } catch (e) {
      print('❌ [CLINIC-PROFILE] Error fetching clinic services: $e');
      rethrow;
    }
  }

  // Fetch clinic doctors
  static Future<List<Map<String, dynamic>>> fetchClinicDoctors(
    String clinicId,
  ) async {
    try {
      print('👨‍⚕️ [CLINIC-PROFILE] Fetching doctors for clinic: $clinicId');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final response = await _supabase.functions.invoke(
        'clinic-doctors',
        body: {'clinic_id': clinicId},
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final doctors = List<Map<String, dynamic>>.from(
          response.data['doctors'] ?? [],
        );
        print(
          '✅ [CLINIC-PROFILE] Successfully fetched ${doctors.length} doctors',
        );
        return doctors;
      } else {
        throw Exception('Failed to fetch clinic doctors');
      }
    } catch (e) {
      print('❌ [CLINIC-PROFILE] Error fetching clinic doctors: $e');
      rethrow;
    }
  }

  // Fetch all clinic profile data at once
  static Future<Map<String, dynamic>> fetchCompleteClinicProfile(
    String clinicId,
  ) async {
    try {
      print(
        '🏥 [CLINIC-PROFILE] Fetching complete profile for clinic: $clinicId',
      );

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        fetchClinicDetails(clinicId),
        fetchClinicServices(clinicId),
        fetchClinicDoctors(clinicId),
      ]);

      final clinicDetails = results[0] as Map<String, dynamic>?;
      final services = results[1] as List<Map<String, dynamic>>;
      final doctors = results[2] as List<Map<String, dynamic>>;

      if (clinicDetails == null) {
        throw Exception('Failed to fetch clinic details');
      }

      print('✅ [CLINIC-PROFILE] Successfully fetched complete clinic profile');
      print(
        '📊 [CLINIC-PROFILE] Details: ✅, Services: ${services.length}, Doctors: ${doctors.length}',
      );

      return {
        'clinic': clinicDetails,
        'services': services,
        'doctors': doctors,
        'success': true,
      };
    } catch (e) {
      print('❌ [CLINIC-PROFILE] Error fetching complete clinic profile: $e');
      rethrow;
    }
  }
}
