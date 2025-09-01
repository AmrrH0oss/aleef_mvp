import 'package:supabase_flutter/supabase_flutter.dart';

/// Service class for fetching clinics using Supabase Edge Functions
class ClinicsEdgeService {
  /// Fetches clinics from the edge function with optional filtering parameters
  ///
  /// Parameters:
  /// - [city]: Filter by city name
  /// - [district]: Filter by district name
  /// - [priceMin]: Minimum price filter
  /// - [priceMax]: Maximum price filter
  /// - [search]: Search term for clinic name or specialty
  ///
  /// Returns a list of clinic data as Map<String, dynamic>
  /// Throws an Exception if the request fails
  static Future<List<Map<String, dynamic>>> fetchClinics({
    String? city,
    String? district,
    double? priceMin,
    double? priceMax,
    String? search,
  }) async {
    try {
      // Build the request body with only non-null parameters
      final Map<String, dynamic> requestBody = {};

      if (city != null && city.isNotEmpty) {
        requestBody['city'] = city;
      }
      if (district != null && district.isNotEmpty) {
        requestBody['district'] = district;
      }
      if (priceMin != null) {
        requestBody['priceMin'] = priceMin;
      }
      if (priceMax != null) {
        requestBody['priceMax'] = priceMax;
      }
      if (search != null && search.isNotEmpty) {
        requestBody['search'] = search;
      }

      // Invoke the Supabase Edge Function
      final res = await Supabase.instance.client.functions.invoke(
        'clinics-list',
        body: requestBody,
      );

      // Check for successful response
      if (res.data == null) {
        throw Exception('No data received from clinics service');
      }

      // Parse the response data
      final responseData = res.data as Map<String, dynamic>;

      // Extract clinics array from response
      if (responseData.containsKey('clinics')) {
        final clinicsData = responseData['clinics'];

        // Ensure we have a valid list
        if (clinicsData is List) {
          return clinicsData
              .map((clinic) => clinic as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception('Invalid clinics data format received');
        }
      } else {
        // If no 'clinics' key, check if the response itself is the clinics array
        if (res.data is List) {
          final clinicsData = res.data as List;
          return clinicsData
              .map((clinic) => clinic as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception('No clinics data found in response');
        }
      }
    } catch (e) {
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
  static Future<List<Map<String, dynamic>>> fetchAllClinics() async {
    return await fetchClinics();
  }

  /// Convenience method to search clinics by name or specialty
  static Future<List<Map<String, dynamic>>> searchClinics(
    String searchTerm,
  ) async {
    if (searchTerm.isEmpty) {
      return await fetchAllClinics();
    }
    return await fetchClinics(search: searchTerm);
  }

  /// Convenience method to fetch clinics by location
  static Future<List<Map<String, dynamic>>> fetchClinicsByLocation({
    String? city,
    String? district,
  }) async {
    return await fetchClinics(city: city, district: district);
  }

  /// Convenience method to fetch clinics within price range
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
}
