import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      Navigator.of(context).pushReplacementNamed('/clinics');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final logoSize = isWide ? 220.0 : 160.0;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 560 : constraints.maxWidth * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(logoSize: logoSize),
                  SizedBox(height: media.size.height * 0.04),
                  Text(
                    'Everything your pet need-in one app',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final double logoSize;
  const _Logo({required this.logoSize});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/logo.png',
      width: logoSize,
      height: logoSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return SvgPicture.asset(
          'lib/assets/logo.svg',
          width: logoSize,
          height: logoSize,
        );
      },
    );
  }
}
