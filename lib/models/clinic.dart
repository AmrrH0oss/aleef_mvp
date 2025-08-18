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
  });

  factory Clinic.fromMap(Map<String, dynamic> map) {
    return Clinic(
      clinicId: (map['clinic_id'] ?? map['id'] ?? '').toString(),
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      phone: map['phone']?.toString(),
      specialty:
          map['specialiy'] as String? ??
          map['specialty'] as String?, // Handle typo in DB
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      examinationPrice: map['examination_price'] != null
          ? (map['examination_price'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clinic_id': int.tryParse(clinicId) ?? clinicId,
      'name': name,
      'location': location,
      'phone': phone,
      'specialiy': specialty, // Use the actual DB column name
      'rating': rating,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'examination_price': examinationPrice,
    };
  }

  @override
  String toString() {
    return 'Clinic(clinicId: $clinicId, name: $name, location: $location, phone: $phone, specialty: $specialty, rating: $rating, imageUrl: $imageUrl, createdAt: $createdAt, examinationPrice: $examinationPrice)';
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
    );
  }
}
