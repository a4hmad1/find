import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    ReportModel report,
  ) async {
    try {
      await ref.read(adminRepositoryProvider).resolveReport(report.id);
      ref
        ..invalidate(adminReportsProvider)
        ..invalidate(adminStatsProvider);
      if (!context.mounted) return;
      showMessageSnackBar(context, 'ڕاپۆرتەکە چارەسەرکرا');
    } on AppFailure catch (failure) {
      if (!context.mounted) return;
      showFailureSnackBar(context, failure);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);

    return AppScaffold(
      title: Ku.adminReports,
      onRefresh: () async {
        ref.invalidate(adminReportsProvider);
        try {
          await ref.read(adminReportsProvider.future);
        } on Object {
          // Rendered as an error state below.
        }
      },
      child: reports.when(
        loading: () => const LoadingSkeleton(count: 5),
        error: (error, _) => ErrorView.failure(
          AppFailure.from(error),
          onRetry: () => ref.invalidate(adminReportsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'هیچ ڕاپۆرتێک نییە',
              message: 'ڕاپۆرتە نوێیەکان لێرە دەردەکەون.',
              icon: Icons.flag_outlined,
            );
          }
          return Column(
            children: [
              for (final report in items)
                Card(
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(
                      report.reason,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(report.description ?? 'وردەکاری نییە'),
                        const SizedBox(height: 4),
                        Text(
                          DateFormatters.dateTime(report.createdAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (report.isOpen)
                          OutlinedButton(
                            onPressed: () => _resolve(context, ref, report),
                            child: const Text('چارەسەرکرا'),
                          )
                        else
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                        // A report is only actionable next to the post it is
                        // about; the previous screen showed neither a link nor
                        // any way to see what had been reported.
                        if (report.postId case final postId?)
                          TextButton(
                            onPressed: () =>
                                context.push('${AppRoutes.post}/$postId'),
                            child: const Text(Ku.details),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
