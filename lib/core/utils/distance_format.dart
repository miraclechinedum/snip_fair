/// A stylist's `distance` (km, from Laravel) for display, or null when it is
/// unknown — then no distance is shown at all (never "0 km").
///
/// Under 1 km: "< 1 km"; under 10 km: one decimal place ("2.4 km",
/// "1.0 km"); further: whole kilometres ("13 km"). The website uses the same
/// rules (resources/js/lib/distance.ts in the Laravel repository).
String? formatDistanceKm(Object? km) {
  final value = km is num ? km.toDouble() : double.tryParse('${km ?? ''}');
  if (value == null || !value.isFinite || value < 0) return null;
  if (value < 1) return '< 1 km';
  final tenths = (value * 10).round() / 10;
  if (tenths < 10) return '${tenths.toStringAsFixed(1)} km';
  return '${value.round()} km';
}

/// [formatDistanceKm] followed by "away", or null when unknown.
String? formatDistanceAway(Object? km) {
  final distance = formatDistanceKm(km);
  return distance == null ? null : '$distance away';
}
