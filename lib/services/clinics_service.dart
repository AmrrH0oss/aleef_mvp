import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';
// import '../data/edge/clinics_edge_service.dart'; // TODO: Re-enable when Edge Function is deployed
import 'clinics_service_simple.dart';

class ClinicsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName =
      'Clinic'; // Updated to match actual Supabase table name

  /// Fetch clinics sorted by user location using Edge Function
  ///
  /// This is the main method that should be used throughout the app.
  /// It automatically:
  /// 1. Gets the current user's JWT from Supabase session
  /// 2. Calls the 'clinics-sorted-by-location' Edge Function with JWT
  /// 3. Returns clinics sorted by user's location (district > city > others)
  /// 4. Includes average rating and review count
  ///
  /// Throws an Exception if:
  /// - User is not logged in (no active session)
  /// - Edge Function call fails
  /// - Response parsing fails
  static Future<List<Clinic>> fetchClinics() async {
    try {
      // Check for active session and get access token
      final session = _supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please log in again.');
      }

      final jwt = session.accessToken;
      if (jwt.isEmpty) {
        throw Exception('Invalid session token. Please log in again.');
      }

      print('🔍 [CLINICS SERVICE] Fetching clinics with user location sorting');
      print(
        '🔍 [CLINICS SERVICE] Session valid, user: ${_supabase.auth.currentUser?.email}',
      );

      // TEMPORARY: Use direct database query since Edge Function is not deployed
      // TODO: Deploy Edge Function and switch back to ClinicsEdgeService
      print(
        '⚠️ [CLINICS SERVICE] Using direct database query (Edge Function not deployed)',
      );
      final clinicsData = await ClinicsServiceSimple.fetchClinicsDirectly();

      print(
        '✅ [CLINICS SERVICE] Successfully fetched ${clinicsData.length} clinics',
      );

      // clinicsData is already List<Clinic> from ClinicsServiceSimple
      // Just return it directly
      if (clinicsData.isNotEmpty) {
        print('📋 [CLINICS SERVICE] Sample clinic: ${clinicsData.first.name}');
      }

      return clinicsData;
    } catch (e) {
      print('DEBUG: Error fetching clinics: $e');

      // Handle different types of errors
      if (e is FunctionException) {
        throw Exception('Edge function error: ${e.details}');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Unexpected error fetching clinics: $e');
      }
    }
  }

  // Get clinic by ID
  static Future<Clinic?> getClinicById(String clinicId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('clinic_id', clinicId)
          .single();

      return Clinic.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Search clinics by name or specialty
  static Future<List<Clinic>> searchClinics(String query) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .or('name.ilike.%$query%,specialty.ilike.%$query%')
          .order('name');

      return (response as List).map((map) => Clinic.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to search clinics: $e');
    }
  }

  // Get clinics by specialty
  static Future<List<Clinic>> getClinicsBySpecialty(String specialty) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('specialty', specialty)
          .order('name');

      return (response as List).map((map) => Clinic.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to fetch clinics by specialty: $e');
    }
  }

  // Create new clinic (admin only)
  static Future<Clinic> createClinic(Clinic clinic) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .insert(clinic.toMap())
          .select()
          .single();

      return Clinic.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create clinic: $e');
    }
  }

  // Update clinic (admin only)
  static Future<Clinic> updateClinic(Clinic clinic) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .update(clinic.toMap())
          .eq('clinic_id', clinic.clinicId)
          .select()
          .single();

      return Clinic.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update clinic: $e');
    }
  }

  // Delete clinic (admin only)
  static Future<void> deleteClinic(String clinicId) async {
    try {
      await _supabase.from(_tableName).delete().eq('clinic_id', clinicId);
    } catch (e) {
      throw Exception('Failed to delete clinic: $e');
    }
  }

  // Get clinics with real-time updates
  static RealtimeChannel subscribeToClinics() {
    return _supabase
        .channel('clinics_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tableName,
          callback: (payload) {
            // Handle real-time updates here
            // Note: Real-time clinic changes received
          },
        )
        .subscribe();
  }
}
