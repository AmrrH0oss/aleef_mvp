import 'package:flutter/material.dart';
import '../models/clinic.dart';
import '../theme/app_theme.dart';

class ClinicCard extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback? onTap;
  final bool isCompact;

  const ClinicCard({
    super.key,
    required this.clinic,
    this.onTap,
    this.isCompact = false,
  });

  // Helper method to parse distance from location string
  double get distance {
    // Try to extract distance from location string (e.g., "1.5 km" -> 1.5)
    final locationText = clinic.location.toLowerCase();
    final kmIndex = locationText.indexOf('km');
    if (kmIndex != -1) {
      final beforeKm = locationText.substring(0, kmIndex).trim();
      final parts = beforeKm.split(' ');
      if (parts.isNotEmpty) {
        final distanceStr = parts.last;
        return double.tryParse(distanceStr) ?? 0.0;
      }
    }
    return 0.0; // Default distance if can't parse
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: isCompact
              ? _buildCompactLayout(context)
              : _buildFullLayout(context),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildClinicImage(context, 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clinic.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinic.specialty ?? 'General Practice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _buildInfoPills(context),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildClinicImage(context, 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                clinic.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                clinic.specialty ?? 'General Practice',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _buildInfoPills(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClinicImage(BuildContext context, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: clinic.imageUrl != null
            ? Image.network(
                clinic.imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholderIcon(context, size),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingPlaceholder(context, size);
                },
              )
            : _buildPlaceholderIcon(context, size),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_hospital,
        color: Theme.of(context).colorScheme.primary,
        size: size * 0.4,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChevronIcon(BuildContext context, double size, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.chevron_right,
        size: iconSize,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // NEW: Updated info pills with horizontal layout for rating, distance, and price
  Widget _buildInfoPills(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: [
        if (clinic.rating != null)
          _buildInfoPill(
            Icons.star,
            "${clinic.rating!.toStringAsFixed(1)}",
            const Color(0xFFFFC107),
          ),
        if (distance > 0)
          _buildInfoPill(
            Icons.location_on,
            "${distance.toStringAsFixed(1)}km",
            const Color(0xFFE91E63),
          ),
        if (clinic.examinationPrice != null)
          _buildInfoPill(
            Icons.attach_money,
            "${clinic.examinationPrice!.toInt()}EGP",
            const Color(0xFF4CAF50),
          ),
      ],
    );
  }

  Widget _buildInfoPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
