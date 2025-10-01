import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';

/// Simplified clinics service that queries the database directly
/// This bypasses the Edge Function to test if the issue is with the function or the database
class ClinicsServiceSimple {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch clinics directly from the database (bypassing Edge Function)
  static Future<List<Clinic>> fetchClinicsDirectly() async {
    try {
      print('🔍 [SIMPLE SERVICE] Fetching clinics directly from database...');

      // Check for active session
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      print(
        '✅ [SIMPLE SERVICE] Session valid, user: ${_supabase.auth.currentUser?.email}',
      );

      // Query the Clinic table directly
      print('🔍 [SIMPLE SERVICE] Querying Clinic table...');
      final response = await _supabase
          .from('Clinic')
          .select(
            'clinic_id, name, city, district, examination_price, profile_image',
          )
          .limit(10); // Limit to 10 for testing

      print('✅ [SIMPLE SERVICE] Database query successful');
      print('📊 [SIMPLE SERVICE] Raw response: $response');

      if (response.isEmpty) {
        print('⚠️ [SIMPLE SERVICE] No clinics found in database');
        return [];
      }

      // Convert to Clinic objects
      final clinics = <Clinic>[];
      for (int i = 0; i < response.length; i++) {
        try {
          final clinicData = response[i] as Map<String, dynamic>;

          // Add missing fields with defaults
          clinicData['location'] =
              '${clinicData['city'] ?? ''}, ${clinicData['district'] ?? ''}';
          clinicData['group_type'] = 'clinic';
          clinicData['_rank'] = 0;

          final clinic = Clinic.fromMap(clinicData);
          clinics.add(clinic);

          print('✅ [SIMPLE SERVICE] Parsed clinic: ${clinic.name}');
        } catch (e) {
          print('⚠️ [SIMPLE SERVICE] Error parsing clinic at index $i: $e');
          print('⚠️ [SIMPLE SERVICE] Problematic data: ${response[i]}');
        }
      }

      print('✅ [SIMPLE SERVICE] Successfully parsed ${clinics.length} clinics');
      return clinics;
    } catch (e) {
      print('❌ [SIMPLE SERVICE] Error: $e');

      if (e is PostgrestException) {
        print('🔍 [SIMPLE SERVICE] Postgres error code: ${e.code}');
        print('🔍 [SIMPLE SERVICE] Postgres error message: ${e.message}');
        print('🔍 [SIMPLE SERVICE] Postgres error details: ${e.details}');
      }

      rethrow;
    }
  }
}
