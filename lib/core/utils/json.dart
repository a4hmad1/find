/// Tolerant accessors for decoding PostgREST rows.
///
/// Supabase returns `Map<String, dynamic>` with values whose runtime types
/// depend on the column type and on whether the row came from a REST response
/// or a realtime payload (realtime delivers numbers as strings). Every model
/// previously repeated `json['x']?.toString() ?? ''` by hand; these extensions
/// centralise that so a decoding rule is fixed in one place.
extension JsonMap on Map<String, dynamic> {
  /// Reads [key] as a string, falling back to [ifAbsent] when missing or null.
  String asString(String key, {String ifAbsent = ''}) {
    final value = this[key];
    return value == null ? ifAbsent : value.toString();
  }

  /// Reads [key] as a string, preserving null and collapsing blanks to null.
  String? asStringOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// Reads [key] as an int, accepting numeric strings.
  int asInt(String key, {int ifAbsent = 0}) {
    final value = this[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? ifAbsent;
    return ifAbsent;
  }

  /// Reads [key] as a double, accepting numeric strings.
  double? asDoubleOrNull(String key) {
    final value = this[key];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Reads [key] as a bool.
  ///
  /// Postgres booleans arrive as `true`/`false`, but realtime payloads can
  /// deliver `'t'`/`'f'` or `'true'`/`'false'`. [ifAbsent] decides the value
  /// for a missing key, which matters for columns like `needs_verification`
  /// that default to true server-side.
  bool asBool(String key, {bool ifAbsent = false}) {
    final value = this[key];
    if (value == null) return ifAbsent;
    if (value is bool) return value;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == 't' || text == '1';
  }

  /// Reads [key] as a [DateTime], returning null for absent or unparseable
  /// values.
  DateTime? asDateOrNull(String key) {
    final value = this[key];
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Decodes an embedded PostgREST relation into a list of models.
  ///
  /// Returns an empty list when the relation was not selected, so callers can
  /// use the same model for queries with and without the join.
  List<T> asModelList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final value = this[key];
    if (value is! List) return <T>[];
    return value.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}

extension PostgresDate on DateTime {
  /// Formats as a bare `yyyy-MM-dd` for Postgres `date` columns.
  ///
  /// Uses the local calendar date deliberately: a `date` column records the day
  /// the event happened where the user is, not the UTC day.
  String toDateOnlyString() {
    final local = toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Formats as an ISO-8601 UTC instant for `timestamptz` columns.
  ///
  /// Every write goes through this so timestamps are never mixed local/UTC, as
  /// they were when some updates called `toIso8601String()` directly.
  String toUtcIso() => toUtc().toIso8601String();

  /// Midnight of this instant's local day, expressed as UTC — the lower bound
  /// for "posts created today" style queries.
  DateTime get startOfLocalDay {
    final local = toLocal();
    return DateTime(local.year, local.month, local.day).toUtc();
  }

  bool isSameLocalDay(DateTime other) {
    final a = toLocal();
    final b = other.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
