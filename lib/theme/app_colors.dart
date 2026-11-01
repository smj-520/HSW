import 'package:flutter/material.dart';

/// Brand palette aligned with Hostel Student Wallet reference (#28a745 + cream).
abstract final class AppColors {
  /// Primary action green from mockups.
  static const Color primary = Color(0xFF28A745);
  static const Color primaryDark = Color(0xFF1E7A34);
  static const Color primaryLight = Color(0xFF5CB85C);
  static const Color primaryContainer = Color(0xFFE6F4EA);

  /// App chrome (scaffold, bars) in light mode — mint wash.
  static const Color surface = Color(0xFFEDFFF0);

  /// Same as [surface]; kept for readable call sites in auth layout code.
  static const Color authScreenCream = surface;
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFDEE2E6);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9EBEA);
  static const Color success = Color(0xFF28A745);

  /// Splash wallet illustration.
  static const Color walletBody = Color(0xFF1B5E3A);
  static const Color billGreen = Color(0xFF2FA65C);
  static const Color coinGold = Color(0xFFE2B93C);
  static const Color coinGoldDeep = Color(0xFFC9A227);

  /// User home (finance overview) palette from product mock.
  static const Color homeBackground = Color(0xFFF5F5F3);
  static const Color homePrimary = Color(0xFF1F4D3D);
  static const Color homeAccent = Color(0xFF2E7D5B);
  static const Color homeExpense = Color(0xFFE74C3C);
  static const Color homeIncome = Color(0xFF27AE60);
  static const Color homeSaving = Color(0xFFD4A017);
  static const Color homeMuted = Color(0xFF8A8F8A);
  static const Color homeNavInactive = Color(0xFF9AA09A);
}
