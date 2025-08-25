import 'package:flutter/material.dart';
import 'package:test_screen/core/supabase_client.dart';
import 'package:test_screen/screens/clinic_list_screen.dart';
import 'package:test_screen/screens/create_account_screen.dart';
import 'package:test_screen/screens/login_screen.dart';
import 'package:test_screen/screens/splash_screen.dart';
import 'package:test_screen/screens/clinic_profile_screen.dart';
import 'package:test_screen/screens/book_appointment_screen.dart';
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
        '/clinics': (_) => const ClinicListScreen(),
        '/clinicProfile': (_) => const ClinicProfileScreen(),
        '/bookAppointment': (_) => const BookAppointmentScreen(),
      },
    );
  }
}
