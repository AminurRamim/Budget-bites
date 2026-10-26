/// Form validators shared by the meal form, purchase flow, and edit dialog.
/// Each returns an error message, or null when the value is valid.

String? validateMealName(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return 'Enter a meal name';
  if (t.length > 40) return 'Keep the name to 40 characters or fewer';
  return null;
}

String? validatePrice(String? value) {
  final t = value?.trim() ?? '';
  if (t.isEmpty) return 'Enter a price';
  final p = double.tryParse(t);
  if (p == null || p.isNaN || p.isInfinite) return 'Enter a number, like 8.50';
  if (p <= 0) return 'Price must be more than 0';
  if (p > 100) return 'Price must be 100 or less';
  return null;
}

String? validateNote(String? value) {
  if ((value ?? '').length > 120) return 'Keep the note to 120 characters or fewer';
  return null;
}
