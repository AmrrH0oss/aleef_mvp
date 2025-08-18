import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final TextInputAction textInputAction;
  final void Function(String value)? onSubmitted;
  final Widget? prefixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: IconTheme(
                  data: IconThemeData(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  child: prefixIcon!,
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      onFieldSubmitted: onSubmitted,
    );
  }
}
