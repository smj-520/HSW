import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextFormField with prefix icon, optional suffix, and soft error container.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onFieldSubmitted,
    this.autofillHints,
    this.focusNode,
    this.readOnly = false,
    this.suffixText,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final bool readOnly;
  final String? suffixText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          autofillHints: autofillHints,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixText: suffixText,
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                    size: 22,
                  )
                : null,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
