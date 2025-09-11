import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthOnlyTestScreen extends StatefulWidget {
  const AuthOnlyTestScreen({super.key});

  @override
  State<AuthOnlyTestScreen> createState() => _AuthOnlyTestScreenState();
}

class _AuthOnlyTestScreenState extends State<AuthOnlyTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  bool _isLoading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    // Pre-fill with test data
    _emailController.text =
        'testuser${DateTime.now().millisecondsSinceEpoch}@aleef.com';
    _passwordController.text = 'password123';
    _fullNameController.text = 'Test User';
    _phoneController.text = '+201234567890';
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

  Future<void> _testAuthOnly() async {
    if (_isLoading) return;

    // Generate a fresh email for each test to avoid conflicts
    final freshEmail =
        'testuser${DateTime.now().millisecondsSinceEpoch}@aleef.com';
    _emailController.text = freshEmail;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      print('=== TESTING AUTH-ONLY SIGNUP ===');
      print('DEBUG: Using fresh email: $freshEmail');
      final result = await AuthService.signUpAuthOnly(
        email: freshEmail,
        password: _passwordController.text.trim(),
      );

      setState(() {
        if (result == null) {
          _result = '✅ SUCCESS: Auth user created successfully!';
        } else {
          _result = '❌ FAILED: $result';
        }
      });
    } catch (e) {
      setState(() {
        _result = '❌ EXCEPTION: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testWithoutTrigger() async {
    if (_isLoading) return;

    // Generate a fresh email for each test to avoid conflicts
    final freshEmail =
        'testuser${DateTime.now().millisecondsSinceEpoch}@aleef.com';
    _emailController.text = freshEmail;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      print('=== TESTING SIGNUP WITHOUT TRIGGER ===');
      print('DEBUG: Using fresh email: $freshEmail');
      final result = await AuthService.signUpWithoutTrigger(
        email: freshEmail,
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
      );

      setState(() {
        if (result == null) {
          _result = '✅ SUCCESS: Auth user + PetOwners created successfully!';
        } else {
          _result = '❌ FAILED: $result';
        }
      });
    } catch (e) {
      setState(() {
        _result = '❌ EXCEPTION: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth-Only Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧪 Auth-Only Signup Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Test different signup approaches to isolate the database issue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

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
                const SizedBox(width: 16),
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
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _testAuthOnly,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('🔒 Test Auth-Only Signup'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _testWithoutTrigger,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('✋ Test Without Trigger'),
            ),

            if (_result != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _result!.startsWith('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  border: Border.all(
                    color: _result!.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!,
                  style: TextStyle(
                    color: _result!.startsWith('✅')
                        ? Colors.green[800]
                        : Colors.red[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              '💡 Test Results:',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '🔒 Auth-Only: Tests if basic Supabase auth works\n'
              '✋ Without Trigger: Tests manual PetOwners creation',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
