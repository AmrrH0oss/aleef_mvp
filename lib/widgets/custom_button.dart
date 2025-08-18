import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height ?? 48,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: backgroundColor ?? theme.colorScheme.primary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: _buildButtonContent(theme),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor ?? theme.colorScheme.primary,
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                elevation: 2,
                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              child: _buildButtonContent(theme),
            ),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              color:
                  textColor ??
                  (isOutlined ? theme.colorScheme.primary : Colors.white),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }
}
