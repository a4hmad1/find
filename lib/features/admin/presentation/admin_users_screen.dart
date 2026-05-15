import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  late Future<List<ProfileModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(adminRepositoryProvider).users();
  }

  Future<void> _ban(ProfileModel user, bool banned) async {
    await ref.read(adminRepositoryProvider).banUser(user.id, banned);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.adminUsers,
      child: FutureBuilder<List<ProfileModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 5);
          }
          if (snapshot.hasError) return const ErrorView(message: Ku.notAllowed);
          final users = snapshot.data ?? [];
          if (users.isEmpty) return const EmptyState();
          return Column(
            children: users.map((user) {
              return Card(
                child: ListTile(
                  leading: ProfileAvatar(profile: user),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '@${user.githubUsername}  ${_roleLabel(user.role)}',
                    textDirection: TextDirection.ltr,
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _ban(user, !user.isBanned),
                    child: Text(user.isBanned ? 'لابردنی ڕاگرتن' : 'ڕاگرتن'),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

String _roleLabel(String role) {
  return switch (role) {
    'admin' => 'بەڕێوەبەر',
    'moderator' => 'چاودێر',
    _ => 'بەکارهێنەر',
  };
}
