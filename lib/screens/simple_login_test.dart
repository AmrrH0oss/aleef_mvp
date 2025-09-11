import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Simple login test screen for quick authentication testing
class SimpleLoginTest extends StatefulWidget {
  const SimpleLoginTest({super.key});

  @override
  State<SimpleLoginTest> createState() => _SimpleLoginTestState();
}

class _SimpleLoginTestState extends State<SimpleLoginTest> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    // Pre-fill with test credentials for quick testing
    _emailController.text = 'test@aleef.com';
    _passwordController.text = 'TestPassword123!';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final error = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (error != null) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
      } else {
        setState(() {
          _success = 'Login successful! You can now access clinics.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    setState(() {
      _success = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Login Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Session Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isLoggedIn ? Colors.green.shade50 : Colors.red.shade50,
                border: Border.all(
                  color: isLoggedIn ? Colors.green : Colors.red,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isLoggedIn ? Icons.check_circle : Icons.error,
                        color: isLoggedIn ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLoggedIn ? 'Logged In' : 'Not Logged In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLoggedIn
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (isLoggedIn) ...[
                    const SizedBox(height: 8),
                    Text(
                      'User: ${Supabase.instance.client.auth.currentUser?.email ?? 'Unknown'}',
                    ),
                    Text('Token: ${session.accessToken.substring(0, 20)}...'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!isLoggedIn) ...[
              // Login Form
              const Text(
                'Test Credentials',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

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

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _testLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('🔑 Test Login'),
              ),
            ] else ...[
              // Logged In Actions
              const Text(
                'Authentication Successful!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/clinics-simple');
                },
                icon: const Icon(Icons.local_hospital),
                label: const Text('🏥 View Clinics (Should Work Now)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],

            const SizedBox(height: 24),

            // Status Messages
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),

            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _success!,
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Use the test credentials above to login'),
                  Text('2. After successful login, tap "View Clinics"'),
                  Text('3. Clinics should load sorted by your location'),
                  Text('4. No more "No active session" errors!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

