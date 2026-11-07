import 'package:flutter/material.dart';

abstract final class AppTransitions {
  static Route<T> fadeSlide<T extends Object?>(
    Widget page, {
    String? routeName,
    Duration transitionDuration = const Duration(milliseconds: 400),
    Duration reverseTransitionDuration = const Duration(milliseconds: 320),
    Offset slideBegin = const Offset(0, 0.035),
    Curve curve = Curves.easeOutCubic,
    Curve reverseCurve = Curves.easeInCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName ?? page.runtimeType.toString()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: reverseCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideBegin,
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Route<T> fadeSlideSheet<T extends Object?>(
    Widget page, {
    String? routeName,
  }) {
    return fadeSlide(
      page,
      routeName: routeName,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      slideBegin: const Offset(0, 0.024),
    );
  }

  static Route<T> fade<T extends Object?>(
    Widget page, {
    String? routeName,
    Duration transitionDuration = const Duration(milliseconds: 360),
    Duration reverseTransitionDuration = const Duration(milliseconds: 280),
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: routeName ?? page.runtimeType.toString()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: transitionDuration,
      reverseTransitionDuration: reverseTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: curve);
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}
