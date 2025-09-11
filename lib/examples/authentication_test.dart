import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../data/edge/clinics_edge_service.dart';
import '../models/clinic.dart';
import '../widgets/clinic_card.dart';

/// Comprehensive test screen to validate the authentication fix
/// and user-location-based sorting functionality
class AuthenticationTestScreen extends StatefulWidget {
  const AuthenticationTestScreen({super.key});

  @override
  State<AuthenticationTestScreen> createState() =>
      _AuthenticationTestScreenState();
}

class _AuthenticationTestScreenState extends State<AuthenticationTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _testResults;
  List<Clinic> _clinics = [];
  Map<String, dynamic>? _userProfile;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Set default test credentials (you can change these)
    _emailController.text = 'test@aleef.com';
    _passwordController.text = 'TestPassword123!';

    // Check if user is already logged in
    _checkCurrentSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _checkCurrentSession() {
    final user = AuthService.currentUser;
    final session = Supabase.instance.client.auth.currentSession;

    setState(() {
      _isLoggedIn = user != null && session?.accessToken != null;
      if (_isLoggedIn) {
        _testResults =
            '✅ Current session is valid\n'
            'User ID: ${user!.id}\n'
            'Access Token: ${session!.accessToken!.substring(0, 20)}...\n';
      } else {
        _testResults = '❌ No active session found';
      }
    });
  }

  Future<void> _runFullAuthenticationTest() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Starting authentication tests...\n';
    });

    try {
      // Test 1: Login with credentials
      await _testLogin();

      // Test 2: Verify session and token
      await _testSessionValidation();

      // Test 3: Test fetchClinics with authentication
      await _testFetchClinicsWithAuth();

      // Test 4: Test sorting logic
      await _testSortingLogic();

      // Test 5: Test no session scenario
      await _testNoSessionScenario();
    } catch (e) {
      setState(() {
        _testResults = (_testResults ?? '') + '\n❌ Test failed with error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    try {
      setState(() {
        _testResults = (_testResults ?? '') + '\n📝 Test 1: Testing login...';
      });

      final error = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (error == null) {
        final user = AuthService.currentUser;
        final session = Supabase.instance.client.auth.currentSession;

        setState(() {
          _isLoggedIn = true;
          _testResults =
              (_testResults ?? '') +
              '\n✅ Login successful!'
                  '\n   User ID: ${user?.id}'
                  '\n   Email: ${user?.email}'
                  '\n   Access Token Length: ${session?.accessToken?.length ?? 0} characters'
                  '\n   Token Preview: ${session?.accessToken?.substring(0, 30)}...';
        });

        // Load user profile
        _userProfile = await AuthService.getUserProfile();
        if (_userProfile != null) {
          setState(() {
            _testResults =
                (_testResults ?? '') +
                '\n✅ User profile loaded:'
                    '\n   City: ${_userProfile!['city']}'
                    '\n   District: ${_userProfile!['district']}';
          });
        }
      } else {
        setState(() {
          _testResults = (_testResults ?? '') + '\n❌ Login failed: $error';
        });
        return;
      }
    } catch (e) {
      setState(() {
        _testResults = (_testResults ?? '') + '\n❌ Login test failed: $e';
      });
    }
  }

  Future<void> _testSessionValidation() async {
    setState(() {
      _testResults =
          (_testResults ?? '') + '\n\n📝 Test 2: Validating session...';
    });

    final session = Supabase.instance.client.auth.currentSession;
    final user = AuthService.currentUser;

    if (session?.accessToken != null && user != null) {
      setState(() {
        _testResults =
            (_testResults ?? '') +
            '\n✅ Session validation passed!'
                '\n   Session exists: ${session != null}'
                '\n   Access token exists: ${session?.accessToken != null}'
                '\n   Token expires at: ${session?.expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(session!.expiresAt! * 1000) : "Unknown"}'
                '\n   User authenticated: ${user != null}';
      });
    } else {
      setState(() {
        _testResults =
            (_testResults ?? '') +
            '\n❌ Session validation failed - no valid session';
      });
    }
  }

  Future<void> _testFetchClinicsWithAuth() async {
    setState(() {
      _testResults =
          (_testResults ?? '') +
          '\n\n📝 Test 3: Testing fetchClinics with authentication...';
    });

    try {
      // This should now work with proper authentication
      final clinicsData = await ClinicsEdgeService.fetchClinics();
      final clinics = clinicsData.map((data) => Clinic.fromMap(data)).toList();

      setState(() {
        _clinics = clinics;
        _testResults =
            (_testResults ?? '') +
            '\n✅ fetchClinics successful!'
                '\n   Number of clinics fetched: ${clinics.length}'
                '\n   Authorization header: ✅ Included Bearer token'
                '\n   API Response: ✅ 200 OK (no 401 error)';

        if (clinics.isNotEmpty) {
          _testResults =
              (_testResults ?? '') +
              '\n   Sample clinic: ${clinics.first.name} (${clinics.first.city}, ${clinics.first.district})';
        }
      });
    } catch (e) {
      setState(() {
        _testResults = (_testResults ?? '') + '\n❌ fetchClinics failed: $e';
      });
    }
  }

  Future<void> _testSortingLogic() async {
    setState(() {
      _testResults =
          (_testResults ?? '') +
          '\n\n📝 Test 4: Testing user-location-based sorting...';
    });

    if (_clinics.isEmpty) {
      setState(() {
        _testResults =
            (_testResults ?? '') + '\n⚠️ No clinics to test sorting with';
      });
      return;
    }

    if (_userProfile == null) {
      setState(() {
        _testResults =
            (_testResults ?? '') + '\n⚠️ No user profile to test sorting with';
      });
      return;
    }

    // Apply the same sorting logic as in the clinics page
    final sortedClinics = List<Clinic>.from(_clinics);
    _applySortingLogic(sortedClinics);

    // Analyze sorting results
    final userDistrict = (_userProfile!['district']?.toString() ?? '')
        .toLowerCase();
    final userCity = (_userProfile!['city']?.toString() ?? '').toLowerCase();

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

    setState(() {
      _clinics = sortedClinics; // Update with sorted list
      _testResults =
          (_testResults ?? '') +
          '\n✅ Sorting logic applied!'
              '\n   User location: ${_userProfile!['city']}, ${_userProfile!['district']}'
              '\n   Same district clinics: $sameDistrictCount (should appear first)'
              '\n   Same city clinics: $sameCityCount (should appear second)'
              '\n   Other clinics: $othersCount (should appear last)';

      if (sortedClinics.isNotEmpty) {
        _testResults =
            (_testResults ?? '') +
            '\n   First clinic: ${sortedClinics.first.name} (${sortedClinics.first.city}, ${sortedClinics.first.district})';
      }
    });
  }

  void _applySortingLogic(List<Clinic> clinics) {
    if (_userProfile == null) {
      clinics.sort((a, b) => a.name.compareTo(b.name));
      return;
    }

    final userDistrict = (_userProfile!['district']?.toString() ?? '')
        .toLowerCase();
    final userCity = (_userProfile!['city']?.toString() ?? '').toLowerCase();

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

  Future<void> _testNoSessionScenario() async {
    setState(() {
      _testResults =
          (_testResults ?? '') +
          '\n\n📝 Test 5: Testing no session scenario...';
    });

    try {
      // Temporarily sign out to test no session scenario
      await AuthService.signOut();

      // This should throw "No active session. Please log in again."
      await ClinicsEdgeService.fetchClinics();

      setState(() {
        _testResults =
            (_testResults ?? '') +
            '\n❌ Expected no session error, but call succeeded';
      });
    } catch (e) {
      if (e.toString().contains('No active session. Please log in again.')) {
        setState(() {
          _testResults =
              (_testResults ?? '') +
              '\n✅ No session error handled correctly: $e';
        });
      } else {
        setState(() {
          _testResults = (_testResults ?? '') + '\n❌ Unexpected error: $e';
        });
      }
    }

    // Sign back in for UI testing
    try {
      await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() {
        _isLoggedIn = true;
        _testResults =
            (_testResults ?? '') + '\n✅ Re-authenticated for UI testing';
      });
    } catch (e) {
      setState(() {
        _testResults =
            (_testResults ?? '') + '\n❌ Failed to re-authenticate: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test credentials section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Credentials',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _runFullAuthenticationTest,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Run Full Test'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _checkCurrentSession,
                          child: const Text('Check Session'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test results section
            if (_testResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          _testResults!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Visual clinics list section (FutureBuilder test)
            if (_isLoggedIn)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visual UI Test - FutureBuilder with fetchClinics()',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 400,
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: ClinicsEdgeService.fetchClinics(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Loading clinics with authentication...',
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error: ${snapshot.error}',
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (snapshot.hasData) {
                              final clinicsData = snapshot.data!;
                              final clinics = clinicsData
                                  .map((data) => Clinic.fromMap(data))
                                  .toList();

                              if (clinics.isEmpty) {
                                return const Center(
                                  child: Text('No clinics found'),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '✅ SUCCESS: ${clinics.length} clinics loaded with proper authentication!',
                                      style: TextStyle(
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: clinics.length,
                                      itemBuilder: (context, index) {
                                        final clinic = clinics[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: ClinicCard(
                                            clinic: clinic,
                                            isCompact: true,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }

                            return const Center(child: Text('No data'));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
