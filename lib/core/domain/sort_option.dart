/// Ordering applied to search results.
///
/// Previously this travelled through the app as a raw Kurdish string, which
/// meant a typo in a label silently changed query behaviour. The label is now
/// presentation-only and the enum drives sorting.
enum SortOption {
  newest('نوێترین'),
  oldest('کۆنترین'),
  nearest('نزیکترین'),
  mostUrgent('گرنگترین');

  const SortOption(this.label);

  final String label;

  static const fallback = SortOption.newest;

  static SortOption? tryParse(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    for (final option in values) {
      if (option.name == text || option.label == text) return option;
    }
    return null;
  }
}
