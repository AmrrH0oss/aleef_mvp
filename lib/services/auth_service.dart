import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Get auth state changes stream
  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // Sign up with email and password
  static Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      // Step 1: Sign up the user
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return 'Failed to create user account';
      }

      // Step 2: Insert profile into "Pet owners" table
      try {
        print('DEBUG: Creating profile for user: ${response.user!.id}');
        print('DEBUG: Full name: $fullName, Phone: $phone');

        // Check if profile already exists
        final existingProfile = await _supabase
            .from('Pet owners')
            .select()
            .eq('pet_owner_id', response.user!.id)
            .maybeSingle();

        print('DEBUG: Existing profile: $existingProfile');

        if (existingProfile == null) {
          // Insert new profile
          final insertResult = await _supabase.from('Pet owners').insert({
            'pet_owner_id': response.user!.id,
            'Full_name': fullName,
            'phone': phone ?? '', // Provide empty string if phone is null
          });
          print('DEBUG: Profile insert result: $insertResult');
        }
      } catch (profileError) {
        print('Profile creation error: $profileError');
        // Return the error to user so they know there's an issue
        return 'Account created but profile setup failed: $profileError';
      }

      return null; // Success
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Sign in with email and password
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null; // Success
    } catch (e) {
      return _handleAuthError(e);
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update password
  static Future<UserResponse> updatePassword(String newPassword) async {
    return await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Update user profile
  static Future<UserResponse> updateProfile({
    String? email,
    Map<String, dynamic>? userData,
  }) async {
    return await _supabase.auth.updateUser(
      UserAttributes(email: email, data: userData),
    );
  }

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Get user ID
  static String? get userId => currentUser?.id;

  // Helper method to handle authentication errors
  static String _handleAuthError(dynamic error) {
    if (error is AuthException) {
      switch (error.message.toLowerCase()) {
        case 'invalid login credentials':
        case 'invalid email or password':
          return 'Invalid email or password. Please check your credentials.';
        case 'email not confirmed':
          return 'Please check your email and confirm your account before signing in.';
        case 'user already registered':
        case 'user already exists':
          return 'An account with this email already exists. Try signing in instead.';
        case 'password should be at least 6 characters':
        case 'password too short':
          return 'Password must be at least 6 characters long.';
        case 'unable to validate email address: invalid format':
        case 'invalid email format':
        case 'invalid email':
          return 'Please enter a valid email address.';
        case 'signup disabled':
          return 'Account registration is currently disabled.';
        case 'too many requests':
          return 'Too many requests. Please wait a moment and try again.';
        default:
          return error.message.isNotEmpty
              ? error.message
              : 'Authentication failed. Please try again.';
      }
    }

    // Handle network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
