import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pet.dart';

class PetService {
  static final _supabase = Supabase.instance.client;

  /// Adds a new pet to the database
  static Future<Pet> addPet({
    required String name,
    required String species,
    required String gender,
    required String breed,
    double? weight,
    required DateTime dateOfBirth,
  }) async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      print('🐾 [PET-SERVICE] Adding pet for user: ${user.email}');

      // Get user's pet_owner_id
      final petOwnerResponse = await _supabase
          .from('PetOwners')
          .select('pet_owner_id')
          .eq('user_id', user.id)
          .single();

      final petOwnerId = petOwnerResponse['pet_owner_id'];
      print('👤 [PET-SERVICE] Pet owner ID: $petOwnerId');

      // Create pet data (let Supabase generate the UUID automatically)
      final petData = {
        // Don't include 'pet_id' - let Supabase generate it with gen_random_uuid()
        'name': name,
        'species': species,
        'gender': gender,
        'breed': breed,
        'weight': weight,
        'date_of_birth': dateOfBirth.toIso8601String().split(
          'T',
        )[0], // Date only
        'owner_id': petOwnerId,
      };

      print('🐾 [PET-SERVICE] Inserting pet data: ${petData.toString()}');

      // Insert pet into database
      final response = await _supabase
          .from('pet')
          .insert(petData)
          .select()
          .single();

      print('✅ [PET-SERVICE] Pet added successfully: ${response['name']}');

      // Return Pet object
      return Pet.fromMap(response);
    } catch (e) {
      print('❌ [PET-SERVICE] Error adding pet: $e');
      rethrow;
    }
  }

  /// Gets all pets for the current user
  static Future<List<Pet>> getUserPets() async {
    try {
      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      print('🐾 [PET-SERVICE] Fetching pets for user: ${user.email}');

      // Get user's pet_owner_id
      final petOwnerResponse = await _supabase
          .from('PetOwners')
          .select('pet_owner_id')
          .eq('user_id', user.id)
          .single();

      final petOwnerId = petOwnerResponse['pet_owner_id'];

      // Get all pets for this owner
      final response = await _supabase
          .from('pet')
          .select('*')
          .eq('owner_id', petOwnerId)
          .order('created_at', ascending: false);

      print('🐾 [PET-SERVICE] Found ${response.length} pets');

      // Convert to Pet objects
      final pets = response.map((petData) => Pet.fromMap(petData)).toList();

      return pets;
    } catch (e) {
      print('❌ [PET-SERVICE] Error fetching pets: $e');
      rethrow;
    }
  }

  /// Gets a specific pet by ID
  static Future<Pet> getPetById(String petId) async {
    try {
      print('🐾 [PET-SERVICE] Fetching pet with ID: $petId');

      final response = await _supabase
          .from('pet')
          .select('*')
          .eq('pet_id', petId)
          .single();

      print('✅ [PET-SERVICE] Pet fetched successfully: ${response['name']}');

      return Pet.fromMap(response);
    } catch (e) {
      print('❌ [PET-SERVICE] Error fetching pet: $e');
      rethrow;
    }
  }

  /// Updates an existing pet
  static Future<Pet> updatePet({
    required String petId,
    String? name,
    String? species,
    String? gender,
    String? breed,
    double? weight,
    DateTime? dateOfBirth,
  }) async {
    try {
      print('🐾 [PET-SERVICE] Updating pet with ID: $petId');

      // Create update data (only include non-null values)
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (species != null) updateData['species'] = species;
      if (gender != null) updateData['gender'] = gender;
      if (breed != null) updateData['breed'] = breed;
      if (weight != null) updateData['weight'] = weight;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String().split(
          'T',
        )[0];
      }

      print('🐾 [PET-SERVICE] Update data: ${updateData.toString()}');

      // Update pet in database
      final response = await _supabase
          .from('pet')
          .update(updateData)
          .eq('pet_id', petId)
          .select()
          .single();

      print('✅ [PET-SERVICE] Pet updated successfully: ${response['name']}');

      return Pet.fromMap(response);
    } catch (e) {
      print('❌ [PET-SERVICE] Error updating pet: $e');
      rethrow;
    }
  }

  /// Deletes a pet
  static Future<void> deletePet(String petId) async {
    try {
      print('🐾 [PET-SERVICE] Deleting pet with ID: $petId');

      await _supabase.from('pet').delete().eq('pet_id', petId);

      print('✅ [PET-SERVICE] Pet deleted successfully');
    } catch (e) {
      print('❌ [PET-SERVICE] Error deleting pet: $e');
      rethrow;
    }
  }

  /// Validates pet data before submission
  static String? validatePetData({
    required String name,
    required String species,
    required String gender,
    required String breed,
    double? weight,
    required DateTime dateOfBirth,
  }) {
    // Name validation
    if (name.trim().isEmpty) {
      return 'Pet name is required';
    }
    if (name.trim().length < 2) {
      return 'Pet name must be at least 2 characters';
    }
    if (name.trim().length > 50) {
      return 'Pet name must be less than 50 characters';
    }

    // Species validation
    if (species.trim().isEmpty) {
      return 'Pet species is required';
    }

    // Gender validation
    if (gender.trim().isEmpty) {
      return 'Pet gender is required';
    }

    // Breed validation
    if (breed.trim().isEmpty) {
      return 'Pet breed is required';
    }

    // Weight validation
    if (weight != null && weight <= 0) {
      return 'Weight must be greater than 0';
    }
    if (weight != null && weight > 500) {
      return 'Weight seems too high. Please check the value.';
    }

    // Date of birth validation
    final now = DateTime.now();
    if (dateOfBirth.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    final maxAge = now.subtract(const Duration(days: 365 * 50)); // 50 years max
    if (dateOfBirth.isBefore(maxAge)) {
      return 'Date of birth seems too old. Please check the date.';
    }

    return null; // No validation errors
  }

  /// Helper method to handle service errors
  static String handleError(dynamic error) {
    if (error.toString().contains('No authenticated user')) {
      return 'Please log in to add pets';
    } else if (error.toString().contains('Pet owner profile not found')) {
      return 'Profile not found. Please complete your profile first.';
    } else if (error.toString().contains('duplicate key')) {
      return 'A pet with this information already exists';
    } else if (error.toString().contains('foreign key')) {
      return 'Invalid owner information. Please try again.';
    } else if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'Failed to save pet information. Please try again.';
    }
  }
}
