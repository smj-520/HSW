import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import './admin_home_screen.dart';
import '../services/admin_services.dart';
import '../navigation/app_transitions.dart';
import '../services/user_profile_repository.dart';
import '../widgets/motion_widgets.dart';
import './login_screen.dart';
import './splash_screen.dart';
import './user_home_screen.dart';

class AuthSessionRouter extends StatefulWidget {
  const AuthSessionRouter({super.key});

  @override
  State<AuthSessionRouter> createState() => _AuthSessionRouterState();
}

class _AuthSessionRouterState extends State<AuthSessionRouter> {
  final _adminAuth = AdminAuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  // Picks splash, login, admin home, or user home.
  Future<void> _route() async {
    if (!mounted) return;

    if (Firebase.apps.isEmpty) {
      _replace(const SplashScreen());
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _replace(const SplashScreen());
      return;
    }

    try {
      final blocked = await UserProfileRepository().isBlocked(user.uid);
      if (blocked) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _replace(const LoginScreen());
        return;
      }
    } catch (_) {}

    String role = 'user';
    try {
      role = await _adminAuth.getRole(user.uid).timeout(const Duration(seconds: 12));
    } catch (_) {
      role = 'user';
    }
    if (!mounted) return;

    try {
      await UserProfileRepository().touchLastLogin(user.uid);
    } catch (_) {}

    if (!mounted) return;

    if (_adminAuth.isAdmin(role)) {
      _openAdminHome();
    } else {
      _openUserHome();
    }
  }

  void _openAdminHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
    );
  }

  void _openUserHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const UserHomeScreen()),
    );
  }

  void _replace(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      AppTransitions.fade(page, routeName: page.runtimeType.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: GentlePulse(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
