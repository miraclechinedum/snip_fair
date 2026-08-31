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
