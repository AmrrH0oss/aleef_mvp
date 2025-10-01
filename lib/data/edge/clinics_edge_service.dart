import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for fetching clinics using Supabase Edge Functions
class ClinicsEdgeService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches clinics from the authenticated edge function
  ///
  /// Requires user to be logged in and includes access token in Authorization header
  /// Calls the 'get-clinics' edge function and returns the clinics list
  ///
  /// Throws an Exception if:
  /// - User is not logged in
  /// - Edge function returns an error
  /// - Response format is invalid
  static Future<List<Map<String, dynamic>>> fetchClinicsAuthenticated() async {
    try {
      // Check if user is logged in
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to fetch clinics');
      }

      // Get the current access token
      final session = _supabase.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('No valid session found. Please log in again.');
      }

      // Call the edge function with Authorization header
      final res = await _supabase.functions.invoke(
        'get-clinics',
        headers: {
          'Authorization': 'Bearer ${session!.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      // Check for successful response
      if (res.data == null) {
        throw Exception('No data received from clinics service');
      }

      // Parse the response data
      final responseData = res.data;

      // Handle different response formats
      List<dynamic> clinicsData;

      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('clinics')) {
        // Response has 'clinics' key
        clinicsData = responseData['clinics'] as List<dynamic>;
      } else if (responseData is List) {
        // Response is directly the clinics array
        clinicsData = responseData;
      } else {
        throw Exception('Invalid response format: expected clinics array');
      }

      // Convert to List<Map<String, dynamic>>
      return clinicsData
          .map((clinic) => clinic as Map<String, dynamic>)
          .toList();
    } catch (e) {
      // Handle different types of errors
      if (e is FunctionException) {
        throw Exception('Edge function error: ${e.details ?? e.reasonPhrase}');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Unexpected error fetching clinics: $e');
      }
    }
  }

  /// Fetches clinics from the updated clinics-list edge function with location-based sorting
  ///
  /// This function now automatically sorts clinics by user location using JWT verification:
  /// - Same district: _rank = 2 (highest priority)
  /// - Same city: _rank = 1 (medium priority)
  /// - Otherwise: _rank = 0 (lowest priority)
  ///
  /// Parameters:
  /// - [priceMin]: Minimum examination price filter
  /// - [priceMax]: Maximum examination price filter
  /// - [search]: Search term for clinic name
  ///
  /// Returns a list of clinic data with _rank field for location priority
  /// Throws an Exception if the request fails or no active session
  static Future<List<Map<String, dynamic>>> fetchClinics({
    double? priceMin,
    double? priceMax,
    String? search,
  }) async {
    // Use the main fetchClinicsSortedByUserLocation method with enhanced logging
    return await fetchClinicsSortedByUserLocation(
      search: search,
      priceMin: priceMin,
      priceMax: priceMax,
    );
  }

  /// Validates filter parameters before making the request
  static bool _isValidFilterParams({double? priceMin, double? priceMax}) {
    // Ensure price range is valid
    if (priceMin != null && priceMax != null) {
      return priceMin <= priceMax && priceMin >= 0;
    }

    // Individual price values should be non-negative
    if (priceMin != null && priceMin < 0) return false;
    if (priceMax != null && priceMax < 0) return false;

    return true;
  }

  /// Convenience method to fetch all clinics without filters
  /// Requires active user session
  static Future<List<Map<String, dynamic>>> fetchAllClinics() async {
    return await fetchClinics();
  }

  /// Convenience method to search clinics by name or specialty
  /// Requires active user session
  static Future<List<Map<String, dynamic>>> searchClinics(
    String searchTerm,
  ) async {
    if (searchTerm.isEmpty) {
      return await fetchAllClinics();
    }
    return await fetchClinics(search: searchTerm);
  }

  /// Convenience method to fetch all clinics (location sorting handled automatically)
  /// Note: Location sorting is now handled automatically by the Edge Function
  /// This method is kept for backward compatibility
  static Future<List<Map<String, dynamic>>> fetchClinicsByLocation({
    String? city,
    String? district,
  }) async {
    // Location filtering is now handled server-side automatically
    // Just return all clinics sorted by user location
    return await fetchClinics();
  }

  /// Convenience method to fetch clinics within price range
  /// Requires active user session
  static Future<List<Map<String, dynamic>>> fetchClinicsByPriceRange({
    required double minPrice,
    required double maxPrice,
  }) async {
    if (!_isValidFilterParams(priceMin: minPrice, priceMax: maxPrice)) {
      throw Exception(
        'Invalid price range: min ($minPrice) must be <= max ($maxPrice) and both >= 0',
      );
    }

    return await fetchClinics(priceMin: minPrice, priceMax: maxPrice);
  }

  /// Fetches clinics sorted by user location from Edge Function
  ///
  /// This method calls an Edge Function that:
  /// 1. Decodes the JWT to get the user ID
  /// 2. Fetches user's location from PetOwners table
  /// 3. Returns clinics sorted by location priority:
  ///    - Same district first
  ///    - Same city second
  ///    - Others last
  /// 4. Includes average rating and review count
  ///
  /// Returns clinics with location-based sorting applied server-side
  /// Throws an Exception if user is not logged in or request fails
  static Future<List<Map<String, dynamic>>> fetchClinicsSortedByUserLocation({
    String? search,
    double? priceMin,
    double? priceMax,
  }) async {
    try {
      // Check for active session and get access token
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken == null) {
        throw Exception('No active session. Please log in again.');
      }

      // Get current user info for logging
      final currentUser = Supabase.instance.client.auth.currentUser;
      print('🔍 [API REQUEST] User: ${currentUser?.email}');
      print('🔍 [API REQUEST] User ID: ${currentUser?.id}');

      // Build the request body with optional parameters
      final Map<String, dynamic> requestBody = {};

      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
      }
      if (priceMin != null) {
        requestBody['priceMin'] = priceMin;
      }
      if (priceMax != null) {
        requestBody['priceMax'] = priceMax;
      }

      // Log the complete request details
      print('🚀 [API REQUEST] Method: POST');
      print('🚀 [API REQUEST] Endpoint: clinics-list');
      print('🚀 [API REQUEST] Headers: {');
      print('    Authorization: Bearer ${session!.accessToken}');
      print('    Content-Type: application/json');
      print('}');
      print('🚀 [API REQUEST] Body: $requestBody');
      print('');
      print('🔑 [FULL JWT TOKEN FOR SUPABASE TESTING]:');
      print(session!.accessToken);
      print('');

      // Call the Edge Function (using clinics-list as the main endpoint)
      final res = await Supabase.instance.client.functions.invoke(
        'clinics-list', // Using the main clinics-list endpoint
        body: requestBody,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      // Log the raw response
      print('📥 [API RESPONSE] Status: ${res.status}');
      print('📥 [API RESPONSE] Raw Data: ${res.data}');

      // Check for successful response
      if (res.data == null) {
        print('❌ [API ERROR] No data received from clinics service');
        throw Exception('No data received from clinics service');
      }

      // Parse the response data
      final responseData = res.data as Map<String, dynamic>;
      print(
        '📊 [API RESPONSE] Parsed Response Keys: ${responseData.keys.toList()}',
      );

      // Extract clinics array from response
      if (responseData.containsKey('clinics')) {
        final clinicsData = responseData['clinics'];
        print(
          '📊 [API RESPONSE] Clinics count: ${clinicsData is List ? clinicsData.length : 'Invalid format'}',
        );

        // Log user location info if available
        if (responseData.containsKey('user_location')) {
          print('📍 [USER LOCATION] ${responseData['user_location']}');
        }

        // Ensure we have a valid list
        if (clinicsData is List) {
          // Log first clinic for debugging
          if (clinicsData.isNotEmpty) {
            print('📋 [SAMPLE CLINIC] ${clinicsData.first}');
          }

          final parsedClinics = clinicsData.map((clinic) {
            try {
              // Add group_type field if missing (default to 'clinic')
              final clinicMap = Map<String, dynamic>.from(
                clinic as Map<String, dynamic>,
              );
              if (!clinicMap.containsKey('group_type')) {
                clinicMap['group_type'] = 'clinic'; // Default group type
              }
              return clinicMap;
            } catch (e) {
              print(
                '⚠️ [PARSING WARNING] Error processing clinic: $clinic, Error: $e',
              );
              return clinic as Map<String, dynamic>;
            }
          }).toList();

          print(
            '✅ [API SUCCESS] Successfully parsed ${parsedClinics.length} clinics',
          );
          return parsedClinics;
        } else {
          print(
            '❌ [API ERROR] Invalid clinics data format: ${clinicsData.runtimeType}',
          );
          throw Exception('Invalid clinics data format received');
        }
      } else {
        print(
          '❌ [API ERROR] No clinics key in response. Available keys: ${responseData.keys.toList()}',
        );
        throw Exception('No clinics data found in response');
      }
    } catch (e) {
      print('💥 [API ERROR] Exception caught: $e');
      print('💥 [API ERROR] Exception type: ${e.runtimeType}');

      // Handle different types of errors
      if (e is FunctionException) {
        print('💥 [FUNCTION ERROR] Details: ${e.details}');
        print('💥 [FUNCTION ERROR] Reason: ${e.reasonPhrase}');
        throw Exception('Edge function error: ${e.details ?? e.reasonPhrase}');
      } else if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Unexpected error fetching sorted clinics: $e');
      }
    }
  }
}
