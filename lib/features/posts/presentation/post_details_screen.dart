import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
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
  bool _contacting = false;
  bool _saving = false;

  Future<void> _contact(PostModel post) async {
    setState(() => _contacting = true);
    try {
      final conversation = await ref
          .read(messagesRepositoryProvider)
          .createOrOpen(postId: post.id, otherUserId: post.ownerId);
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      // `push` completes when the thread is popped; nothing here awaits it.
      unawaited(context.push('${AppRoutes.messages}/${conversation.id}'));
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure, onRetry: () => _contact(post));
    } finally {
      if (mounted) setState(() => _contacting = false);
    }
  }

  Future<void> _save(PostModel post) async {
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).savePost(post.id);
      if (!mounted) return;
      ref.invalidate(savedPostsProvider);
      showMessageSnackBar(context, 'بابەتەکە پاشەکەوتکرا');
    } on AppFailure catch (failure) {
      // Previously this had no catch at all: a failed save threw into the void
      // and the user was told nothing.
      if (!mounted) return;
      showFailureSnackBar(context, failure, onRetry: () => _save(post));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share(PostModel post) async {
    await SharePlus.instance.share(
      ShareParams(text: '${post.title}\n${post.city}\n${post.postTypeLabel}'),
    );
  }

  Future<void> _report(PostModel post) async {
    final result = await showDialog<_ReportInput>(
      context: context,
      builder: (dialogContext) => const _ReportDialog(),
    );
    if (result == null || !mounted) return;

    try {
      await ref
          .read(postsRepositoryProvider)
          .reportPost(
            postId: post.id,
            reason: result.reason,
            description: result.description,
            reportedUserId: post.userId,
          );
      if (!mounted) return;
      showMessageSnackBar(context, 'ڕاپۆرتەکەت نێردرا');
    } on AppFailure catch (failure) {
      if (!mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  /// Opens an external app for a phone number or email address.
  ///
  /// The value is placed in the URI's path rather than concatenated into the
  /// string, so a stored value containing URI syntax cannot alter the target.
  Future<void> _launchContact(String value, String scheme) async {
    final uri = Uri(scheme: scheme, path: value.trim());
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched || !mounted) return;
    showMessageSnackBar(context, 'نەتوانرا بکرێتەوە');
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(signedInProvider);
    final post = ref.watch(postDetailsProvider(widget.postId));

    return post.when(
      loading: () => const AppScaffold(
        title: 'وردەکاری بابەت',
        child: LoadingSkeleton(count: 4),
      ),
      error: (error, _) => AppScaffold(
        title: 'وردەکاری بابەت',
        child: ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(postDetailsProvider(widget.postId)),
        ),
      ),
      data: (value) {
        if (value == null) {
          return const AppScaffold(
            title: 'وردەکاری بابەت',
            child: ErrorView(
              message: 'ئەم بابەتە نەدۆزرایەوە',
              detail: 'لەوانەیە سڕابێتەوە یان داخرابێت.',
              icon: Icons.search_off_rounded,
            ),
          );
        }
        return _PostDetails(
          post: value,
          signedIn: signedIn,
          contacting: _contacting,
          saving: _saving,
          onSave: () => _save(value),
          onShare: () => _share(value),
          onContact: () => _contact(value),
          onReport: () => _report(value),
          onLaunchPhone: () => _launchContact(value.contactPhone!, 'tel'),
          onLaunchEmail: () => _launchContact(value.contactEmail!, 'mailto'),
        );
      },
    );
  }
}

class _PostDetails extends StatelessWidget {
  const _PostDetails({
    required this.post,
    required this.signedIn,
    required this.contacting,
    required this.saving,
    required this.onSave,
    required this.onShare,
    required this.onContact,
    required this.onReport,
    required this.onLaunchPhone,
    required this.onLaunchEmail,
  });

  final PostModel post;
  final bool signedIn;
  final bool contacting;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onContact;
  final VoidCallback onReport;
  final VoidCallback onLaunchPhone;
  final VoidCallback onLaunchEmail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = (post.contactPhone ?? '').isNotEmpty;
    final hasEmail = (post.contactEmail ?? '').isNotEmpty;

    return AppScaffold(
      title: 'وردەکاری بابەت',
      actions: [
        if (signedIn)
          IconButton(
            tooltip: Ku.save,
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bookmark_add_rounded),
          ),
        IconButton(
          tooltip: Ku.share,
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ImageCarousel(post: post),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: post.status),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CategoryChip(label: post.postTypeLabel, selected: true),
              if (post.itemType.isNotEmpty) CategoryChip(label: post.itemType),
              if (post.city.isNotEmpty) CategoryChip(label: post.city),
            ],
          ),
          const SizedBox(height: 18),
          _DetailRow(
            icon: Icons.place_rounded,
            title: 'شوێن',
            value: post.locationText,
          ),
          _DetailRow(icon: Icons.map_rounded, title: 'ناوچە', value: post.area),
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
          ),
          const SizedBox(height: 18),
          _OwnerCard(profile: post.profile),
          const SizedBox(height: 16),
          const InfoBanner(
            message:
                'تکایە پێش وەرگرتنەوەی شت، زانیارییەکان بە وردی پشتڕاست بکەرەوە.',
          ),
          const SizedBox(height: 18),
          // Contact details are only published when the author opted in.
          if (post.allowContactPublic && (hasPhone || hasEmail)) ...[
            if (hasPhone)
              SecondaryButton(
                label: 'پەیوەندی بە ژمارە',
                icon: Icons.call_rounded,
                onPressed: onLaunchPhone,
              ),
            if (hasEmail) ...[
              const SizedBox(height: 8),
              SecondaryButton(
                label: 'ناردنی ئیمەیڵ',
                icon: Icons.mail_rounded,
                onPressed: onLaunchEmail,
              ),
            ],
            const SizedBox(height: 8),
          ],
          if (post.isClosed)
            const InfoBanner(
              message: Ku.closedPost,
              icon: Icons.lock_rounded,
              color: AppColors.muted,
              background: Color(0xFFEFF2F1),
            )
          else
            PrimaryButton(
              label: Ku.sendMessage,
              icon: Icons.chat_rounded,
              loading: contacting,
              onPressed: signedIn ? onContact : null,
            ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: Ku.report,
            icon: Icons.flag_rounded,
            onPressed: signedIn ? onReport : null,
          ),
          if (!signedIn) ...[
            const SizedBox(height: 16),
            // Guests previously saw disabled buttons with no explanation and no
            // route to signing in.
            const GuestModeView(
              title: 'دۆخی میوان',
              message: 'بۆ ناردنی نامە یان ڕاپۆرتکردن پێویستە بچیتە ژوورەوە.',
              icon: Icons.lock_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.post});

  final PostModel post;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  // Held in state and disposed: the previous version constructed a new
  // PageController inside build, leaking one per frame.
  late final PageController _controller = PageController(
    viewportFraction: 0.92,
  );
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.post.images;
    if (images.isEmpty) {
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

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: PostImageView(imageUrl: images[index].imageUrl),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < images.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.muted,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
        ],
      ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.profile});

  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.hairline),
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
                  profile?.resolvedDisplayName ?? 'بەکارهێنەر',
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

/// What the report dialog returns on submit.
class _ReportInput {
  const _ReportInput({required this.reason, this.description});

  final String reason;
  final String? description;
}

/// Report form.
///
/// Its own widget so the description controller is disposed. The previous
/// inline version created a `TextEditingController` inside an async method and
/// never disposed it, leaking one per report opened.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _description = TextEditingController();
  String _reason = AppLists.reportReasons.first;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ڕاپۆرتکردن'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledDropdown<String>(
              label: 'هۆکار',
              value: _reason,
              items: AppLists.reportReasons,
              labelOf: (item) => item,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'وردەکاری'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Ku.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _description.text.trim();
            Navigator.of(context).pop(
              _ReportInput(
                reason: _reason,
                description: text.isEmpty ? null : text,
              ),
            );
          },
          child: const Text('ناردنی ڕاپۆرت'),
        ),
      ],
    );
  }
}
