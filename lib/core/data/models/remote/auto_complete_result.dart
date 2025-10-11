class AutoCompleteResult {
  String? type;
  List<Features>? features;
  Query? query;

  AutoCompleteResult({this.type, this.features, this.query});

  AutoCompleteResult.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(Features.fromJson(v as Map<String, dynamic>));
      });
    }
    query = json['query'] != null
        ? Query.fromJson(json['query'] as Map<String, dynamic>)
        : null;
  }
}

class Features {
  String? type;
  Properties? properties;
  Geometry? geometry;
  List<double>? bbox;

  Features({this.type, this.properties, this.geometry, this.bbox});

  Features.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    properties = json['properties'] != null
        ? Properties.fromJson(json['properties'] as Map<String, dynamic>)
        : null;
    geometry = json['geometry'] != null
        ? Geometry.fromJson(json['geometry'] as Map<String, dynamic>)
        : null;
    bbox =
        json['bbox'] != null ? List.from(json['bbox'] as List<dynamic>) : null;
  }
}

class Properties {
  String? country;
  String? countryCode;
  String? state;
  String? county;
  String? city;
  String? postcode;
  String? suburb;
  String? street;
  String? iso31662;
  Datasource? datasource;
  String? stateCode;
  double? lon;
  double? lat;
  String? resultType;
  String? formatted;
  String? addressLine1;
  String? addressLine2;
  Timezone? timezone;
  String? plusCode;
  String? plusCodeShort;
  Rank? rank;
  String? placeId;

  Properties(
      {this.country,
      this.countryCode,
      this.state,
      this.county,
      this.city,
      this.postcode,
      this.suburb,
      this.street,
      this.iso31662,
      this.datasource,
      this.stateCode,
      this.lon,
      this.lat,
      this.resultType,
      this.formatted,
      this.addressLine1,
      this.addressLine2,
      this.timezone,
      this.plusCode,
      this.plusCodeShort,
      this.rank,
      this.placeId});

  Properties.fromJson(Map<String, dynamic> json) {
    country = json['country'] as String?;
    countryCode = json['country_code'] as String?;
    state = json['state'] as String?;
    county = json['county'] as String?;
    city = json['city'] as String?;
    postcode = json['postcode'] as String?;
    suburb = json['suburb'] as String?;
    street = json['street'] as String?;
    iso31662 = json['iso3166_2'] as String?;
    datasource = json['datasource'] != null
        ? Datasource.fromJson(json['datasource'] as Map<String, dynamic>)
        : null;
    stateCode = json['state_code'] as String?;
    lon = json['lon'] as double?;
    lat = json['lat'] as double?;
    resultType = json['result_type'] as String?;
    formatted = json['formatted'] as String?;
    addressLine1 = json['address_line1'] as String?;
    addressLine2 = json['address_line2'] as String?;
    timezone = json['timezone'] != null
        ? Timezone.fromJson(json['timezone'] as Map<String, dynamic>)
        : null;
    plusCode = json['plus_code'] as String?;
    plusCodeShort = json['plus_code_short'] as String?;
    rank = json['rank'] != null
        ? Rank.fromJson(json['rank'] as Map<String, dynamic>)
        : null;
    placeId = json['place_id'] as String?;
  }
}

class Datasource {
  String? sourcename;
  String? attribution;
  String? license;
  String? url;

  Datasource({this.sourcename, this.attribution, this.license, this.url});

  Datasource.fromJson(Map<String, dynamic> json) {
    sourcename = json['sourcename'] as String?;
    attribution = json['attribution'] as String?;
    license = json['license'] as String?;
    url = json['url'] as String?;
  }
}

class Timezone {
  String? name;
  String? offsetSTD;
  int? offsetSTDSeconds;
  String? offsetDST;
  int? offsetDSTSeconds;
  String? abbreviationSTD;
  String? abbreviationDST;

  Timezone(
      {this.name,
      this.offsetSTD,
      this.offsetSTDSeconds,
      this.offsetDST,
      this.offsetDSTSeconds,
      this.abbreviationSTD,
      this.abbreviationDST});

  Timezone.fromJson(Map<String, dynamic> json) {
    name = json['name'] as String?;
    offsetSTD = json['offset_STD'] as String?;
    offsetSTDSeconds = json['offset_STD_seconds'] as int?;
    offsetDST = json['offset_DST'] as String?;
    offsetDSTSeconds = json['offset_DST_seconds'] as int?;
    abbreviationSTD = json['abbreviation_STD'] as String?;
    abbreviationDST = json['abbreviation_DST'] as String?;
  }
}

class Rank {
  int? confidence;
  int? confidenceStreetLevel;
  String? matchType;

  Rank({this.confidence, this.confidenceStreetLevel, this.matchType});

  Rank.fromJson(Map<String, dynamic> json) {
    confidence = json['confidence'] as int?;
    confidenceStreetLevel = json['confidence_street_level'] as int?;
    matchType = json['match_type'] as String?;
  }
}

class Geometry {
  String? type;
  List<double>? coordinates;

  Geometry({this.type, this.coordinates});

  Geometry.fromJson(Map<String, dynamic> json) {
    type = json['type'] as String?;
    coordinates = json['coordinates'] != null
        ? List.from(json['coordinates'] as List<dynamic>)
        : null;
  }
}

class Query {
  String? text;
  Parsed? parsed;
  List<String>? categories;

  Query({this.text, this.parsed, this.categories});

  Query.fromJson(Map<String, dynamic> json) {
    text = json['text'] as String?;
    parsed = json['parsed'] != null
        ? Parsed.fromJson(json['parsed'] as Map<String, dynamic>)
        : null;
    if (json['categories'] != null) {
      categories = <String>[];
      json['categories'].forEach((v) {
        categories!.add((v as String));
      });
    }
  }
}

class Parsed {
  String? street;
  String? expectedType;

  Parsed({this.street, this.expectedType});

  Parsed.fromJson(Map<String, dynamic> json) {
    street = json['street'] as String?;
    expectedType = json['expected_type'] as String?;
  }
}
