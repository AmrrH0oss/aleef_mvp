import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  Map<String, dynamic>? _pet;
  List<Map<String, dynamic>> _vaccinations = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get pet data from navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _pet = args;
      _loadPetDetails();
    }
  }

  Future<void> _loadPetDetails() async {
    if (_pet == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final petId = _pet!['pet_id'];

      // Load vaccinations (medical info)
      final vaccinationsResponse = await Supabase.instance.client
          .from('Medicalinfo')
          .select('*')
          .eq('pet_id', petId)
          .order('vaccination_date', ascending: false);

      if (mounted) {
        setState(() {
          _vaccinations = List<Map<String, dynamic>>.from(vaccinationsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [PET-PROFILE] Error loading pet details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'Unknown';

    try {
      final birthDate = DateTime.parse(dateOfBirth.toString());
      final now = DateTime.now();
      final difference = now.difference(birthDate);

      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();

      if (years > 0) {
        return years == 1 ? '1 year' : '$years years';
      } else if (months > 0) {
        return months == 1 ? '1 month' : '$months months';
      } else {
        final days = difference.inDays;
        return days == 1 ? '1 day' : '$days days';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';

    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getVaccinationFrequency(String vaccinationType) {
    // Common vaccination frequencies
    final frequencies = {
      'rabies': 'Yearly',
      'distemper': 'Yearly',
      'parvovirus': 'Yearly',
      'antiflea': 'Monthly',
      'felocell': 'Yearly',
    };

    final type = vaccinationType.toLowerCase();
    for (var key in frequencies.keys) {
      if (type.contains(key)) {
        return frequencies[key]!;
      }
    }
    return 'Yearly';
  }

  @override
  Widget build(BuildContext context) {
    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pet Profile'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Pet data not found')),
      );
    }

    final petName = _pet!['name'] ?? 'Unknown';
    final petBreed = _pet!['breed'] ?? 'Unknown';
    final petGender = _pet!['gender'] ?? 'Unknown';
    final petWeight = _pet!['weight'];
    final petBirthDate = _pet!['date_of_birth'];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Pet Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        children: [
                          // Pet Avatar
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withOpacity(0.8),
                                  AppColors.primary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pets,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Pet Name
                          Text(
                            petName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pet Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.pets_outlined,
                                  'Breed',
                                  petBreed,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoItem(
                                  petGender.toLowerCase() == 'male'
                                      ? Icons.male
                                      : Icons.female,
                                  'Gender',
                                  petGender,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.cake_outlined,
                                  'Age',
                                  _calculateAge(petBirthDate),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.monitor_weight_outlined,
                                  'Weight',
                                  petWeight != null ? '${petWeight} Kg' : 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Vaccinations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(DateTime.now().toString()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to all vaccinations
                              },
                              child: const Text(
                                'See All',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Vaccinations List
                        if (_vaccinations.isEmpty)
                          _buildNoVaccinationsCard()
                        else
                          Column(
                            children: _vaccinations.map((vaccination) {
                              return _buildVaccinationCard(vaccination);
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.grey.shade600, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoVaccinationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.vaccines_outlined, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            'No vaccination records',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep track of your pet\'s vaccinations',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationCard(Map<String, dynamic> vaccination) {
    final vaccinationType = vaccination['vaccination_type'] ?? 'Unknown';
    final vaccinationDate = vaccination['vaccination_date'];
    final frequency = _getVaccinationFrequency(vaccinationType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccinationType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(vaccinationDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: frequency.toLowerCase() == 'monthly'
                  ? Colors.orange.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              frequency,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: frequency.toLowerCase() == 'monthly'
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
