import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import './screens/admin_home_screen.dart';
import './firebase_options.dart';
import './services/app_i18n.dart';
import './services/app_settings_controller.dart';
import './screens/auth_session_router.dart';
import './screens/login_screen.dart';
import './theme/app_theme.dart';
import './services/bill_reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppSettingsController.instance.load();
  } catch (_) {}
  try {
    await BillReminderService.instance.init();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettingsController.instance,
      builder: (context, _) {
        final settings = AppSettingsController.instance;
        final dark = settings.themeMode == ThemeMode.dark;
        SystemChrome.setSystemUIOverlayStyle(
          (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hostel Student Wallet',
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localeResolutionCallback: (_, _) => settings.locale,
          builder: (context, child) {
            return Directionality(
              textDirection:
                  settings.isArabic ? TextDirection.rtl : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routes: {
            '/login': (_) => const LoginScreen(),
            '/admin': (_) => const AdminHomeScreen(),
          },
          home: const _FirebaseBootstrap(),
        );
      },
    );
  }
}

class _FirebaseBootstrap extends StatefulWidget {
  const _FirebaseBootstrap();

  @override
  State<_FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<_FirebaseBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _bootstrapFirebase();
  }

  Future<void> _bootstrapFirebase() async {
    final binding = WidgetsBinding.instance;
    await binding.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 16));
    await _initializeFirebase().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        AppI18n.ts(
          en: 'Firebase did not finish starting in time. '
              'Try: unplug/replug USB, revoke USB debugging authorizations on the phone, '
              'disable VPN, or run `flutter clean` then run again.',
          ar: 'لم يكتمل تشغيل Firebase في الوقت المحدد. '
              'جرّب: فصل/إعادة توصيل USB، إلغاء تفويض تصحيح USB على الهاتف، '
              'تعطيل VPN، أو تشغيل flutter clean ثم إعادة التشغيل.',
        ),
        const Duration(seconds: 30),
      ),
    );
  }

  static bool _isDuplicateDefaultAppError(Object error) {
    if (error is FirebaseException && error.code == 'duplicate-app') {
      return true;
    }
    final s = error.toString();
    return s.contains('duplicate-app') || s.contains('[core/duplicate-app]');
  }

  Future<void> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) return;
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } on FirebaseException catch (e) {
          if (_isDuplicateDefaultAppError(e)) return;
          rethrow;
        } on PlatformException catch (e) {
          if (_isDuplicateDefaultAppError(e)) return;
          if (e.code == 'channel-error') {
            await Future<void>.delayed(const Duration(milliseconds: 250));
            try {
              await Firebase.initializeApp();
            } on FirebaseException catch (e2) {
              if (_isDuplicateDefaultAppError(e2)) return;
              rethrow;
            } on PlatformException catch (e2) {
              if (_isDuplicateDefaultAppError(e2)) return;
              rethrow;
            }
          } else {
            rethrow;
          }
        }
        return;
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Starting Hostel Student Wallet…',
                        ar: 'جارٍ تشغيل محفظة الطالب السكني...',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Please wait while services connect.',
                        ar: 'يرجى الانتظار ريثما تتصل الخدمات.',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: scheme.error),
                    const SizedBox(height: 12),
                    Text(
                      AppI18n.t(
                        context,
                        en: 'Firebase initialization failed',
                        ar: 'فشل تهيئة Firebase',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initFuture = _initializeFirebase();
                        });
                      },
                      child: Text(
                        AppI18n.t(context, en: 'Retry', ar: 'إعادة المحاولة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const AuthSessionRouter();
      },
    );
  }
}
