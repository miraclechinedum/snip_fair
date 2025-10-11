// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stylist_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StylistProfile {
  int? get id;
  @JsonKey(name: 'user_id')
  String? get userId;
  @JsonKey(name: 'business_name')
  String? get businessName;
  @JsonKey(name: 'years_of_experience')
  int? get yearsOfExperience;
  @JsonKey(name: 'identification_id')
  String? get identificationId;
  @JsonKey(name: 'identification_file')
  String? get identificationFile;
  @JsonKey(name: 'visits_count')
  int? get visitsCount;
  String? get status;
  @JsonKey(name: 'is_available')
  bool? get isAvailable;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  dynamic get banner;
  dynamic get socials;
  dynamic get works;

  /// Create a copy of StylistProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StylistProfileCopyWith<StylistProfile> get copyWith =>
      _$StylistProfileCopyWithImpl<StylistProfile>(
          this as StylistProfile, _$identity);

  /// Serializes this StylistProfile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StylistProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.yearsOfExperience, yearsOfExperience) ||
                other.yearsOfExperience == yearsOfExperience) &&
            (identical(other.identificationId, identificationId) ||
                other.identificationId == identificationId) &&
            (identical(other.identificationFile, identificationFile) ||
                other.identificationFile == identificationFile) &&
            (identical(other.visitsCount, visitsCount) ||
                other.visitsCount == visitsCount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other.banner, banner) &&
            const DeepCollectionEquality().equals(other.socials, socials) &&
            const DeepCollectionEquality().equals(other.works, works));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      businessName,
      yearsOfExperience,
      identificationId,
      identificationFile,
      visitsCount,
      status,
      isAvailable,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(banner),
      const DeepCollectionEquality().hash(socials),
      const DeepCollectionEquality().hash(works));

  @override
  String toString() {
    return 'StylistProfile(id: $id, userId: $userId, businessName: $businessName, yearsOfExperience: $yearsOfExperience, identificationId: $identificationId, identificationFile: $identificationFile, visitsCount: $visitsCount, status: $status, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt, banner: $banner, socials: $socials, works: $works)';
  }
}

/// @nodoc
abstract mixin class $StylistProfileCopyWith<$Res> {
  factory $StylistProfileCopyWith(
          StylistProfile value, $Res Function(StylistProfile) _then) =
      _$StylistProfileCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'business_name') String? businessName,
      @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
      @JsonKey(name: 'identification_id') String? identificationId,
      @JsonKey(name: 'identification_file') String? identificationFile,
      @JsonKey(name: 'visits_count') int? visitsCount,
      String? status,
      @JsonKey(name: 'is_available') bool? isAvailable,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      dynamic banner,
      dynamic socials,
      dynamic works});
}

/// @nodoc
class _$StylistProfileCopyWithImpl<$Res>
    implements $StylistProfileCopyWith<$Res> {
  _$StylistProfileCopyWithImpl(this._self, this._then);

  final StylistProfile _self;
  final $Res Function(StylistProfile) _then;

  /// Create a copy of StylistProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? businessName = freezed,
    Object? yearsOfExperience = freezed,
    Object? identificationId = freezed,
    Object? identificationFile = freezed,
    Object? visitsCount = freezed,
    Object? status = freezed,
    Object? isAvailable = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? banner = freezed,
    Object? socials = freezed,
    Object? works = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessName: freezed == businessName
          ? _self.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      yearsOfExperience: freezed == yearsOfExperience
          ? _self.yearsOfExperience
          : yearsOfExperience // ignore: cast_nullable_to_non_nullable
              as int?,
      identificationId: freezed == identificationId
          ? _self.identificationId
          : identificationId // ignore: cast_nullable_to_non_nullable
              as String?,
      identificationFile: freezed == identificationFile
          ? _self.identificationFile
          : identificationFile // ignore: cast_nullable_to_non_nullable
              as String?,
      visitsCount: freezed == visitsCount
          ? _self.visitsCount
          : visitsCount // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      isAvailable: freezed == isAvailable
          ? _self.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      banner: freezed == banner
          ? _self.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as dynamic,
      socials: freezed == socials
          ? _self.socials
          : socials // ignore: cast_nullable_to_non_nullable
              as dynamic,
      works: freezed == works
          ? _self.works
          : works // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// Adds pattern-matching-related methods to [StylistProfile].
extension StylistProfilePatterns on StylistProfile {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_StylistProfile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StylistProfile() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_StylistProfile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StylistProfile():
        return $default(_that);
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_StylistProfile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StylistProfile() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int? id,
            @JsonKey(name: 'user_id') String? userId,
            @JsonKey(name: 'business_name') String? businessName,
            @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
            @JsonKey(name: 'identification_id') String? identificationId,
            @JsonKey(name: 'identification_file') String? identificationFile,
            @JsonKey(name: 'visits_count') int? visitsCount,
            String? status,
            @JsonKey(name: 'is_available') bool? isAvailable,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            dynamic banner,
            dynamic socials,
            dynamic works)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StylistProfile() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.businessName,
            _that.yearsOfExperience,
            _that.identificationId,
            _that.identificationFile,
            _that.visitsCount,
            _that.status,
            _that.isAvailable,
            _that.createdAt,
            _that.updatedAt,
            _that.banner,
            _that.socials,
            _that.works);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int? id,
            @JsonKey(name: 'user_id') String? userId,
            @JsonKey(name: 'business_name') String? businessName,
            @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
            @JsonKey(name: 'identification_id') String? identificationId,
            @JsonKey(name: 'identification_file') String? identificationFile,
            @JsonKey(name: 'visits_count') int? visitsCount,
            String? status,
            @JsonKey(name: 'is_available') bool? isAvailable,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            dynamic banner,
            dynamic socials,
            dynamic works)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StylistProfile():
        return $default(
            _that.id,
            _that.userId,
            _that.businessName,
            _that.yearsOfExperience,
            _that.identificationId,
            _that.identificationFile,
            _that.visitsCount,
            _that.status,
            _that.isAvailable,
            _that.createdAt,
            _that.updatedAt,
            _that.banner,
            _that.socials,
            _that.works);
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int? id,
            @JsonKey(name: 'user_id') String? userId,
            @JsonKey(name: 'business_name') String? businessName,
            @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
            @JsonKey(name: 'identification_id') String? identificationId,
            @JsonKey(name: 'identification_file') String? identificationFile,
            @JsonKey(name: 'visits_count') int? visitsCount,
            String? status,
            @JsonKey(name: 'is_available') bool? isAvailable,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            dynamic banner,
            dynamic socials,
            dynamic works)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StylistProfile() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.businessName,
            _that.yearsOfExperience,
            _that.identificationId,
            _that.identificationFile,
            _that.visitsCount,
            _that.status,
            _that.isAvailable,
            _that.createdAt,
            _that.updatedAt,
            _that.banner,
            _that.socials,
            _that.works);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _StylistProfile implements StylistProfile {
  _StylistProfile(
      {this.id,
      @JsonKey(name: 'user_id') this.userId,
      @JsonKey(name: 'business_name') this.businessName,
      @JsonKey(name: 'years_of_experience') this.yearsOfExperience,
      @JsonKey(name: 'identification_id') this.identificationId,
      @JsonKey(name: 'identification_file') this.identificationFile,
      @JsonKey(name: 'visits_count') this.visitsCount,
      this.status,
      @JsonKey(name: 'is_available') this.isAvailable,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      this.banner,
      this.socials,
      this.works});
  factory _StylistProfile.fromJson(Map<String, dynamic> json) =>
      _$StylistProfileFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  @JsonKey(name: 'business_name')
  final String? businessName;
  @override
  @JsonKey(name: 'years_of_experience')
  final int? yearsOfExperience;
  @override
  @JsonKey(name: 'identification_id')
  final String? identificationId;
  @override
  @JsonKey(name: 'identification_file')
  final String? identificationFile;
  @override
  @JsonKey(name: 'visits_count')
  final int? visitsCount;
  @override
  final String? status;
  @override
  @JsonKey(name: 'is_available')
  final bool? isAvailable;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  final dynamic banner;
  @override
  final dynamic socials;
  @override
  final dynamic works;

  /// Create a copy of StylistProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StylistProfileCopyWith<_StylistProfile> get copyWith =>
      __$StylistProfileCopyWithImpl<_StylistProfile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StylistProfileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StylistProfile &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.yearsOfExperience, yearsOfExperience) ||
                other.yearsOfExperience == yearsOfExperience) &&
            (identical(other.identificationId, identificationId) ||
                other.identificationId == identificationId) &&
            (identical(other.identificationFile, identificationFile) ||
                other.identificationFile == identificationFile) &&
            (identical(other.visitsCount, visitsCount) ||
                other.visitsCount == visitsCount) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other.banner, banner) &&
            const DeepCollectionEquality().equals(other.socials, socials) &&
            const DeepCollectionEquality().equals(other.works, works));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      businessName,
      yearsOfExperience,
      identificationId,
      identificationFile,
      visitsCount,
      status,
      isAvailable,
      createdAt,
      updatedAt,
      const DeepCollectionEquality().hash(banner),
      const DeepCollectionEquality().hash(socials),
      const DeepCollectionEquality().hash(works));

  @override
  String toString() {
    return 'StylistProfile(id: $id, userId: $userId, businessName: $businessName, yearsOfExperience: $yearsOfExperience, identificationId: $identificationId, identificationFile: $identificationFile, visitsCount: $visitsCount, status: $status, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt, banner: $banner, socials: $socials, works: $works)';
  }
}

/// @nodoc
abstract mixin class _$StylistProfileCopyWith<$Res>
    implements $StylistProfileCopyWith<$Res> {
  factory _$StylistProfileCopyWith(
          _StylistProfile value, $Res Function(_StylistProfile) _then) =
      __$StylistProfileCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'business_name') String? businessName,
      @JsonKey(name: 'years_of_experience') int? yearsOfExperience,
      @JsonKey(name: 'identification_id') String? identificationId,
      @JsonKey(name: 'identification_file') String? identificationFile,
      @JsonKey(name: 'visits_count') int? visitsCount,
      String? status,
      @JsonKey(name: 'is_available') bool? isAvailable,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      dynamic banner,
      dynamic socials,
      dynamic works});
}

/// @nodoc
class __$StylistProfileCopyWithImpl<$Res>
    implements _$StylistProfileCopyWith<$Res> {
  __$StylistProfileCopyWithImpl(this._self, this._then);

  final _StylistProfile _self;
  final $Res Function(_StylistProfile) _then;

  /// Create a copy of StylistProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? businessName = freezed,
    Object? yearsOfExperience = freezed,
    Object? identificationId = freezed,
    Object? identificationFile = freezed,
    Object? visitsCount = freezed,
    Object? status = freezed,
    Object? isAvailable = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? banner = freezed,
    Object? socials = freezed,
    Object? works = freezed,
  }) {
    return _then(_StylistProfile(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      userId: freezed == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      businessName: freezed == businessName
          ? _self.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      yearsOfExperience: freezed == yearsOfExperience
          ? _self.yearsOfExperience
          : yearsOfExperience // ignore: cast_nullable_to_non_nullable
              as int?,
      identificationId: freezed == identificationId
          ? _self.identificationId
          : identificationId // ignore: cast_nullable_to_non_nullable
              as String?,
      identificationFile: freezed == identificationFile
          ? _self.identificationFile
          : identificationFile // ignore: cast_nullable_to_non_nullable
              as String?,
      visitsCount: freezed == visitsCount
          ? _self.visitsCount
          : visitsCount // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      isAvailable: freezed == isAvailable
          ? _self.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      banner: freezed == banner
          ? _self.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as dynamic,
      socials: freezed == socials
          ? _self.socials
          : socials // ignore: cast_nullable_to_non_nullable
              as dynamic,
      works: freezed == works
          ? _self.works
          : works // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

// dart format on
