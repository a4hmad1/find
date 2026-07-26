import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/domain/notification_type.dart';
import '../../core/utils/date_formatters.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/profile_model.dart';
import 'app_scaffold.dart';

/// Circular avatar with a fallback for profiles that have no picture.
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
          ? Icon(Icons.person_rounded, color: AppColors.primary, size: radius)
          : null,
    );
  }
}

/// One row in the notifications list.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final AppNotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: unread ? AppColors.accentSoft : AppColors.primarySoft,
        child: Icon(
          _iconFor(notification.type),
          color: unread ? AppColors.accent : AppColors.primary,
        ),
      ),
      title: Text(
        notification.resolvedTitle,
        style: TextStyle(
          fontWeight: unread ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        notification.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        DateFormatters.date(notification.createdAt),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  static IconData _iconFor(NotificationType type) => switch (type) {
    NotificationType.newMessage => Icons.chat_rounded,
    NotificationType.postApproved => Icons.verified_rounded,
    NotificationType.postRejected => Icons.block_rounded,
    NotificationType.postReturned => Icons.assignment_turned_in_rounded,
    NotificationType.similarItem => Icons.travel_explore_rounded,
    NotificationType.adminNotice => Icons.campaign_rounded,
  };
}

/// A single chat message.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, required this.mine});

  final MessageModel message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = mine ? AppColors.primary : theme.colorScheme.surface;
    final foreground = mine ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          border: mine ? null : Border.all(color: context.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  height: 170,
                  width: 260,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 170,
                    width: 260,
                    child: Icon(Icons.image_not_supported_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (message.hasText)
              Text(
                message.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  height: 1.55,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatters.time(message.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: mine ? Colors.white70 : AppColors.muted,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Headline number with a label, used on both dashboards.
class StatCard extends StatelessWidget {
  const StatCard({
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.hairline),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
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

/// Navigation row used by the profile, settings, and admin menus.
class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    this.badgeCount = 0,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: icon == null
          ? null
          : CircleAvatar(
              backgroundColor: AppColors.primarySoft,
              child: Icon(icon, color: AppColors.primary),
            ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: const BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.all(Radius.circular(999)),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          const Icon(Icons.chevron_left_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}
