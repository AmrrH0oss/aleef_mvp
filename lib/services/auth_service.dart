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

  // Sign up with email, password and profile data
  static Future<String?> signUpWithProfile({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
    required String district,
    String? profileImage,
  }) async {
    try {
      print('DEBUG: Starting signup process for email: $email');

      // Step 1: Sign up the user with Supabase auth with metadata for trigger
      // The database trigger will automatically create PetOwners record
      print('DEBUG: Calling supabase.auth.signUp with user metadata...');
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'city': city,
          'district': district,
          'profile_image': profileImage,
        },
      );
      print('DEBUG: Auth signup completed. Response: ${response.user?.id}');

      if (response.user == null) {
        print('DEBUG: Signup failed - no user returned');
        return 'Failed to create user account';
      }

      // Step 2: Get the user ID from the response
      final userId = response.user!.id;
      print('DEBUG: User created successfully with ID: $userId');

      // Step 3: Verify PetOwners record was created by trigger
      // The database trigger should have automatically created the record
      try {
        print('DEBUG: Verifying PetOwners record was created by trigger...');

        // Wait a moment for the trigger to complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if PetOwners record exists
        final petOwnerRecord = await _supabase
            .from('PetOwners')
            .select('pet_owner_id, user_id, Full_name')
            .eq('user_id', userId)
            .maybeSingle();

        if (petOwnerRecord != null) {
          print('DEBUG: PetOwners record found: $petOwnerRecord');
          print('DEBUG: Signup completed successfully for user: $email');
          return null; // Success
        } else {
          print('DEBUG: No PetOwners record found - trigger may have failed');
          return 'Account created but profile setup failed: Database trigger error. Please contact support.';
        }
      } catch (verificationError) {
        print('DEBUG: Error verifying PetOwners record: $verificationError');
        return 'Account created but profile verification failed: ${verificationError.toString()}';
      }
    } catch (e) {
      print('DEBUG: Signup process failed: $e');
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

  // Get current user's profile from PetOwners table
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _supabase
          .from('PetOwners')
          .select('*')
          .eq('user_id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Test method: Sign up with auth only (no PetOwners insert)
  static Future<String?> signUpAuthOnly({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: Testing auth-only signup for email: $email');

      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      print('DEBUG: Auth-only signup result: ${response.user?.id}');

      if (response.user == null) {
        return 'Failed to create auth user';
      }

      return null; // Success
    } catch (e) {
      print('DEBUG: Auth-only signup failed: $e');
      return _handleAuthError(e);
    }
  }

  // Test method: Sign up without trigger (manual PetOwners insert)
  static Future<String?> signUpWithoutTrigger({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
    required String district,
    String? profileImage,
  }) async {
    try {
      print('DEBUG: Testing signup WITHOUT trigger for email: $email');

      // Step 1: Sign up with NO metadata to avoid trigger
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
        // NO data parameter - this should bypass trigger issues
      );

      print('DEBUG: Auth signup result: ${response.user?.id}');

      if (response.user == null) {
        return 'Failed to create auth user';
      }

      final userId = response.user!.id;

      // Step 2: Manually insert PetOwners record
      try {
        print('DEBUG: Manually inserting PetOwners record...');

        final insertData = {
          'user_id': userId,
          'Full_name': fullName,
          'phone': phone,
          'city': city,
          'district': district,
        };

        if (profileImage != null && profileImage.isNotEmpty) {
          insertData['profile_image'] = profileImage;
        }

        final insertResponse = await _supabase
            .from('PetOwners')
            .insert(insertData)
            .select('pet_owner_id, user_id')
            .single();

        print('DEBUG: Manual PetOwners insert successful: $insertResponse');
        return null; // Success
      } catch (insertError) {
        print('DEBUG: Manual PetOwners insert failed: $insertError');
        return 'Account created but manual profile setup failed: ${insertError.toString()}';
      }
    } catch (e) {
      print('DEBUG: Signup without trigger failed: $e');
      return _handleAuthError(e);
    }
  }

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
