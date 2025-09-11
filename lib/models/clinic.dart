class Clinic {
  final String clinicId;
  final String name;
  final String location;
  final String? phone;
  final String? specialty;
  final double? rating;
  final String? imageUrl;
  final DateTime? createdAt;
  final double? examinationPrice;
  final String? city;
  final String? district;
  final int? reviewsCount;
  final int?
  locationPriority; // For location-based sorting (3=same district, 2=same city, 1=other)
  final String? distanceInfo; // Human-readable distance information
  final int?
  rank; // Location rank from Edge Function (2=same district, 1=same city, 0=other)
  final String? profileImage; // Profile image URL

  const Clinic({
    required this.clinicId,
    required this.name,
    required this.location,
    this.phone,
    this.specialty,
    this.rating,
    this.imageUrl,
    this.createdAt,
    this.examinationPrice,
    this.city,
    this.district,
    this.reviewsCount,
    this.locationPriority,
    this.distanceInfo,
    this.rank,
    this.profileImage,
  });

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      clinicId: (map['clinic_id'] ?? map['id'] ?? '')
          .toString(), // Handle UUID clinic_id from actual DB
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      phone: map['phone']?.toString(),
      specialty:
          map['specialiy'] as String? ??
          map['specialty'] as String?, // Handle typo in DB
      rating: map['rating'] != null
          ? (map['rating'] as num).toDouble()
          : map['avg_rating'] != null
          ? (map['avg_rating'] as num).toDouble()
          : null,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      examinationPrice: map['examination_price'] != null
          ? (map['examination_price'] as num).toDouble()
          : null,
      city: map['city'] as String?,
      district: map['district'] as String?,
      reviewsCount: map['reviews_count'] != null
          ? (map['reviews_count'] as num).toInt()
          : null,
      locationPriority: map['location_priority'] != null
          ? (map['location_priority'] as num).toInt()
          : null,
      distanceInfo: map['distance_info'] as String?,
      rank: map['_rank'] != null ? (map['_rank'] as num).toInt() : null,
      profileImage: map['profile_image'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinic_id': clinicId, // Keep as string since it's UUID in actual DB
      'name': name,
      'location': location,
      'phone': phone,
      'specialiy': specialty, // Use the actual DB column name
      'rating': rating,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'examination_price': examinationPrice,
      'city': city,
      'district': district,
      'reviews_count': reviewsCount,
      'location_priority': locationPriority,
      'distance_info': distanceInfo,
      '_rank': rank,
      'profile_image': profileImage,
    };
  }

  @override
  String toString() {
    return 'Clinic(clinicId: $clinicId, name: $name, location: $location, phone: $phone, specialty: $specialty, rating: $rating, imageUrl: $imageUrl, createdAt: $createdAt, examinationPrice: $examinationPrice, city: $city, district: $district, reviewsCount: $reviewsCount, locationPriority: $locationPriority, distanceInfo: $distanceInfo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clinic && other.clinicId == clinicId;
  }

  @override
  int get hashCode => clinicId.hashCode;

  Clinic copyWith({
    String? clinicId,
    String? name,
    String? location,
    String? phone,
    String? specialty,
    double? rating,
    String? imageUrl,
    DateTime? createdAt,
    double? examinationPrice,
    String? city,
    String? district,
    int? reviewsCount,
    int? locationPriority,
    String? distanceInfo,
    int? rank,
    String? profileImage,
  }) {
    return Clinic(
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      examinationPrice: examinationPrice ?? this.examinationPrice,
      city: city ?? this.city,
      district: district ?? this.district,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      locationPriority: locationPriority ?? this.locationPriority,
      distanceInfo: distanceInfo ?? this.distanceInfo,
      rank: rank ?? this.rank,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
