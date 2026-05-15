import 'package:flutter/material.dart';

import '../../app/localization.dart';

Future<DateTime?> showKurdishDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  final first = firstDate ?? DateTime(2020);
  final last = lastDate ?? DateTime.now();
  var year = initialDate.year.clamp(first.year, last.year).toInt();
  var month = initialDate.month;
  var day = initialDate.day;

  int maxDayFor(int y, int m) => DateTime(y, m + 1, 0).day;

  return showDialog<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        day = day.clamp(1, maxDayFor(year, month)).toInt();
        return AlertDialog(
          title: const Text('ڕێکەوت دیاری بکە'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: year,
                decoration: const InputDecoration(labelText: 'ساڵ'),
                items: [
                  for (var item = last.year; item >= first.year; item--)
                    DropdownMenuItem(value: item, child: Text('$item')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => year = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: month,
                decoration: const InputDecoration(labelText: 'مانگ'),
                items: [
                  for (var item = 1; item <= 12; item++)
                    DropdownMenuItem(value: item, child: Text('$item')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => month = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: day,
                decoration: const InputDecoration(labelText: 'ڕۆژ'),
                items: [
                  for (var item = 1; item <= maxDayFor(year, month); item++)
                    DropdownMenuItem(value: item, child: Text('$item')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => day = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(Ku.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final picked = DateTime(year, month, day);
                if (picked.isBefore(first) || picked.isAfter(last)) {
                  return;
                }
                Navigator.of(context).pop(picked);
              },
              child: const Text(Ku.confirm),
            ),
          ],
        );
      },
    ),
  );
}
