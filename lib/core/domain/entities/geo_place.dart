/// An address, with its coordinates when it was picked from address search.
///
/// An address typed by hand (or loaded from the profile, which only has the
/// text) has no coordinates: [lat] and [lng] are null, never a (0, 0)
/// placeholder.
class GeoPlace {
  GeoPlace({
    required this.address,
    this.lat,
    this.lng,
    this.placeId,
  });

  final String address;
  final double? lat;
  final double? lng;
  final String? placeId;

  /// Both coordinates present, in range and not (0, 0).
  bool get hasValidCoordinates => isValidPair(lat, lng);

  static bool isValidPair(num? latitude, num? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    return !(latitude == 0 && longitude == 0);
  }

  /// The fields Laravel stores with an address (`address_latitude`,
  /// `address_longitude`, `address_place_id`); empty without valid
  /// coordinates, so the server clears any coordinates of an older address.
  Map<String, Object> get coordinateFields => hasValidCoordinates
      ? {
          'address_latitude': lat!,
          'address_longitude': lng!,
          if (placeId != null && placeId!.isNotEmpty)
            'address_place_id': placeId!,
        }
      : const {};
}
