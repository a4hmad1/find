import 'package:find/core/utils/postgrest_filter.dart' as filters;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quote', () {
    test('wraps plain values in double quotes', () {
      expect(filters.quote('erbil'), '"erbil"');
    });

    test('escapes embedded quotes so the literal cannot be closed early', () {
      expect(filters.quote('a"b'), r'"a\"b"');
    });

    test('escapes backslashes before quotes, not after', () {
      // If `"` were escaped first, the backslash it introduced would then be
      // doubled and the value would decode wrongly.
      expect(filters.quote(r'a\b'), r'"a\\b"');
      expect(filters.quote(r'a\"b'), r'"a\\\"b"');
    });
  });

  group('containsPattern', () {
    test('surrounds the term with wildcards', () {
      expect(filters.containsPattern('phone'), '"%phone%"');
    });

    test('neutralises user-supplied LIKE wildcards', () {
      // Two layers of escaping apply, in this order:
      //   1. LIKE escaping turns the user's `%` into `\%`, so it matches a
      //      literal percent sign instead of every row in the table;
      //   2. PostgREST quoting then doubles that backslash to `\\`, so the
      //      quoted literal decodes back to `\%` on the server.
      // The surrounding bare `%` are the wildcards we intend.
      expect(filters.containsPattern('%'), r'"%\\%%"');
      expect(filters.containsPattern('a_b'), r'"%a\\_b%"');
    });

    test('quotes a filter-injection attempt instead of honouring it', () {
      // This is the payload the old implementation was vulnerable to: only
      // commas were stripped, so `status.eq.pending` became a second filter and
      // widened the query past the approved-only restriction.
      const attack = 'x,status.eq.pending';
      final pattern = filters.containsPattern(attack);

      expect(pattern.startsWith('"'), isTrue);
      expect(pattern.endsWith('"'), isTrue);
      // The comma survives as data inside the quoted literal rather than
      // becoming a filter separator.
      expect(pattern, contains('x,status.eq.pending'));
    });
  });

  group('or / andGroup', () {
    test('joins conditions with commas', () {
      expect(filters.or(['a.eq."1"', 'b.eq."2"']), 'a.eq."1",b.eq."2"');
    });

    test('wraps a conjunction so it reads as one branch of an or', () {
      expect(
        filters.andGroup(['a.eq."1"', 'b.eq."2"']),
        'and(a.eq."1",b.eq."2")',
      );
    });
  });
}
