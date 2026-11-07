import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../services/user_profile_repository.dart';
import '../utils/admin_logic.dart';

class BlockedAccountGuard extends StatefulWidget {
  const BlockedAccountGuard({super.key, required this.child});

  final Widget child;

  @override
  State<BlockedAccountGuard> createState() => _BlockedAccountGuardState();
}

class _BlockedAccountGuardState extends State<BlockedAccountGuard> {
  StreamSubscription<bool>? _sub;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    if (Firebase.apps.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _sub = UserProfileRepository().watchBlocked(uid).listen((blocked) {
      if (!blocked || _leaving) return;
      _kickOut();
    });
  }

  Future<void> _kickOut() async {
    _leaving = true;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          AppI18n.t(
            context,
            en: AdminMessages.accountBlocked,
            ar: 'الحساب محظور',
          ),
        ),
      ),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
