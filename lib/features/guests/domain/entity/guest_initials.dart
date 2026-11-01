/// Up to two capital letters from the first words of [fullName], such as
/// `АС` for «Айжан Сарсенова».
String initialsOf(String fullName) {
  return fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((String word) => word.isNotEmpty)
      .take(2)
      .map((String word) => word.substring(0, 1).toUpperCase())
      .join();
}
