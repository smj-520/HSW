import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';

// Admin page: read-only list of user feedback, newest first.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _feedbackService = FeedbackService();
  List<FeedbackModel> feedbackList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadFeedback();
  }

  // Downloads feedback from Firebase.
  Future<void> loadFeedback() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _feedbackService.loadFeedbackList();
      if (!mounted) return;
      setState(() {
        feedbackList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load feedback. Check Firebase rules.';
      });
    }
  }

  // Opens the detail page. Admin cannot change the message.
  void openDetail(FeedbackModel feedback) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FeedbackDetailScreen(feedback: feedback),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(errorMessage, textAlign: TextAlign.center),
        ),
      );
    }
    if (feedbackList.isEmpty) {
      return const Center(
        child: Text(
          'Nothing here yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ResponsiveContent(
      child: ListView.builder(
      padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width)),
      itemCount: feedbackList.length,
      itemBuilder: (context, index) {
        final item = feedbackList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            title: Text(
              item.userName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${item.message}\n${DateFormat('yyyy-MM-dd').format(item.createdAt.toLocal())}  •  ${item.rating}/5',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            isThreeLine: true,
            onTap: () => openDetail(item),
          ),
        );
      },
    ),
    );
  }
}

// Shows one feedback. Admin can only read. There is no edit or delete.
class FeedbackDetailScreen extends StatelessWidget {
  const FeedbackDetailScreen({super.key, required this.feedback});

  final FeedbackModel feedback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(AppI18n.t(context, en: 'Feedback', ar: 'الملاحظات')),
      ),
      body: ResponsiveContent(
      child: ListView(
        padding: EdgeInsets.all(responsivePagePaddingX(MediaQuery.sizeOf(context).width).clamp(16, 28)),
        children: [
          Text(
            feedback.userName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(feedback.createdAt.toLocal()),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppI18n.t(context, en: 'Rating', ar: 'التقييم')}: ${feedback.rating} / 5',
          ),
          const SizedBox(height: 16),
          Text(feedback.message, style: const TextStyle(fontSize: 16)),
        ],
      ),
      ),
    );
  }
}
