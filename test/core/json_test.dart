import 'package:find/core/utils/json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonMap', () {
    test('reads strings, treating null as the fallback', () {
      const json = <String, dynamic>{'a': 'x', 'b': null};
      expect(json.asString('a'), 'x');
      expect(json.asString('b'), '');
      expect(json.asString('missing', ifAbsent: '-'), '-');
    });

    test('collapses blank strings to null', () {
      const json = <String, dynamic>{'a': '', 'b': 'x'};
      expect(json.asStringOrNull('a'), isNull);
      expect(json.asStringOrNull('b'), 'x');
    });

    test('accepts numbers delivered as strings', () {
      // Realtime payloads deliver numeric columns as text, unlike REST reads.
      const json = <String, dynamic>{'i': '42', 'd': '1.5', 'bad': 'x'};
      expect(json.asInt('i'), 42);
      expect(json.asDoubleOrNull('d'), 1.5);
      expect(json.asInt('bad'), 0);
      expect(json.asDoubleOrNull('bad'), isNull);
    });

    test('accepts the several shapes a Postgres bool arrives in', () {
      expect(const <String, dynamic>{'v': true}.asBool('v'), isTrue);
      expect(const <String, dynamic>{'v': 't'}.asBool('v'), isTrue);
      expect(const <String, dynamic>{'v': 'true'}.asBool('v'), isTrue);
      expect(const <String, dynamic>{'v': '1'}.asBool('v'), isTrue);
      expect(const <String, dynamic>{'v': 'f'}.asBool('v'), isFalse);
      expect(const <String, dynamic>{'v': false}.asBool('v'), isFalse);
    });

    test('honours ifAbsent for missing bools', () {
      // `needs_verification` defaults to true server-side, so a missing key
      // must not silently read as false.
      expect(const <String, dynamic>{}.asBool('v', ifAbsent: true), isTrue);
      expect(const <String, dynamic>{}.asBool('v'), isFalse);
    });

    test('returns an empty list when a relation was not selected', () {
      const json = <String, dynamic>{};
      expect(json.asModelList('images', (_) => 1), isEmpty);
    });

    test('decodes an embedded relation', () {
      const json = <String, dynamic>{
        'images': [
          {'id': 'a'},
          {'id': 'b'},
        ],
      };
      expect(json.asModelList('images', (row) => row['id'] as String), [
        'a',
        'b',
      ]);
    });
  });

  group('PostgresDate', () {
    test('formats date-only columns with zero padding', () {
      expect(DateTime(2026, 3, 7).toDateOnlyString(), '2026-03-07');
      expect(DateTime(2026, 11, 21).toDateOnlyString(), '2026-11-21');
    });

    test('always writes timestamps as UTC', () {
      // Mixed local/UTC writes were the cause of off-by-hours ordering.
      final iso = DateTime.utc(2026, 5, 1, 9, 30).toUtcIso();
      expect(iso, startsWith('2026-05-01T09:30'));
      expect(iso, endsWith('Z'));
    });

    test('startOfLocalDay is midnight local, expressed as UTC', () {
      final start = DateTime(2026, 5, 1, 15, 45).startOfLocalDay;
      expect(start.isUtc, isTrue);
      final localMidnight = start.toLocal();
      expect(localMidnight.hour, 0);
      expect(localMidnight.minute, 0);
      expect(localMidnight.day, 1);
    });

    test('compares calendar days, not instants', () {
      final morning = DateTime(2026, 5, 1, 1);
      final evening = DateTime(2026, 5, 1, 23);
      expect(morning.isSameLocalDay(evening), isTrue);
      expect(morning.isSameLocalDay(DateTime(2026, 5, 2)), isFalse);
    });
  });
}
