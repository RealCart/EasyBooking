extension StringExtensions on String {
  /// Up to two uppercase initials for an avatar: `Айжан Сарсенова` → `АС`.
  String get initials {
    final List<String> words = trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .take(2)
        .toList();
    return words
        .map((String word) => String.fromCharCode(word.runes.first))
        .join()
        .toUpperCase();
  }
}
