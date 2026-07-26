import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/localization.dart';
import '../../core/constants/app_constants.dart';
import '../../core/domain/post_status.dart';
import '../../core/utils/date_formatters.dart';
import '../models/post_model.dart';
import 'buttons.dart';

/// Coloured pill showing a post's moderation state.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PostStatus.approved => AppColors.success,
      PostStatus.returned => AppColors.primary,
      PostStatus.closed => AppColors.muted,
      PostStatus.rejected => AppColors.danger,
      PostStatus.pending => AppColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Rounded label used for categories and filters.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = AnimatedContainer(
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

    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: chip,
    );
  }
}

/// Renders a post image from either a network URL or an inline data URI.
///
/// Guest-mode posts hold their images as base64 data URIs, so both sources have
/// to be handled by the same widget.
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
    if (url.isEmpty) return _Fallback(icon: fallbackIcon);

    if (url.startsWith('data:image')) {
      final bytes = _decodeDataUri(url);
      if (bytes == null) return _Fallback(icon: fallbackIcon);
      return Image.memory(bytes, fit: fit, gaplessPlayback: true);
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, url) => const _Fallback(icon: Icons.image_rounded),
      errorWidget: (context, url, error) =>
          const _Fallback(icon: Icons.image_not_supported_rounded),
    );
  }

  static Uint8List? _decodeDataUri(String url) {
    final comma = url.indexOf(',');
    if (comma == -1) return null;
    try {
      return base64Decode(url.substring(comma + 1));
    } on FormatException {
      return null;
    }
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primarySoft,
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

/// A post summary in a list.
///
/// Lays out horizontally by default and stacks on narrow viewports. [compact]
/// forces the dense variant used in moderation lists, where the actions are
/// supplied by the surrounding screen instead.
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
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 380 && !compact;
            return Padding(
              padding: EdgeInsets.all(stacked ? 10 : 12),
              child: stacked
                  ? _StackedContent(
                      post: post,
                      onDetails: onDetails,
                      onContact: onContact,
                    )
                  : _RowContent(
                      post: post,
                      compact: compact,
                      onDetails: onDetails,
                      onContact: onContact,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.post,
    required this.compact,
    required this.onDetails,
    required this.onContact,
  });

  final PostModel post;
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
          child: _PostSummary(
            post: post,
            compact: compact,
            onDetails: onDetails,
            onContact: onContact,
          ),
        ),
      ],
    );
  }
}

class _StackedContent extends StatelessWidget {
  const _StackedContent({
    required this.post,
    required this.onDetails,
    required this.onContact,
  });

  final PostModel post;
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
        _PostSummary(
          post: post,
          compact: false,
          onDetails: onDetails,
          onContact: onContact,
          shortActionLabels: true,
        ),
      ],
    );
  }
}

class _PostSummary extends StatelessWidget {
  const _PostSummary({
    required this.post,
    required this.compact,
    required this.onDetails,
    required this.onContact,
    this.shortActionLabels = false,
  });

  final PostModel post;
  final bool compact;
  final VoidCallback? onDetails;
  final VoidCallback? onContact;
  final bool shortActionLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            _MetaItem(icon: Icons.category_rounded, text: post.postTypeLabel),
            _MetaItem(icon: Icons.place_rounded, text: post.city),
            _MetaItem(
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
          Row(
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
                  label: shortActionLabels ? 'پەیوەندی' : Ku.contactOwner,
                  icon: Icons.chat_rounded,
                  // A returned or closed post no longer accepts contact.
                  onPressed: post.isClosed ? null : onContact,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

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
