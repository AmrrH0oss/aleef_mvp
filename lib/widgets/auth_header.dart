import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logoPath;
  final String heroImagePath;

  const AuthHeader({
    super.key,
    this.title = 'Welcome to Aleef!',
    this.subtitle = 'You are one step away from your pets heaven',
    this.logoPath = 'lib/assets/logo.png',
    this.heroImagePath = 'lib/assets/dog_placeholder.png',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 520;
        final double logoHeight = isWide ? 60 : 48;
        final double circleSize = isWide ? 180 : 140;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Center(
              child: Image.asset(
                logoPath,
                height: logoHeight,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Container(
                  height: logoHeight,
                  alignment: Alignment.center,
                  child: Text(
                    'Aleef',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Circular hero image
            Center(
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F6DB3).withValues(alpha: 0.95),
                  image: DecorationImage(
                    image: AssetImage(heroImagePath),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle error silently - will show background color
                    },
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1F3A5B),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}
