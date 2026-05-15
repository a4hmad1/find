import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/post_model.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  const PostDetailsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  Future<void> _contact(PostModel post) async {
    try {
      final ownerId = post.profile?.id ?? post.userId;
      final conversation = await ref
          .read(messagesRepositoryProvider)
          .createOrOpen(postId: post.id, otherUserId: ownerId);
      if (!mounted) return;
      context.push('${AppRoutes.messages}/${conversation.id}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(Ku.genericError)));
    }
  }

  Future<void> _save(PostModel post) async {
    await ref.read(profileRepositoryProvider).savePost(post.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('بابەتەکە پاشەکەوتکرا')));
  }

  Future<void> _share(PostModel post) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${post.title}\n${post.city}\n${DbValues.postTypeLabels[post.postType] ?? post.postType}',
      ),
    );
  }

  Future<void> _report(PostModel post) async {
    String reason = AppLists.reportReasons.first;
    final description = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ڕاپۆرتکردن'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                decoration: const InputDecoration(labelText: 'هۆکار'),
                items: AppLists.reportReasons
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => reason = value ?? reason),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'وردەکاری'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(Ku.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('ناردنی ڕاپۆرت'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await ref
          .read(postsRepositoryProvider)
          .reportPost(
            postId: post.id,
            reason: reason,
            description: description.text.trim().isEmpty
                ? null
                : description.text.trim(),
            reportedUserId: post.userId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ڕاپۆرتەکەت نێردرا')));
    }
  }

  Future<void> _launch(String value, String scheme) async {
    final uri = Uri.parse('$scheme:$value');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final canUseAccount = ref.watch(signedInProvider);
    final post = ref.watch(postDetailsProvider(widget.postId));
    return post.when(
      loading: () => const AppScaffold(
        title: 'وردەکاری بابەت',
        child: LoadingSkeleton(count: 4),
      ),
      error: (error, stackTrace) =>
          const AppScaffold(title: 'وردەکاری بابەت', child: ErrorView()),
      data: (post) {
        if (post == null) {
          return const AppScaffold(title: 'وردەکاری بابەت', child: ErrorView());
        }
        return AppScaffold(
          title: 'وردەکاری بابەت',
          actions: [
            if (canUseAccount)
              IconButton(
                tooltip: Ku.save,
                onPressed: () => _save(post),
                icon: const Icon(Icons.bookmark_add_rounded),
              ),
            IconButton(
              tooltip: Ku.share,
              onPressed: () => _share(post),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ImageCarousel(post: post),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  StatusBadge(status: post.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CategoryChip(label: post.postTypeLabel, selected: true),
                  CategoryChip(label: post.itemType),
                  CategoryChip(label: post.city),
                ],
              ),
              const SizedBox(height: 18),
              _DetailRow(
                icon: Icons.place_rounded,
                title: 'شوێن',
                value: post.locationText,
              ),
              _DetailRow(
                icon: Icons.map_rounded,
                title: 'ناوچە',
                value: post.area,
              ),
              _DetailRow(
                icon: Icons.calendar_month_rounded,
                title: 'ڕێکەوت',
                value: DateFormatters.date(post.eventDate),
              ),
              _DetailRow(
                icon: Icons.visibility_rounded,
                title: 'بینین',
                value: '${post.viewsCount}',
              ),
              const SizedBox(height: 16),
              Text(
                'وەسفکردن',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                post.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.8),
              ),
              const SizedBox(height: 18),
              _OwnerBlock(profile: post.profile),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'تکایە پێش وەرگرتنەوەی شت، زانیارییەکان بە وردی پشتڕاست بکەرەوە.',
                ),
              ),
              const SizedBox(height: 18),
              if (post.allowContactPublic) ...[
                if ((post.contactPhone ?? '').isNotEmpty)
                  SecondaryButton(
                    label: 'پەیوەندی بە ژمارە',
                    icon: Icons.call_rounded,
                    onPressed: () => _launch(post.contactPhone!, 'tel'),
                  ),
                if ((post.contactEmail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'ناردنی ئیمەیڵ',
                    icon: Icons.mail_rounded,
                    onPressed: () => _launch(post.contactEmail!, 'mailto'),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              PrimaryButton(
                label: Ku.sendMessage,
                icon: Icons.chat_rounded,
                onPressed: post.isClosed || !canUseAccount
                    ? null
                    : () => _contact(post),
              ),
              const SizedBox(height: 8),
              SecondaryButton(
                label: Ku.report,
                icon: Icons.flag_rounded,
                onPressed: canUseAccount ? () => _report(post) : null,
              ),
              if (!canUseAccount) ...[
                const SizedBox(height: 10),
                const Text(
                  'لە دۆخی میواندا تەنها زانیارییە گشتییەکان نیشان دەدرێت.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    if (post.images.isEmpty) {
      return Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Icon(
            Icons.inventory_2_rounded,
            size: 54,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: post.images.length,
        itemBuilder: (context, index) {
          final image = post.images[index];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: PostImageView(imageUrl: image.imageUrl, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Expanded(child: Text(value.isEmpty ? 'دیاری نەکراوە' : value)),
        ],
      ),
    );
  }
}

class _OwnerBlock extends StatelessWidget {
  const _OwnerBlock({required this.profile});

  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ProfileAvatar(profile: profile, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.displayName ?? 'بەکارهێنەر',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${profile?.githubUsername ?? 'github'}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}
