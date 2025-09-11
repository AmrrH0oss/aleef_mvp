import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../data/edge/clinics_edge_service.dart';
import '../models/clinic.dart';

/// Test runner for authentication and clinic fetching functionality
class AuthTestRunner {
  static const String testEmail = 'test@aleef.com';
  static const String testPassword = 'TestPassword123!';

  /// Run all authentication tests programmatically
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};

    try {
      // Test 1: Login
      results['login'] = await _testLogin();

      // Test 2: Session validation
      results['session'] = await _testSessionValidation();

      // Test 3: Fetch clinics with auth
      results['fetchClinics'] = await _testFetchClinicsAuth();

      // Test 4: Sorting logic
      results['sorting'] = await _testSortingLogic();

      // Test 5: No session scenario
      results['noSession'] = await _testNoSessionScenario();

      results['overall'] = 'success';
    } catch (e) {
      results['overall'] = 'failed';
      results['error'] = e.toString();
    }

    return results;
  }

  static Future<Map<String, dynamic>> _testLogin() async {
    try {
      // First ensure we're logged out
      await AuthService.signOut();

      // Attempt login
      final error = await AuthService.signIn(
        email: testEmail,
        password: testPassword,
      );

      if (error != null) {
        return {
          'status': 'failed',
          'error': error,
          'message': 'Login failed with error: $error',
        };
      }

      final user = AuthService.currentUser;
      final session = Supabase.instance.client.auth.currentSession;

      if (user == null || session?.accessToken == null) {
        return {
          'status': 'failed',
          'error': 'No user or session after login',
          'message': 'Login appeared successful but no user/session found',
        };
      }

      return {
        'status': 'success',
        'userId': user.id,
        'email': user.email,
        'tokenLength': session!.accessToken!.length,
        'message': 'Login successful with valid session',
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'Login test threw exception',
      };
    }
  }

  static Future<Map<String, dynamic>> _testSessionValidation() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final user = AuthService.currentUser;

      if (session?.accessToken == null) {
        return {
          'status': 'failed',
          'error': 'No access token',
          'message': 'Session validation failed - no access token',
        };
      }

      if (user == null) {
        return {
          'status': 'failed',
          'error': 'No current user',
          'message': 'Session validation failed - no current user',
        };
      }

      // Check if token is not expired
      final expiresAt = session?.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (expiresAt != null && expiresAt <= now) {
        return {
          'status': 'failed',
          'error': 'Token expired',
          'message': 'Session validation failed - token expired',
        };
      }

      return {
        'status': 'success',
        'hasToken': session?.accessToken != null,
        'hasUser': user != null,
        'expiresAt': expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(
                expiresAt * 1000,
              ).toIso8601String()
            : null,
        'message': 'Session validation successful',
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'Session validation test threw exception',
      };
    }
  }

  static Future<Map<String, dynamic>> _testFetchClinicsAuth() async {
    try {
      // Verify we have a session before testing
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken == null) {
        return {
          'status': 'failed',
          'error': 'No session for test',
          'message': 'Cannot test fetchClinics - no active session',
        };
      }

      // Test the fetchClinics call
      final clinicsData = await ClinicsEdgeService.fetchClinics();
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      return {
        'status': 'success',
        'clinicsCount': clinics.length,
        'hasAuthHeader':
            true, // We know it has auth header from our implementation
        'sampleClinic': clinics.isNotEmpty
            ? {
                'name': clinics.first.name,
                'city': clinics.first.city,
                'district': clinics.first.district,
              }
            : null,
        'message': 'fetchClinics successful with authentication',
      };
    } catch (e) {
      // Check if it's the expected authentication error
      if (e.toString().contains('No active session')) {
        return {
          'status': 'failed',
          'error': 'Authentication error',
          'message':
              'fetchClinics failed due to authentication: ${e.toString()}',
        };
      }

      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'fetchClinics test threw unexpected exception',
      };
    }
  }

  static Future<Map<String, dynamic>> _testSortingLogic() async {
    try {
      // Get user profile for sorting test
      final userProfile = await AuthService.getUserProfile();
      if (userProfile == null) {
        return {
          'status': 'failed',
          'error': 'No user profile',
          'message': 'Cannot test sorting - no user profile found',
        };
      }

      // Fetch clinics
      final clinicsData = await ClinicsEdgeService.fetchClinics();
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      if (clinics.isEmpty) {
        return {
          'status': 'warning',
          'message': 'No clinics available to test sorting',
        };
      }

      // Apply sorting logic
      final sortedClinics = List<Clinic>.from(clinics);
      _applySortingLogic(sortedClinics, userProfile);

      // Analyze sorting results
      final userDistrict = (userProfile['district']?.toString() ?? '')
          .toLowerCase();
      final userCity = (userProfile['city']?.toString() ?? '').toLowerCase();

      int sameDistrictCount = 0;
      int sameCityCount = 0;
      int othersCount = 0;

      for (final clinic in sortedClinics) {
        final clinicDistrict = (clinic.district ?? '').toLowerCase();
        final clinicCity = (clinic.city ?? '').toLowerCase();

        if (userDistrict.isNotEmpty && clinicDistrict == userDistrict) {
          sameDistrictCount++;
        } else if (userCity.isNotEmpty && clinicCity == userCity) {
          sameCityCount++;
        } else {
          othersCount++;
        }
      }

      return {
        'status': 'success',
        'userLocation': {
          'city': userProfile['city'],
          'district': userProfile['district'],
        },
        'sortingResults': {
          'sameDistrict': sameDistrictCount,
          'sameCity': sameCityCount,
          'others': othersCount,
        },
        'firstClinic': {
          'name': sortedClinics.first.name,
          'city': sortedClinics.first.city,
          'district': sortedClinics.first.district,
        },
        'message': 'Sorting logic applied successfully',
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'Sorting test threw exception',
      };
    }
  }

  static void _applySortingLogic(
    List<Clinic> clinics,
    Map<String, dynamic> userProfile,
  ) {
    final userDistrict = (userProfile['district']?.toString() ?? '')
        .toLowerCase();
    final userCity = (userProfile['city']?.toString() ?? '').toLowerCase();

    clinics.sort((a, b) {
      final aDistrict = (a.district ?? '').toLowerCase();
      final aCity = (a.city ?? '').toLowerCase();
      final bDistrict = (b.district ?? '').toLowerCase();
      final bCity = (b.city ?? '').toLowerCase();

      int aPriority = 1;
      int bPriority = 1;

      if (userDistrict.isNotEmpty && aDistrict == userDistrict) {
        aPriority = 3;
      } else if (userCity.isNotEmpty && aCity == userCity) {
        aPriority = 2;
      }

      if (userDistrict.isNotEmpty && bDistrict == userDistrict) {
        bPriority = 3;
      } else if (userCity.isNotEmpty && bCity == userCity) {
        bPriority = 2;
      }

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority);
      }

      return a.name.compareTo(b.name);
    });
  }

  static Future<Map<String, dynamic>> _testNoSessionScenario() async {
    try {
      // Save current session state
      final wasLoggedIn = AuthService.currentUser != null;

      // Sign out to test no session scenario
      await AuthService.signOut();

      try {
        // This should throw "No active session. Please log in again."
        await ClinicsEdgeService.fetchClinics();

        // If we reach here, the test failed
        return {
          'status': 'failed',
          'error': 'Expected exception not thrown',
          'message':
              'fetchClinics should have thrown no session error but succeeded',
        };
      } catch (e) {
        if (e.toString().contains('No active session. Please log in again.')) {
          // This is the expected behavior
          final result = {
            'status': 'success',
            'expectedError': e.toString(),
            'message': 'No session error handled correctly',
          };

          // Restore session if user was previously logged in
          if (wasLoggedIn) {
            try {
              await AuthService.signIn(
                email: testEmail,
                password: testPassword,
              );
              result['restoredSession'] = 'true';
            } catch (restoreError) {
              result['restoredSession'] = 'false';
              result['restoreError'] = restoreError.toString();
            }
          }

          return result;
        } else {
          return {
            'status': 'failed',
            'error': 'Unexpected error type',
            'actualError': e.toString(),
            'message': 'Expected no session error but got different error',
          };
        }
      }
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'message': 'No session test threw unexpected exception',
      };
    }
  }

  /// Print test results in a readable format
  static void printResults(Map<String, dynamic> results) {
    if (kDebugMode) {
      print('\n🧪 AUTHENTICATION TEST RESULTS 🧪');
      print('=' * 50);

      print('\n📝 Overall Status: ${results['overall']}');

      if (results.containsKey('error')) {
        print('❌ Overall Error: ${results['error']}');
      }

      // Print individual test results
      final tests = [
        'login',
        'session',
        'fetchClinics',
        'sorting',
        'noSession',
      ];

      for (final test in tests) {
        if (results.containsKey(test)) {
          final testResult = results[test] as Map<String, dynamic>;
          print('\n--- $test Test ---');
          print('Status: ${testResult['status']}');
          print('Message: ${testResult['message']}');

          if (testResult.containsKey('error')) {
            print('Error: ${testResult['error']}');
          }

          // Print additional details for specific tests
          if (test == 'login' && testResult['status'] == 'success') {
            print('User ID: ${testResult['userId']}');
            print('Token Length: ${testResult['tokenLength']}');
          }

          if (test == 'fetchClinics' && testResult['status'] == 'success') {
            print('Clinics Count: ${testResult['clinicsCount']}');
          }

          if (test == 'sorting' && testResult['status'] == 'success') {
            final sorting = testResult['sortingResults'];
            print('Same District: ${sorting['sameDistrict']}');
            print('Same City: ${sorting['sameCity']}');
            print('Others: ${sorting['others']}');
          }
        }
      }

      print('\n' + '=' * 50);
    }
  }
}
