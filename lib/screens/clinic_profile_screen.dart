import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../widgets/custom_button.dart';
import '../theme/app_theme.dart';
import '../services/clinic_profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  Map<String, dynamic>? clinicData;
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> doctors = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clinic = ModalRoute.of(context)?.settings.arguments as Clinic?;
      if (clinic != null) {
        _loadClinicProfile(clinic.clinicId);
      }
    });
  }

  Future<void> _loadClinicProfile(String clinicId) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final profileData = await ClinicProfileService.fetchCompleteClinicProfile(
        clinicId,
      );

      setState(() {
        clinicData = profileData['clinic'];
        services = List<Map<String, dynamic>>.from(
          profileData['services'] ?? [],
        );
        doctors = List<Map<String, dynamic>>.from(profileData['doctors'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the clinic data passed through route arguments
    final clinic = ModalRoute.of(context)?.settings.arguments as Clinic?;

    if (clinic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Clinic Profile')),
        body: const Center(child: Text('No clinic data found')),
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(clinic.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(clinic.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading clinic profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadClinicProfile(clinic.clinicId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero Image
                  clinic.imageUrl != null
                      ? Image.network(
                          clinic.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(context),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildLoadingPlaceholder(context);
                          },
                        )
                      : _buildPlaceholderImage(context),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Clinic info overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clinicData?['name'] ?? clinic.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Veterinary clinic',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoPillsOverlay(context, clinic),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Services Section
                  _buildServicesSection(context, clinic),

                  const SizedBox(height: 32),

                  // Doctors Section
                  _buildDoctorsSection(context),

                  const SizedBox(height: 32),

                  // Opening Hours Section
                  _buildOpeningHoursSection(context),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom buttons
      bottomNavigationBar: _buildBottomButtons(context, clinic),
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.local_hospital_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildInfoPillsOverlay(BuildContext context, Clinic clinic) {
    return Row(
      children: [
        // Location pill
        _buildOverlayPill(
          Icons.location_on,
          clinicData?['location'] ?? '${clinic.district}, ${clinic.city}',
          Colors.blue,
        ),
        const SizedBox(width: 8),
        // Hours pill
        if (clinicData?['current_status'] != null) ...[
          _buildOverlayPill(
            Icons.access_time,
            clinicData!['current_status'] == 'open' ? 'Open Now' : 'Closed',
            clinicData!['current_status'] == 'open' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
        ],
        // Rating pill
        if (clinicData?['avg_rating'] != null) ...[
          _buildOverlayPill(
            Icons.star,
            '${clinicData!['avg_rating']}',
            Colors.amber,
          ),
        ],
      ],
    );
  }

  Widget _buildOverlayPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context, Clinic clinic) {
    // Use real services data from API, fallback to default if empty
    final servicesList = services.isNotEmpty
        ? services
        : [
            {
              'name': 'Examination',
              'price':
                  clinicData?['examination_price'] ??
                  clinic.examinationPrice ??
                  300,
            },
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Our services',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: servicesList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = servicesList[index];
              return _buildServiceCard(context, service);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            service['name'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${service['price']} EGP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection(BuildContext context) {
    // Use real doctors data from API, fallback to empty if no doctors
    final doctorsList = doctors.isNotEmpty ? doctors : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Drs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (doctorsList.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No doctors available',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This clinic hasn\'t added doctor profiles yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: doctorsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doctor = doctorsList[index];
              return _buildDoctorCard(context, doctor);
            },
          ),
      ],
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    final isAvailable = doctor['availability_status'] == 'available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Doctor Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: doctor['profile_image'] != null
                  ? Image.network(
                      doctor['profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDoctorPlaceholder(context),
                    )
                  : _buildDoctorPlaceholder(context),
            ),
          ),
          const SizedBox(width: 16),
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor['name'] ?? 'Dr. Unknown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor['experience'] ??
                      doctor['specialization'] ??
                      'General Veterinarian',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      doctor['available_hours'] ?? 'Hours not specified',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpeningHoursSection(BuildContext context) {
    final openingHours = clinicData?['opening_hours'];

    if (openingHours == null) {
      return const SizedBox.shrink();
    }

    // Days of the week in order
    final daysOfWeek = [
      {'key': 'monday', 'name': 'Monday'},
      {'key': 'tuesday', 'name': 'Tuesday'},
      {'key': 'wednesday', 'name': 'Wednesday'},
      {'key': 'thursday', 'name': 'Thursday'},
      {'key': 'friday', 'name': 'Friday'},
      {'key': 'saturday', 'name': 'Saturday'},
      {'key': 'sunday', 'name': 'Sunday'},
    ];

    // Get current day for highlighting
    final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    final todayKey = daysOfWeek[today - 1]['key'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Hours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: daysOfWeek.map((day) {
              final dayKey = day['key']!;
              final dayName = day['name']!;
              final dayHours = openingHours[dayKey];
              final isToday = dayKey == todayKey;

              String hoursText = 'Closed';
              Color statusColor = Colors.red;

              if (dayHours != null &&
                  dayHours['open'] != null &&
                  dayHours['close'] != null &&
                  dayHours['open'] != 'closed') {
                hoursText = '${dayHours['open']} - ${dayHours['close']}';
                statusColor = Colors.green;
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isToday) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          dayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isToday
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      hoursText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorPlaceholder(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, Clinic clinic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Call Button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: () => _makePhoneCall(context),
              icon: Icon(Icons.phone, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Book Appointment Button
          Expanded(
            child: CustomButton(
              text: 'Book an appointment',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/bookAppointment',
                  arguments: clinic,
                );
              },
              backgroundColor: AppColors.primary,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    final phoneNumber = clinicData?['phone'];

    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw Exception('Could not launch phone app');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not make phone call: $e')));
    }
  }

  double _parseDistance(String location) {
    final locationText = location.toLowerCase();
    final kmIndex = locationText.indexOf('km');
    if (kmIndex != -1) {
      final beforeKm = locationText.substring(0, kmIndex).trim();
      final parts = beforeKm.split(' ');
      if (parts.isNotEmpty) {
        final distanceStr = parts.last;
        return double.tryParse(distanceStr) ?? 0.0;
      }
    }
    return 0.0;
  }
}
