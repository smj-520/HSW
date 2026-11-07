import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/admin_services.dart';
import '../services/user_profile_repository.dart';
import '../services/app_i18n.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/responsive_layout.dart';


class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final _message = TextEditingController();
  int rating = 5;
  bool isLoading = false;
  String errorMessage = '';

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }


  Future<void> sendFeedback() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => errorMessage = 'Please write a message');
      return;
    }
    if (Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null) {
      setState(() => errorMessage = 'You must be signed in');
      return;
    }
    final user = FirebaseAuth.instance.currentUser!;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      String userName = user.displayName?.trim() ?? '';
      final profile = await UserProfileRepository().getUserProfile(user.uid);
      final fromProfile = (profile?['displayName'] as String?)?.trim();
      if (fromProfile != null && fromProfile.isNotEmpty) {
        userName = fromProfile;
      }
      if (userName.isEmpty) userName = user.email ?? 'User';

      await FeedbackService().addFeedback(
        uid: user.uid,
        userName: userName,
        message: text,
        rating: rating,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(AppI18n.t(context, en: 'Feedback sent', ar: 'تم إرسال الملاحظة'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not send. Check Firebase rules.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(AppI18n.t(context, en: 'Send feedback', ar: 'إرسال ملاحظة')),
      ),
      body: ResponsiveContent(
      child: ListView(
        padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
        children: [
          Text(AppI18n.t(context, en: 'Rating', ar: 'التقييم')),
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: isLoading ? null : () => setState(() => rating = star),
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            enabled: !isLoading,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: AppI18n.t(context, en: 'Message', ar: 'الرسالة'),
              hintText: AppI18n.t(context, en: 'Tell us what you think', ar: 'أخبرنا برأيك'),
            ),
          ),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          PrimaryActionButton(
            label: AppI18n.t(context, en: 'Send', ar: 'إرسال'),
            isLoading: isLoading,
            onPressed: isLoading ? null : sendFeedback,
          ),
        ],
      ),
      ),
    );
  }
}
