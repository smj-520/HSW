import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/motion_widgets.dart';

/// Placeholder UI for future AI chatbot integration (API / backend).
class AiChatbotScreen extends StatelessWidget {
  const AiChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppI18n.t(context, en: 'AI Chatbot', ar: 'محادثة الذكاء الاصطناعي'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedAppear(
                index: 0,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 68,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedAppear(
                index: 1,
                child: Text(
                  AppI18n.t(
                    context,
                    en: 'AI Chatbot',
                    ar: 'محادثة الذكاء الاصطناعي',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedAppear(
                index: 2,
                child: Text(
                  AppI18n.t(
                    context,
                    en: 'Chatbot UI is ready for backend/API integration.',
                    ar: 'واجهة الشات بوت جاهزة للربط مع الـ API.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
