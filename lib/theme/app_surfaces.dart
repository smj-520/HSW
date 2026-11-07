import 'package:flutter/material.dart';

abstract final class AppSurfaces {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color page(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  static Color card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return isDark(context) ? scheme.surfaceContainerHigh : Colors.white;
  }

  static Color ink(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color muted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  static Color border(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.outline.withValues(alpha: isDark(context) ? 0.5 : 0.9);
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark(context) ? 0.35 : 0.06),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];
  }
}
