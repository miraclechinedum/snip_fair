/// Coerces a JSON value to `String?`.
///
/// Some backend environments return numeric ID / count fields as `int` and
/// others (notably the production Laravel API) return the same fields as
/// `String`. Model fields declared as `String?` blow up on the hard cast when
/// the value arrives as an int. Use this as `fromJson:` on the affected
/// `@JsonKey` annotations so deserialization survives either shape.
String? toStringOrNull(dynamic v) => v?.toString();

/// Coerces a JSON list to `List<String>?`, skipping any null / non-String
/// elements. The Laravel backend sometimes returns e.g. `media_urls: [null]`,
/// and the generated `map((e) => e as String)` crashes on the null. Use this
/// as `fromJson:` on nullable-string-list fields so deserialization tolerates
/// stray nulls without dropping the whole parent object.
List<String>? nonNullStringList(dynamic v) {
  if (v is! List) return null;
  return v.whereType<String>().toList();
}

/// Coerces a JSON money/number value to `num?` without losing cents.
///
/// Laravel sends amounts as JSON numbers (`250`, `250.5`), as decimal
/// strings from SQL sums (`"250.50"`) or via `number_format` with thousands
/// separators (`"1,250.00"`). Anything else (null, bools, words) is null —
/// "unknown", never silently zero.
num? toNumOrNull(dynamic v) {
  if (v is num) return v.isFinite ? v : null;
  if (v is! String) return null;
  final cleaned = v.trim().replaceAll(',', '').replaceAll(' ', '');
  if (cleaned.isEmpty) return null;
  final parsed = num.tryParse(cleaned);
  return parsed != null && parsed.isFinite ? parsed : null;
}

/// Coerces a JSON count to `int?`: whole numbers given as `3`, `3.0` or
/// `"3"`. Fractions and non-numbers are null, never truncated.
int? toIntOrNull(dynamic v) {
  final n = toNumOrNull(v);
  if (n == null || n != n.truncate()) return null;
  return n.toInt();
}
