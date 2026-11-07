import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../services/app_i18n.dart';
import '../utils/form_validators.dart';

class StyledCountryPhoneField extends StatelessWidget {
  const StyledCountryPhoneField({
    super.key,
    required this.phoneController,
    required this.selectedIsoCode,
    required this.onCountryChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.fixedCountryOnly = false,
    this.fixedCountryLabel = 'Oman',
    this.fixedDialCode = '+968',
  });

  final TextEditingController phoneController;
  final String selectedIsoCode;
  final ValueChanged<CountryCode> onCountryChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final bool fixedCountryOnly;
  final String fixedCountryLabel;
  final String fixedDialCode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (fixedCountryOnly) {
      return TextFormField(
        controller: phoneController,
        keyboardType: TextInputType.phone,
        textInputAction: textInputAction,
        autofillHints: const [AutofillHints.telephoneNumber],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: AppI18n.t(context, en: 'Phone Number', ar: 'رقم الهاتف'),
          hintText: AppI18n.t(
            context,
            en: 'National number',
            ar: 'الرقم الوطني',
          ),
          prefixIcon: Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🇴🇲',
                  style: TextStyle(
                    fontSize: 17,
                    color: scheme.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$fixedCountryLabel $fixedDialCode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            maxWidth: 200,
            minHeight: 48,
            maxHeight: 48,
          ),
        ),
        validator: validator,
      );
    }

    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      autofillHints: const [AutofillHints.telephoneNumber],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: AppI18n.t(context, en: 'Phone Number', ar: 'رقم الهاتف'),
        hintText: AppI18n.t(context, en: 'National number', ar: 'الرقم الوطني'),
        prefixIcon: CountryCodePicker(
          key: ValueKey<String>(selectedIsoCode),
          onChanged: onCountryChanged,
          initialSelection: selectedIsoCode,
          favorite: const [
            'OM',
            'AE',
            'SA',
            'EG',
            'JO',
            'KW',
            'QA',
            'BH',
            'US',
            'GB',
          ],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
          padding: EdgeInsets.zero,
          flagWidth: 26,
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
          dialogTextStyle: TextStyle(fontSize: 15, color: scheme.onSurface),
          dialogBackgroundColor: scheme.surfaceContainerHigh,
          dialogSize: Size(
            MediaQuery.sizeOf(context).width * 0.92,
            MediaQuery.sizeOf(context).height * 0.72,
          ),
          searchDecoration: InputDecoration(
            hintText: AppI18n.t(
              context,
              en: 'Search country',
              ar: 'ابحث عن الدولة',
            ),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 88,
          maxWidth: 120,
          minHeight: 48,
          maxHeight: 48,
        ),
      ),
      validator: validator,
    );
  }
}

String? tryParsePhoneE164(String nationalDigits, String isoAlpha2) {
  final iso = FormValidators.tryParseIso(isoAlpha2);
  if (iso == null) return null;
  final raw = nationalDigits.trim().replaceAll(RegExp(r'[\s-]'), '');
  if (raw.isEmpty) return null;
  try {
    final pn = PhoneNumber.parse(raw, callerCountry: iso);
    return pn.international;
  } catch (_) {
    return null;
  }
}
