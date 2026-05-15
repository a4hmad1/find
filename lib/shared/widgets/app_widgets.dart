import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_formatters.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../models/profile_model.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding = const EdgeInsets.all(20),
    this.scrollable = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsets padding;
  final bool scrollable;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: content,
              )
            : content,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

class OfficialHeader extends StatelessWidget {
  const OfficialHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EAF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class KurdishSearchBar extends StatelessWidget {
  const KurdishSearchBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onFilter,
    this.hint = 'چی لەدەستت داوە یان چی دۆزیوتەوە؟',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilter;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onFilter == null
            ? null
            : IconButton(
                tooltip: Ku.filter,
                onPressed: onFilter,
                icon: const Icon(Icons.tune_rounded),
              ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DbValues.approved => AppColors.success,
      DbValues.returned => AppColors.primary,
      DbValues.closed => AppColors.muted,
      DbValues.rejected => AppColors.danger,
      _ => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        DbValues.statusLabels[status] ?? status,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.onContact,
    this.onDetails,
    this.compact = false,
  });

  final PostModel post;
  final VoidCallback? onContact;
  final VoidCallback? onDetails;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380 && !compact;
        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onDetails,
            child: Padding(
              padding: EdgeInsets.all(narrow ? 10 : 12),
              child: narrow
                  ? _NarrowPostCardContent(
                      post: post,
                      theme: theme,
                      onDetails: onDetails,
                      onContact: onContact,
                    )
                  : _HorizontalPostCardContent(
                      post: post,
                      theme: theme,
                      compact: compact,
                      onDetails: onDetails,
                      onContact: onContact,
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalPostCardContent extends StatelessWidget {
  const _HorizontalPostCardContent({
    required this.post,
    required this.theme,
    required this.compact,
    required this.onDetails,
    required this.onContact,
  });

  final PostModel post;
  final ThemeData theme;
  final bool compact;
  final VoidCallback? onDetails;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: compact ? 82 : 108,
            height: compact ? 82 : 126,
            child: PostImageView(imageUrl: post.coverUrl),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PostTextBlock(
            post: post,
            theme: theme,
            compact: compact,
            onDetails: onDetails,
            onContact: onContact,
          ),
        ),
      ],
    );
  }
}

class _NarrowPostCardContent extends StatelessWidget {
  const _NarrowPostCardContent({
    required this.post,
    required this.theme,
    required this.onDetails,
    required this.onContact,
  });

  final PostModel post;
  final ThemeData theme;
  final VoidCallback? onDetails;
  final VoidCallback? onContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PostImageView(imageUrl: post.coverUrl),
          ),
        ),
        const SizedBox(height: 12),
        _PostTextBlock(
          post: post,
          theme: theme,
          compact: false,
          onDetails: onDetails,
          onContact: onContact,
          shortActions: true,
        ),
      ],
    );
  }
}

class _PostTextBlock extends StatelessWidget {
  const _PostTextBlock({
    required this.post,
    required this.theme,
    required this.compact,
    required this.onDetails,
    required this.onContact,
    this.shortActions = false,
  });

  final PostModel post;
  final ThemeData theme;
  final bool compact;
  final VoidCallback? onDetails;
  final VoidCallback? onContact;
  final bool shortActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          maxLines: compact ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(status: post.status),
            _Meta(icon: Icons.category_rounded, text: post.postTypeLabel),
            _Meta(icon: Icons.place_rounded, text: post.city),
            _Meta(
              icon: Icons.calendar_month_rounded,
              text: DateFormatters.date(post.eventDate ?? post.createdAt),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.description,
          maxLines: compact ? 1 : 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.muted,
            height: 1.65,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 12),
          _PostActions(
            onDetails: onDetails,
            onContact: post.isClosed ? null : onContact,
            shortLabels: shortActions,
          ),
        ],
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.onDetails,
    required this.onContact,
    required this.shortLabels,
  });

  final VoidCallback? onDetails;
  final VoidCallback? onContact;
  final bool shortLabels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SecondaryButton(
            label: Ku.details,
            icon: Icons.info_rounded,
            onPressed: onDetails,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PrimaryButton(
            label: shortLabels ? 'پەیوەندی' : Ku.contactOwner,
            icon: Icons.chat_rounded,
            onPressed: onContact,
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 148),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostImageView extends StatelessWidget {
  const PostImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.inventory_2_rounded,
  });

  final String? imageUrl;
  final BoxFit fit;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl ?? '';
    if (url.isEmpty) return _fallback();
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma == -1) return _fallback();
      try {
        final bytes = base64Decode(url.substring(comma + 1));
        return Image.memory(bytes, fit: fit, gaplessPlayback: true);
      } catch (_) {
        return _fallback();
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => _fallback(icon: Icons.image_rounded),
      errorWidget: (context, url, error) =>
          _fallback(icon: Icons.image_not_supported_rounded),
    );
  }

  Widget _fallback({IconData? icon}) {
    return Container(
      color: AppColors.primarySoft,
      child: Icon(icon ?? fallbackIcon, color: AppColors.primary),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: loading ? null : onPressed,
      iconAlignment: IconAlignment.start,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon ?? Icons.check_rounded, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      iconAlignment: IconAlignment.start,
      icon: Icon(icon ?? Icons.arrow_back_rounded, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class GitHubLoginButton extends StatelessWidget {
  const GitHubLoginButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: Ku.githubLogin,
      icon: Icons.code_rounded,
      loading: loading,
      onPressed: onPressed,
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = Ku.noItems,
    this.message = 'کاتێک بابەتێک هەبێت لێرە دەردەکەوێت.',
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.muted),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message = Ku.genericError, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(
          title: message,
          message: 'تکایە دواتر هەوڵبدەرەوە.',
          icon: Icons.error_rounded,
        ),
        if (onRetry != null)
          PrimaryButton(
            label: Ku.retry,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
      ],
    );
  }
}

class GuestModeView extends StatelessWidget {
  const GuestModeView({
    super.key,
    this.title = 'دۆخی میوان',
    this.message = 'ئەم بەشە لە دۆخی میواندا بەردەست نییە.',
    this.icon = Icons.lock_outline_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyState(title: title, message: message, icon: icon),
        if (actionLabel != null && onAction != null)
          PrimaryButton(
            label: actionLabel!,
            icon: Icons.home_rounded,
            onPressed: onAction,
          ),
      ],
    );
  }
}

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF162235)
        : const Color(0xFFE8EEF5);
    final highlight = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF22304A)
        : const Color(0xFFF7FAFC);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: List.generate(
          count,
          (index) => Container(
            height: 126,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class ImagePickerGrid extends StatelessWidget {
  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onChanged,
  });

  final List<XFile> images;
  final ValueChanged<List<XFile>> onChanged;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    final next = [...images, ...picked].take(5).toList();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length < 5 ? images.length + 1 : images.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index == images.length && images.length < 5) {
          return InkWell(
            onTap: _pick,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7E3F1)),
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColors.primary,
              ),
            ),
          );
        }
        final file = images[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List>(
                future: file.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(color: AppColors.primarySoft);
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              ),
              Positioned(
                top: 6,
                left: 6,
                child: InkWell(
                  onTap: () {
                    final next = [...images]..removeAt(index);
                    onChanged(next);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CityDropdown extends StatelessWidget {
  const CityDropdown({super.key, required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'شار'),
      items: AppLists.cities
          .map((city) => DropdownMenuItem(value: city, child: Text(city)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class ItemTypeDropdown extends StatelessWidget {
  const ItemTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'جۆری شت'),
      items: AppLists.itemTypes
          .map((type) => DropdownMenuItem(value: type, child: Text(type)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class PostTypeSelector extends StatelessWidget {
  const PostTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppLists.postTypes.map((type) {
        final selected = value == type;
        return ChoiceChip(
          label: Text(DbValues.postTypeLabels[type] ?? type),
          selected: selected,
          onSelected: (_) => onChanged(type),
        );
      }).toList(),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.profile, this.radius = 24});

  final ProfileModel? profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatar = profile?.avatarUrl ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      backgroundImage: avatar.isEmpty
          ? null
          : CachedNetworkImageProvider(avatar),
      child: avatar.isEmpty
          ? const Icon(Icons.person_rounded, color: AppColors.primary)
          : null,
    );
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final AppNotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: notification.isRead
            ? AppColors.primarySoft
            : AppColors.accentSoft,
        child: Icon(
          notification.isRead
              ? Icons.notifications_none_rounded
              : Icons.notifications_active_rounded,
          color: notification.isRead ? AppColors.primary : AppColors.accent,
        ),
      ),
      title: Text(
        notification.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(notification.body),
      trailing: Text(DateFormatters.date(notification.createdAt)),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine});

  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final bg = mine ? AppColors.primary : Theme.of(context).colorScheme.surface;
    final fg = mine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  height: 170,
                  width: 260,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (message.message.isNotEmpty)
              Text(
                message.message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: fg, height: 1.55),
              ),
            const SizedBox(height: 4),
            Text(
              DateFormatters.time(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mine ? Colors.white70 : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.muted)),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(Ku.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(Ku.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.noInternet,
      child: Column(
        children: [
          const EmptyState(
            title: Ku.noInternet,
            message: 'تکایە پەیوەندی ئینتەرنێت پشتڕاست بکەرەوە.',
            icon: Icons.wifi_off_rounded,
          ),
          PrimaryButton(
            label: Ku.retry,
            icon: Icons.refresh_rounded,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
