import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestDatabaseAccess extends StatefulWidget {
  const TestDatabaseAccess({super.key});

  @override
  State<TestDatabaseAccess> createState() => _TestDatabaseAccessState();
}

class _TestDatabaseAccessState extends State<TestDatabaseAccess> {
  String _results = '';
  bool _isRunning = false;

  Future<void> _testDatabaseAccess() async {
    setState(() {
      _isRunning = true;
      _results = 'Testing database access...\n\n';
    });

    try {
      final supabase = Supabase.instance.client;

      _addResult('🔍 Testing authentication...');
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;

      if (session == null || user == null) {
        _addResult('❌ Not authenticated');
        return;
      }

      _addResult('✅ Authenticated as: ${user.email}');

      _addResult('\n🔍 Testing direct table access...');

      try {
        // Test 1: Simple count query
        _addResult('Test 1: Counting clinics...');
        final countResponse = await supabase
            .from('Clinic')
            .select('clinic_id')
            .count(CountOption.exact);

        _addResult('✅ Clinic count: ${countResponse.count}');

        // Test 2: Simple select query
        _addResult('\nTest 2: Fetching clinic names...');
        final nameResponse = await supabase
            .from('Clinic')
            .select('clinic_id, name')
            .limit(3);

        _addResult('✅ Fetched ${nameResponse.length} clinic names:');
        for (final clinic in nameResponse) {
          _addResult('  - ${clinic['name']} (ID: ${clinic['clinic_id']})');
        }

        // Test 3: Full clinic data
        _addResult('\nTest 3: Fetching full clinic data...');
        final fullResponse = await supabase
            .from('Clinic')
            .select(
              'clinic_id, name, city, district, examination_price, profile_image',
            )
            .limit(2);

        _addResult('✅ Fetched ${fullResponse.length} full clinic records:');
        for (final clinic in fullResponse) {
          _addResult('  - Name: ${clinic['name']}');
          _addResult('    City: ${clinic['city']}');
          _addResult('    District: ${clinic['district']}');
          _addResult('    Price: ${clinic['examination_price']}');
          _addResult('');
        }
      } catch (e) {
        _addResult('❌ Database access failed: $e');

        if (e is PostgrestException) {
          _addResult('🔍 Postgres error details:');
          _addResult('  Code: ${e.code}');
          _addResult('  Message: ${e.message}');
          _addResult('  Details: ${e.details}');
          _addResult('  Hint: ${e.hint}');

          if (e.code == '42501') {
            _addResult('');
            _addResult(
              '🚨 SOLUTION: This is a Row Level Security (RLS) error!',
            );
            _addResult(
              'Fix: Go to Supabase Dashboard → Database → Tables → Clinic',
            );
            _addResult(
              'Either disable RLS or add a policy for authenticated users',
            );
          }
        }
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
      _results += '$result\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Database Access'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _testDatabaseAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isRunning
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Testing...'),
                      ],
                    )
                  : const Text('Test Database Access'),
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
                    _results.isEmpty
                        ? 'Click "Test Database Access" to start...'
                        : _results,
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



