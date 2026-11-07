import 'package:flutter/material.dart';

import '../services/app_i18n.dart';
import '../widgets/responsive_layout.dart';
import '../models/admin_models.dart';
import '../services/admin_services.dart';
import '../utils/admin_logic.dart';
import '../widgets/admin_widgets.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _userService = AdminUserService();
  final _search = TextEditingController();
  List<UserModel> userList = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final list = await _userService.loadUserList();
      if (!mounted) return;
      setState(() {
        userList = list;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Could not load users. Check Firebase rules.';
      });
    }
  }

  List<UserModel> filteredList() {
    return filterUsersByName(userList, _search.text);
  }

  Future<void> blockUser(UserModel user) async {
    final willBlock = !user.isBlocked;
    final ok = await ConfirmDialog.show(
      context,
      message: willBlock
          ? 'Block ${user.name}?'
          : 'Unblock ${user.name}?',
    );
    if (!ok) return;
    try {
      await _userService.setBlocked(uid: user.uid, blocked: willBlock);
      await loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willBlock
                ? AppI18n.t(
                    context,
                    en: AdminMessages.userBlocked,
                    ar: 'تم حظر المستخدم.',
                  )
                : AppI18n.t(
                    context,
                    en: AdminMessages.userUnblocked,
                    ar: 'تم إلغاء الحظر.',
                  ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppI18n.t(context, en: 'Could not update this user.', ar: 'تعذر تحديث هذا المستخدم.'),
          ),
        ),
      );
    }
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

    final visible = filteredList();
    return ResponsiveContent(
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: AppI18n.t(context, en: 'Search by name', ar: 'ابحث بالاسم'),
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    AppI18n.t(context, en: 'Nothing here yet', ar: 'لا يوجد شيء هنا بعد'),
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final user = visible[index];
                    return _UserTile(
                      user: user,
                      onBlockTap: () => blockUser(user),
                    );
                  },
                ),
        ),
      ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onBlockTap});

  final UserModel user;
  final VoidCallback onBlockTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = user.isBlocked ? Colors.red : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: const TextStyle(color: Colors.grey)),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(user.phone, style: const TextStyle(color: Colors.grey)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    user.isBlocked
                        ? AppI18n.t(context, en: 'Blocked', ar: 'محظور')
                        : AppI18n.t(context, en: 'Active', ar: 'نشط'),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (!user.isAdmin)
              TextButton(
                onPressed: onBlockTap,
                child: Text(
                  user.isBlocked
                      ? AppI18n.t(context, en: 'Unblock', ar: 'إلغاء الحظر')
                      : AppI18n.t(context, en: 'Block', ar: 'حظر'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
