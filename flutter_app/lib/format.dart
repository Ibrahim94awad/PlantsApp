import 'models.dart';

String formatQuantity(int value) {
  final digits = value.abs().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return value < 0 ? '-$formatted' : formatted;
}

String historyAction(String action) => switch (action) {
      'created' => 'Aangemaakt',
      'added' => 'Toegevoegd',
      'removed' => 'Verwijderd',
      'corrected' => 'Gecorrigeerd',
      'edited' => 'Bewerkt',
      'distributed' => 'Verdeeld',
      _ => action,
    };

int? defaultQuantityForSize(List<Choice> sizes, int? sizeId) {
  for (final size in sizes) {
    if (size.id == sizeId) {
      return size.defaultQuantity;
    }
  }
  return null;
}

String formatDateTime(int value) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year} ${two(date.hour)}:${two(date.minute)}';
}

DateTime dateOnly(int value) {
  final date = DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime(date.year, date.month, date.day);
}

String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (date == today) return 'Vandaag';
  if (date == today.subtract(const Duration(days: 1))) return 'Gisteren';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year}';
}

/// Resolves the sub-department that should be selected by default when the
/// available choices change: keeps a still-valid selection, otherwise falls
/// back to the first choice (or null when there are none).
int? resolveDefaultSubDepartment(int? current, List<Choice> choices) {
  if (current != null && choices.any((entry) => entry.id == current)) {
    return current;
  }
  return choices.isNotEmpty ? choices.first.id : null;
}
