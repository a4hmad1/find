/// Helpers for building PostgREST filter strings safely.
///
/// PostgREST's `or=` / `and=` syntax is a comma-separated, parenthesised
/// mini-language. Interpolating raw user input into it lets a crafted query
/// close the current condition and append arbitrary filters — for example a
/// search for `x,status.eq.pending` would widen the result set past the
/// approved-only restriction the caller intended.
///
/// The defence is PostgREST's own quoting: a value wrapped in double quotes is
/// read literally, with `\` and `"` escaped inside it. Everything that reaches
/// a filter string goes through [quote].
library;

/// Wraps [value] in PostgREST's double-quoted literal form.
///
/// Backslashes are escaped first so that the escaping of `"` is not itself
/// re-escaped.
String quote(String value) {
  final escaped = value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}

/// Escapes SQL `LIKE`/`ILIKE` wildcards so a user searching for a literal `%`
/// or `_` does not accidentally match every row.
///
/// Uses `\` as the escape character, which is Postgres' default for `LIKE`.
String escapeLikeWildcards(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Builds a quoted `ilike` pattern that matches [term] anywhere in a column.
///
/// The wildcards the caller wants (`%` on either side) are added after the
/// user's own wildcards have been neutralised.
String containsPattern(String term) => quote('%${escapeLikeWildcards(term)}%');

/// Joins [conditions] into the body of a PostgREST `or` filter.
String or(Iterable<String> conditions) => conditions.join(',');

/// Wraps [conditions] into a single parenthesised `and` group, for use as one
/// branch of an `or` filter.
String andGroup(Iterable<String> conditions) => 'and(${conditions.join(',')})';
