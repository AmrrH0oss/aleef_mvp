class Pet {
  final String petId;
  final DateTime createdAt;
  final String name;
  final String species;
  final String gender;
  final String breed;
  final double? weight;
  final DateTime dateOfBirth;
  final String ownerId;

  Pet({
    required this.petId,
    required this.createdAt,
    required this.name,
    required this.species,
    required this.gender,
    required this.breed,
    this.weight,
    required this.dateOfBirth,
    required this.ownerId,
  });

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['pet_id'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      gender: map['gender'] ?? '',
      breed: map['breed'] ?? '',
      weight: map['weight']?.toDouble(),
      dateOfBirth: DateTime.parse(
        map['date_of_birth'] ?? DateTime.now().toIso8601String(),
      ),
      ownerId: map['owner_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pet_id': petId,
      'created_at': createdAt.toIso8601String(),
      'name': name,
      'species': species,
      'gender': gender,
      'breed': breed,
      'weight': weight,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // Date only
      'owner_id': ownerId,
    };
  }

  /// Creates a map for inserting into Supabase (without pet_id and created_at)
  Map<String, dynamic> toInsertMap() {
    return {
      'pet_id': petId, // We'll generate UUID in the service
      'name': name,
      'species': species,
      'gender': gender,
      'breed': breed,
      'weight': weight,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // Date only
      'owner_id': ownerId,
    };
  }

  Pet copyWith({
    String? petId,
    DateTime? createdAt,
    String? name,
    String? species,
    String? gender,
    String? breed,
    double? weight,
    DateTime? dateOfBirth,
    String? ownerId,
  }) {
    return Pet(
      petId: petId ?? this.petId,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  @override
  String toString() {
    return 'Pet(petId: $petId, name: $name, species: $species, breed: $breed, gender: $gender, weight: $weight, dateOfBirth: $dateOfBirth, ownerId: $ownerId)';
  }

  /// Get age in years and months
  String get ageString {
    final now = DateTime.now();
    final age = now.difference(dateOfBirth);
    final years = (age.inDays / 365).floor();
    final months = ((age.inDays % 365) / 30).floor();

    if (years > 0) {
      if (months > 0) {
        return '$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}';
      } else {
        return '$years year${years > 1 ? 's' : ''}';
      }
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      final days = age.inDays;
      return '$days day${days > 1 ? 's' : ''}';
    }
  }

  /// Common pet species options
  static const List<String> commonSpecies = ['Dog', 'Cat'];

  /// Common gender options
  static const List<String> genderOptions = ['Male', 'Female'];

  /// Common dog breeds
  static const List<String> dogBreeds = [
    'Golden Retriever',
    'German Shepherd',
    'Labrador Retriever',
    'Bulldog',
    'Poodle',
    'Beagle',
    'Rottweiler',
    'Yorkshire Terrier',
    'Dachshund',
    'Siberian Husky',
    'Mixed Breed',
    'Other',
  ];

  /// Common cat breeds
  static const List<String> catBreeds = [
    'Persian',
    'Maine Coon',
    'British Shorthair',
    'Ragdoll',
    'Bengal',
    'Abyssinian',
    'Russian Blue',
    'Scottish Fold',
    'Siamese',
    'Domestic Shorthair',
    'Mixed Breed',
    'Other',
  ];

  /// Get breed options based on species
  static List<String> getBreedsForSpecies(String species) {
    switch (species.toLowerCase()) {
      case 'dog':
        return dogBreeds;
      case 'cat':
        return catBreeds;
      default:
        return ['Mixed Breed', 'Other'];
    }
  }
}
