import 'package:find/core/domain/notification_type.dart';
import 'package:find/core/domain/post_status.dart';
import 'package:find/core/domain/post_type.dart';
import 'package:find/core/domain/sort_option.dart';
import 'package:find/core/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostType', () {
    test('round-trips through its wire value', () {
      for (final type in PostType.values) {
        expect(PostType.tryParse(type.wire), type);
      }
    });

    test('returns null for values it does not know', () {
      // A value added to the database ahead of a client release must decode to
      // null rather than throwing mid-list.
      expect(PostType.tryParse('abandoned'), isNull);
      expect(PostType.tryParse(null), isNull);
    });

    test('pairs lost with found so matches are the opposite kind', () {
      expect(PostType.lost.opposite, PostType.found);
      expect(PostType.found.opposite, PostType.lost);
      // Someone whose item was stolen is looking for found reports.
      expect(PostType.stolen.opposite, PostType.found);
    });
  });

  group('PostStatus', () {
    test('round-trips through its wire value', () {
      for (final status in PostStatus.values) {
        expect(PostStatus.tryParse(status.wire), status);
      }
    });

    test('treats returned and closed as terminal', () {
      expect(PostStatus.returned.isTerminal, isTrue);
      expect(PostStatus.closed.isTerminal, isTrue);
      expect(PostStatus.approved.isTerminal, isFalse);
      expect(PostStatus.pending.isTerminal, isFalse);
    });

    test('excludes unmoderated and rejected posts from public browsing', () {
      expect(PostStatus.publiclyVisible, contains(PostStatus.approved));
      expect(PostStatus.publiclyVisible, isNot(contains(PostStatus.pending)));
      expect(PostStatus.publiclyVisible, isNot(contains(PostStatus.rejected)));
    });
  });

  group('UserRole', () {
    test('falls back to the least privileged role for unknown values', () {
      // Failing open here would hand moderation tools to an ordinary user.
      expect(UserRole.parse('superuser'), UserRole.user);
      expect(UserRole.parse(null), UserRole.user);
      expect(UserRole.parse(''), UserRole.user);
    });

    test('grants moderation only to admin and moderator', () {
      expect(UserRole.admin.canModerate, isTrue);
      expect(UserRole.moderator.canModerate, isTrue);
      expect(UserRole.user.canModerate, isFalse);
    });
  });

  group('SortOption', () {
    test('parses both the enum name and the Kurdish label', () {
      expect(SortOption.tryParse('newest'), SortOption.newest);
      expect(SortOption.tryParse(SortOption.oldest.label), SortOption.oldest);
      expect(SortOption.tryParse('sideways'), isNull);
    });
  });

  group('NotificationType / ReportStatus', () {
    test('round-trip and fall back for unknown values', () {
      for (final type in NotificationType.values) {
        expect(NotificationType.parse(type.wire), type);
      }
      expect(NotificationType.parse('quantum'), NotificationType.adminNotice);

      for (final status in ReportStatus.values) {
        expect(ReportStatus.parse(status.wire), status);
      }
      expect(ReportStatus.parse('escalated'), ReportStatus.pending);
    });
  });
}
