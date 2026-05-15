import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization.dart';
import '../../../app/providers.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/widgets/app_widgets.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  late Future<List<ReportModel>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(adminRepositoryProvider).reports();
  }

  Future<void> _resolve(ReportModel report) async {
    await ref.read(adminRepositoryProvider).resolveReport(report.id);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: Ku.adminReports,
      child: FutureBuilder<List<ReportModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingSkeleton(count: 5);
          }
          if (snapshot.hasError) return const ErrorView(message: Ku.notAllowed);
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const EmptyState(
              title: 'هیچ ڕاپۆرتێک نییە',
              message: 'ڕاپۆرتە نوێیەکان لێرە دەردەکەون.',
              icon: Icons.flag_outlined,
            );
          }
          return Column(
            children: reports.map((report) {
              return Card(
                child: ListTile(
                  title: Text(
                    report.reason,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '${report.description ?? 'وردەکاری نییە'}\n${DateFormatters.date(report.createdAt)}',
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => _resolve(report),
                    child: const Text('چارەسەرکرا'),
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
