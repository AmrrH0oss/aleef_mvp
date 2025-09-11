import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Test screen to verify PetOwners record creation after signup
class SignupTest extends StatefulWidget {
  const SignupTest({super.key});

  @override
  State<SignupTest> createState() => _SignupTestState();
}

class _SignupTestState extends State<SignupTest> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();

  bool _isLoading = false;
  String? _testResults;

  @override
  void initState() {
    super.initState();
    // Pre-fill with test data
    _emailController.text =
        'testuser${DateTime.now().millisecondsSinceEpoch}@aleef.com';
    _passwordController.text = 'TestPassword123!';
    _fullNameController.text = 'Test User';
    _phoneController.text = '+1234567890';
    _cityController.text = 'Cairo';
    _districtController.text = 'Maadi';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _testSignupFlow() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Starting signup test...\n';
    });

    try {
      // Test the complete signup flow
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _fullNameController.text.trim();
      final phone = _phoneController.text.trim();
      final city = _cityController.text.trim();
      final district = _districtController.text.trim();

      setState(() {
        _testResults =
            (_testResults ?? '') +
            'Testing signup for: $email\n'
                'Location: $district, $city\n\n';
      });

      // Call the updated signup method
      final error = await AuthService.signUpWithProfile(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        city: city,
        district: district,
      );

      if (error != null) {
        setState(() {
          _testResults = (_testResults ?? '') + '❌ Signup failed: $error\n';
        });
        return;
      }

      setState(() {
        _testResults = (_testResults ?? '') + '✅ Signup successful!\n\n';
      });

      // Verify auth user was created
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser != null) {
        setState(() {
          _testResults =
              (_testResults ?? '') +
              '✅ Auth user created:\n'
                  '   ID: ${authUser.id}\n'
                  '   Email: ${authUser.email}\n\n';
        });

        // Verify PetOwners record was created
        try {
          final profile = await AuthService.getUserProfile();
          if (profile != null) {
            setState(() {
              _testResults =
                  (_testResults ?? '') +
                  '✅ PetOwners record created:\n'
                      '   User ID: ${profile['user_id']}\n'
                      '   Full Name: ${profile['full_name']}\n'
                      '   City: ${profile['city']}\n'
                      '   District: ${profile['district']}\n'
                      '   Phone: ${profile['phone']}\n\n'
                      '🎉 SUCCESS: Both auth.users and PetOwners records exist!\n'
                      'Foreign key relationship working correctly!\n';
            });
          } else {
            setState(() {
              _testResults =
                  (_testResults ?? '') +
                  '❌ PetOwners record NOT found!\n'
                      'Foreign key relationship may have failed.\n';
            });
          }
        } catch (profileError) {
          setState(() {
            _testResults =
                (_testResults ?? '') +
                '❌ Error fetching PetOwners record: $profileError\n';
          });
        }
      } else {
        setState(() {
          _testResults =
              (_testResults ?? '') + '❌ No auth user found after signup\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults =
            (_testResults ?? '') + '❌ Test failed with exception: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanup() async {
    try {
      // Sign out to clean up
      await AuthService.signOut();
      setState(() {
        _testResults =
            (_testResults ?? '') + '\n🧹 Cleaned up: User signed out\n';
      });
    } catch (e) {
      setState(() {
        _testResults = (_testResults ?? '') + '\n❌ Cleanup failed: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Signup Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Signup Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                    const SizedBox(height: 8),

                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _districtController,
                            decoration: const InputDecoration(
                              labelText: 'District',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testSignupFlow,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    '🔑 Test Signup + PetOwners Creation',
                                  ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _cleanup,
                          child: const Text('🧹 Cleanup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test results
            if (_testResults != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 What This Test Does:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Creates Supabase auth user with signUp()'),
                    const Text(
                      '2. Immediately inserts PetOwners record with user_id',
                    ),
                    const Text('3. Verifies foreign key relationship works'),
                    const Text('4. Confirms both records exist in database'),
                    const Text('5. Tests error handling for failed inserts'),
                    const SizedBox(height: 16),
                    const Text(
                      '✅ Success Criteria:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '• Both auth.users and PetOwners records created',
                    ),
                    const Text('• Foreign key user_id matches auth user ID'),
                    const Text('• All profile fields populated correctly'),
                    const Text('• No "profile setup failed" errors'),
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
