import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/clinics_service.dart';
import 'services/clinics_service_simple.dart';
import 'data/edge/clinics_edge_service.dart';

class DebugClinicsTest extends StatefulWidget {
  const DebugClinicsTest({super.key});

  @override
  State<DebugClinicsTest> createState() => _DebugClinicsTestState();
}

class _DebugClinicsTestState extends State<DebugClinicsTest> {
  String _testResults = '';
  bool _isRunning = false;

  Future<void> _runDebugTest() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Starting debug test...\n\n';
    });

    try {
      // Test 1: Check authentication
      _addResult('🔍 TEST 1: Checking authentication...');
      final session = Supabase.instance.client.auth.currentSession;
      final user = Supabase.instance.client.auth.currentUser;

      if (session == null) {
        _addResult('❌ No active session found');
        _addResult('');
        _addResult('🚨 SOLUTION: You need to log in first!');
        _addResult('1. Go back to the login screen');
        _addResult('2. Enter your email and password');
        _addResult('3. Click "Login"');
        _addResult('4. Then come back to run this test');
        _addResult('');
        _addResult(
          '💡 The clinics page error happens because you\'re not logged in.',
        );
        return;
      }

      _addResult('✅ Session found');
      _addResult('📧 User email: ${user?.email}');
      _addResult('🆔 User ID: ${user?.id}');
      _addResult('🔑 Token length: ${session.accessToken.length}');

      // Test 2: Test direct Edge Function call
      _addResult('\n🔍 TEST 2: Testing direct Edge Function call...');

      try {
        final res = await Supabase.instance.client.functions.invoke(
          'clinics-list',
          body: {},
          headers: {
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          },
        );

        _addResult('✅ Edge Function call successful');
        _addResult('📊 Response status: ${res.status}');
        _addResult('📦 Response data type: ${res.data.runtimeType}');

        if (res.data != null) {
          final data = res.data as Map<String, dynamic>;
          _addResult('🔑 Response keys: ${data.keys.toList()}');

          if (data.containsKey('clinics')) {
            final clinics = data['clinics'];
            _addResult(
              '🏥 Clinics count: ${clinics is List ? clinics.length : 'Not a list'}',
            );

            if (clinics is List && clinics.isNotEmpty) {
              _addResult(
                '📋 First clinic keys: ${(clinics.first as Map).keys.toList()}',
              );
            }
          }

          if (data.containsKey('error')) {
            _addResult('❌ Error in response: ${data['error']}');
          }
        }
      } catch (e) {
        _addResult('❌ Edge Function call failed: $e');
        if (e is FunctionException) {
          _addResult('🔍 Function error details: ${e.details}');
          _addResult('🔍 Function error reason: ${e.reasonPhrase}');
        }
      }

      // Test 3: Test ClinicsEdgeService
      _addResult('\n🔍 TEST 3: Testing ClinicsEdgeService...');

      try {
        final clinicsData =
            await ClinicsEdgeService.fetchClinicsSortedByUserLocation();
        _addResult('✅ ClinicsEdgeService call successful');
        _addResult('🏥 Clinics data count: ${clinicsData.length}');

        if (clinicsData.isNotEmpty) {
          _addResult('📋 First clinic data: ${clinicsData.first}');
        }
      } catch (e) {
        _addResult('❌ ClinicsEdgeService call failed: $e');
      }

      // Test 4: Test Direct Database Query
      _addResult('\n🔍 TEST 4: Testing Direct Database Query...');

      try {
        final clinics = await ClinicsServiceSimple.fetchClinicsDirectly();
        _addResult('✅ Direct database query successful');
        _addResult('🏥 Clinics count: ${clinics.length}');

        if (clinics.isNotEmpty) {
          _addResult('📋 First clinic: ${clinics.first.name}');
        }
      } catch (e) {
        _addResult('❌ Direct database query failed: $e');
      }

      // Test 5: Test ClinicsService
      _addResult('\n🔍 TEST 5: Testing ClinicsService...');

      try {
        final clinics = await ClinicsService.fetchClinics();
        _addResult('✅ ClinicsService call successful');
        _addResult('🏥 Clinics count: ${clinics.length}');

        if (clinics.isNotEmpty) {
          _addResult('📋 First clinic: ${clinics.first.name}');
        }
      } catch (e) {
        _addResult('❌ ClinicsService call failed: $e');
      }
    } catch (e) {
      _addResult('💥 Unexpected error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _addResult(String result) {
    setState(() {
      _testResults += '$result\n';
    });
  }

  void _copyJwtToken() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null) {
        // In a real app, you'd use a clipboard package
        // For now, just show it in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('JWT Token'),
            content: SelectableText(
              session!.accessToken,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active session found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting token: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Clinics Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? null : _runDebugTest,
                  child: _isRunning
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Running Tests...'),
                          ],
                        )
                      : const Text('Run Debug Test'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Go to Login'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _copyJwtToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Copy JWT'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResults.isEmpty
                        ? 'Click "Run Debug Test" to start...'
                        : _testResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
