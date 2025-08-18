import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final bool showValidationIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.showValidationIcon = false,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: IconTheme(
                  data: IconThemeData(
                    color: theme.colorScheme.primary.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  child: prefixIcon!,
                ),
              )
            : null,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        labelStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
        helperStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
