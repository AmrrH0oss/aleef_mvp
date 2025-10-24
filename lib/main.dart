import 'package:flutter/material.dart';
import 'package:test_screen/core/supabase_client.dart';
import 'package:test_screen/screens/clinic_list_screen.dart';
import 'package:test_screen/screens/clinics_page.dart';
import 'package:test_screen/screens/create_account_screen.dart';
import 'package:test_screen/screens/login_screen.dart';
import 'package:test_screen/screens/splash_screen.dart';
import 'package:test_screen/screens/clinic_profile_screen.dart';
import 'package:test_screen/screens/book_appointment_screen.dart';
import 'package:test_screen/screens/home_screen.dart';
import 'package:test_screen/screens/add_pet_screen.dart';
import 'package:test_screen/screens/view_all_appointments_screen.dart';
import 'package:test_screen/screens/appointment_details_screen.dart';
import 'package:test_screen/screens/reschedule_appointment_screen.dart';
import 'package:test_screen/screens/user_profile_screen.dart';
import 'package:test_screen/screens/pet_profile_screen.dart';
import 'package:test_screen/debug_clinics_test.dart';
import 'package:test_screen/test_database_access.dart';
import 'package:test_screen/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aleef Health',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/create-account': (_) => const CreateAccountScreen(),
        '/home': (_) => const HomeScreen(),
        '/clinics': (_) => const ClinicListScreen(),
        '/clinics-simple': (_) =>
            const ClinicsPage(), // Simple clinics page with ListTile
        '/clinicProfile': (_) => const ClinicProfileScreen(),
        '/bookAppointment': (_) => const BookAppointmentScreen(),
        '/addPet': (_) => const AddPetScreen(),
        '/appointments': (_) => const ViewAllAppointmentsScreen(),
        '/appointmentDetails': (_) => const AppointmentDetailsScreen(),
        '/rescheduleAppointment': (_) => const RescheduleAppointmentScreen(),
        '/profile': (_) => const UserProfileScreen(),
        '/petProfile': (_) => const PetProfileScreen(),
        '/debug-clinics': (_) => const DebugClinicsTest(), // Debug test screen
        '/test-db': (_) => const TestDatabaseAccess(), // Database access test
      },
    );
  }
}
