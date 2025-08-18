import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/clinic.dart';

class ClinicsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tableName = 'clinics';

  // Fetch all clinics ordered by name
  static Future<List<Clinic>> fetchClinics() async {
    try {
      print('DEBUG: Fetching clinics from table: $_tableName');
      final response = await _supabase
          .from(_tableName)
          .select()
          .order('name', ascending: true);

      print('DEBUG: Raw response: $response');
      print('DEBUG: Response type: ${response.runtimeType}');

      final clinics = (response as List)
          .map((map) => Clinic.fromMap(map))
          .toList();
      print('DEBUG: Parsed ${clinics.length} clinics');

      return clinics;
    } catch (e) {
      print('DEBUG: Error fetching clinics: $e');
      throw Exception('Failed to fetch clinics: $e');
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
