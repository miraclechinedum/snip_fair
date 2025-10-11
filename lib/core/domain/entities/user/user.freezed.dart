// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {
  int? get id;
  String? get name;
  @JsonKey(name: 'first_name')
  String? get firstName;
  @JsonKey(name: 'last_name')
  String? get lastName;
  String? get email;
  @JsonKey(name: 'email_verified_at')
  DateTime? get emailVerifiedAt;
  @JsonKey(name: 'phone_verified_at')
  dynamic get phoneVerifiedAt;
  String? get phone;
  String? get country;
  String? get bio;
  String? get type;
  String? get role;
  String? get avatar;
  @JsonKey(name: 'last_login_at')
  DateTime? get lastLoginAt;
  String? get status;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @JsonKey(name: 'deleted_at')
  dynamic get deletedAt;
  int? get balance;
  @JsonKey(name: 'is_featured')
  bool? get isFeatured;
  @JsonKey(name: 'use_location')
  bool? get useLocation;
  @JsonKey(name: 'subscription_status')
  String? get subscriptionStatus;
  bool? get availability;
  dynamic get plan;
  @JsonKey(name: 'stylist_profile')
  StylistProfile? get stylistProfile;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserCopyWith<User> get copyWith =>
      _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is User &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.emailVerifiedAt, emailVerifiedAt) ||
                other.emailVerifiedAt == emailVerifiedAt) &&
            const DeepCollectionEquality()
                .equals(other.phoneVerifiedAt, phoneVerifiedAt) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other.deletedAt, deletedAt) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.useLocation, useLocation) ||
                other.useLocation == useLocation) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.availability, availability) ||
                other.availability == availability) &&
            const DeepCollectionEquality().equals(other.plan, plan) &&
            (identical(other.stylistProfile, stylistProfile) ||
                other.stylistProfile == stylistProfile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        firstName,
        lastName,
        email,
        emailVerifiedAt,
        const DeepCollectionEquality().hash(phoneVerifiedAt),
        phone,
        country,
        bio,
        type,
        role,
        avatar,
        lastLoginAt,
        status,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(deletedAt),
        balance,
        isFeatured,
        useLocation,
        subscriptionStatus,
        availability,
        const DeepCollectionEquality().hash(plan),
        stylistProfile
      ]);

  @override
  String toString() {
    return 'User(id: $id, name: $name, firstName: $firstName, lastName: $lastName, email: $email, emailVerifiedAt: $emailVerifiedAt, phoneVerifiedAt: $phoneVerifiedAt, phone: $phone, country: $country, bio: $bio, type: $type, role: $role, avatar: $avatar, lastLoginAt: $lastLoginAt, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, balance: $balance, isFeatured: $isFeatured, useLocation: $useLocation, subscriptionStatus: $subscriptionStatus, availability: $availability, plan: $plan, stylistProfile: $stylistProfile)';
  }
}

/// @nodoc
abstract mixin class $UserCopyWith<$Res> {
  factory $UserCopyWith(User value, $Res Function(User) _then) =
      _$UserCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      String? name,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      String? email,
      @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
      @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
      String? phone,
      String? country,
      String? bio,
      String? type,
      String? role,
      String? avatar,
      @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
      String? status,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'deleted_at') dynamic deletedAt,
      int? balance,
      @JsonKey(name: 'is_featured') bool? isFeatured,
      @JsonKey(name: 'use_location') bool? useLocation,
      @JsonKey(name: 'subscription_status') String? subscriptionStatus,
      bool? availability,
      dynamic plan,
      @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile});

  $StylistProfileCopyWith<$Res>? get stylistProfile;
}

/// @nodoc
class _$UserCopyWithImpl<$Res> implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? email = freezed,
    Object? emailVerifiedAt = freezed,
    Object? phoneVerifiedAt = freezed,
    Object? phone = freezed,
    Object? country = freezed,
    Object? bio = freezed,
    Object? type = freezed,
    Object? role = freezed,
    Object? avatar = freezed,
    Object? lastLoginAt = freezed,
    Object? status = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? balance = freezed,
    Object? isFeatured = freezed,
    Object? useLocation = freezed,
    Object? subscriptionStatus = freezed,
    Object? availability = freezed,
    Object? plan = freezed,
    Object? stylistProfile = freezed,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      emailVerifiedAt: freezed == emailVerifiedAt
          ? _self.emailVerifiedAt
          : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      phoneVerifiedAt: freezed == phoneVerifiedAt
          ? _self.phoneVerifiedAt
          : phoneVerifiedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLoginAt: freezed == lastLoginAt
          ? _self.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      balance: freezed == balance
          ? _self.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as int?,
      isFeatured: freezed == isFeatured
          ? _self.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool?,
      useLocation: freezed == useLocation
          ? _self.useLocation
          : useLocation // ignore: cast_nullable_to_non_nullable
              as bool?,
      subscriptionStatus: freezed == subscriptionStatus
          ? _self.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      availability: freezed == availability
          ? _self.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as bool?,
      plan: freezed == plan
          ? _self.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as dynamic,
      stylistProfile: freezed == stylistProfile
          ? _self.stylistProfile
          : stylistProfile // ignore: cast_nullable_to_non_nullable
              as StylistProfile?,
    ));
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StylistProfileCopyWith<$Res>? get stylistProfile {
    if (_self.stylistProfile == null) {
      return null;
    }

    return $StylistProfileCopyWith<$Res>(_self.stylistProfile!, (value) {
      return _then(_self.copyWith(stylistProfile: value));
    });
  }
}

/// Adds pattern-matching-related methods to [User].
extension UserPatterns on User {
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
    TResult Function(_User value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
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
    TResult Function(_User value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User():
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
    TResult? Function(_User value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
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
            String? name,
            @JsonKey(name: 'first_name') String? firstName,
            @JsonKey(name: 'last_name') String? lastName,
            String? email,
            @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
            @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
            String? phone,
            String? country,
            String? bio,
            String? type,
            String? role,
            String? avatar,
            @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
            String? status,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'deleted_at') dynamic deletedAt,
            int? balance,
            @JsonKey(name: 'is_featured') bool? isFeatured,
            @JsonKey(name: 'use_location') bool? useLocation,
            @JsonKey(name: 'subscription_status') String? subscriptionStatus,
            bool? availability,
            dynamic plan,
            @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.firstName,
            _that.lastName,
            _that.email,
            _that.emailVerifiedAt,
            _that.phoneVerifiedAt,
            _that.phone,
            _that.country,
            _that.bio,
            _that.type,
            _that.role,
            _that.avatar,
            _that.lastLoginAt,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.deletedAt,
            _that.balance,
            _that.isFeatured,
            _that.useLocation,
            _that.subscriptionStatus,
            _that.availability,
            _that.plan,
            _that.stylistProfile);
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
            String? name,
            @JsonKey(name: 'first_name') String? firstName,
            @JsonKey(name: 'last_name') String? lastName,
            String? email,
            @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
            @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
            String? phone,
            String? country,
            String? bio,
            String? type,
            String? role,
            String? avatar,
            @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
            String? status,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'deleted_at') dynamic deletedAt,
            int? balance,
            @JsonKey(name: 'is_featured') bool? isFeatured,
            @JsonKey(name: 'use_location') bool? useLocation,
            @JsonKey(name: 'subscription_status') String? subscriptionStatus,
            bool? availability,
            dynamic plan,
            @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User():
        return $default(
            _that.id,
            _that.name,
            _that.firstName,
            _that.lastName,
            _that.email,
            _that.emailVerifiedAt,
            _that.phoneVerifiedAt,
            _that.phone,
            _that.country,
            _that.bio,
            _that.type,
            _that.role,
            _that.avatar,
            _that.lastLoginAt,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.deletedAt,
            _that.balance,
            _that.isFeatured,
            _that.useLocation,
            _that.subscriptionStatus,
            _that.availability,
            _that.plan,
            _that.stylistProfile);
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
            String? name,
            @JsonKey(name: 'first_name') String? firstName,
            @JsonKey(name: 'last_name') String? lastName,
            String? email,
            @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
            @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
            String? phone,
            String? country,
            String? bio,
            String? type,
            String? role,
            String? avatar,
            @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
            String? status,
            @JsonKey(name: 'created_at') DateTime? createdAt,
            @JsonKey(name: 'updated_at') DateTime? updatedAt,
            @JsonKey(name: 'deleted_at') dynamic deletedAt,
            int? balance,
            @JsonKey(name: 'is_featured') bool? isFeatured,
            @JsonKey(name: 'use_location') bool? useLocation,
            @JsonKey(name: 'subscription_status') String? subscriptionStatus,
            bool? availability,
            dynamic plan,
            @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _User() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.firstName,
            _that.lastName,
            _that.email,
            _that.emailVerifiedAt,
            _that.phoneVerifiedAt,
            _that.phone,
            _that.country,
            _that.bio,
            _that.type,
            _that.role,
            _that.avatar,
            _that.lastLoginAt,
            _that.status,
            _that.createdAt,
            _that.updatedAt,
            _that.deletedAt,
            _that.balance,
            _that.isFeatured,
            _that.useLocation,
            _that.subscriptionStatus,
            _that.availability,
            _that.plan,
            _that.stylistProfile);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _User implements User {
  const _User(
      {this.id,
      this.name,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      this.email,
      @JsonKey(name: 'email_verified_at') this.emailVerifiedAt,
      @JsonKey(name: 'phone_verified_at') this.phoneVerifiedAt,
      this.phone,
      this.country,
      this.bio,
      this.type,
      this.role,
      this.avatar,
      @JsonKey(name: 'last_login_at') this.lastLoginAt,
      this.status,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'deleted_at') this.deletedAt,
      this.balance,
      @JsonKey(name: 'is_featured') this.isFeatured,
      @JsonKey(name: 'use_location') this.useLocation,
      @JsonKey(name: 'subscription_status') this.subscriptionStatus,
      this.availability,
      this.plan,
      @JsonKey(name: 'stylist_profile') this.stylistProfile});
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  final int? id;
  @override
  final String? name;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  @override
  final String? email;
  @override
  @JsonKey(name: 'email_verified_at')
  final DateTime? emailVerifiedAt;
  @override
  @JsonKey(name: 'phone_verified_at')
  final dynamic phoneVerifiedAt;
  @override
  final String? phone;
  @override
  final String? country;
  @override
  final String? bio;
  @override
  final String? type;
  @override
  final String? role;
  @override
  final String? avatar;
  @override
  @JsonKey(name: 'last_login_at')
  final DateTime? lastLoginAt;
  @override
  final String? status;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'deleted_at')
  final dynamic deletedAt;
  @override
  final int? balance;
  @override
  @JsonKey(name: 'is_featured')
  final bool? isFeatured;
  @override
  @JsonKey(name: 'use_location')
  final bool? useLocation;
  @override
  @JsonKey(name: 'subscription_status')
  final String? subscriptionStatus;
  @override
  final bool? availability;
  @override
  final dynamic plan;
  @override
  @JsonKey(name: 'stylist_profile')
  final StylistProfile? stylistProfile;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserCopyWith<_User> get copyWith =>
      __$UserCopyWithImpl<_User>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _User &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.emailVerifiedAt, emailVerifiedAt) ||
                other.emailVerifiedAt == emailVerifiedAt) &&
            const DeepCollectionEquality()
                .equals(other.phoneVerifiedAt, phoneVerifiedAt) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other.deletedAt, deletedAt) &&
            (identical(other.balance, balance) || other.balance == balance) &&
            (identical(other.isFeatured, isFeatured) ||
                other.isFeatured == isFeatured) &&
            (identical(other.useLocation, useLocation) ||
                other.useLocation == useLocation) &&
            (identical(other.subscriptionStatus, subscriptionStatus) ||
                other.subscriptionStatus == subscriptionStatus) &&
            (identical(other.availability, availability) ||
                other.availability == availability) &&
            const DeepCollectionEquality().equals(other.plan, plan) &&
            (identical(other.stylistProfile, stylistProfile) ||
                other.stylistProfile == stylistProfile));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        firstName,
        lastName,
        email,
        emailVerifiedAt,
        const DeepCollectionEquality().hash(phoneVerifiedAt),
        phone,
        country,
        bio,
        type,
        role,
        avatar,
        lastLoginAt,
        status,
        createdAt,
        updatedAt,
        const DeepCollectionEquality().hash(deletedAt),
        balance,
        isFeatured,
        useLocation,
        subscriptionStatus,
        availability,
        const DeepCollectionEquality().hash(plan),
        stylistProfile
      ]);

  @override
  String toString() {
    return 'User(id: $id, name: $name, firstName: $firstName, lastName: $lastName, email: $email, emailVerifiedAt: $emailVerifiedAt, phoneVerifiedAt: $phoneVerifiedAt, phone: $phone, country: $country, bio: $bio, type: $type, role: $role, avatar: $avatar, lastLoginAt: $lastLoginAt, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, deletedAt: $deletedAt, balance: $balance, isFeatured: $isFeatured, useLocation: $useLocation, subscriptionStatus: $subscriptionStatus, availability: $availability, plan: $plan, stylistProfile: $stylistProfile)';
  }
}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) =
      __$UserCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      String? name,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      String? email,
      @JsonKey(name: 'email_verified_at') DateTime? emailVerifiedAt,
      @JsonKey(name: 'phone_verified_at') dynamic phoneVerifiedAt,
      String? phone,
      String? country,
      String? bio,
      String? type,
      String? role,
      String? avatar,
      @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,
      String? status,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      @JsonKey(name: 'deleted_at') dynamic deletedAt,
      int? balance,
      @JsonKey(name: 'is_featured') bool? isFeatured,
      @JsonKey(name: 'use_location') bool? useLocation,
      @JsonKey(name: 'subscription_status') String? subscriptionStatus,
      bool? availability,
      dynamic plan,
      @JsonKey(name: 'stylist_profile') StylistProfile? stylistProfile});

  @override
  $StylistProfileCopyWith<$Res>? get stylistProfile;
}

/// @nodoc
class __$UserCopyWithImpl<$Res> implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? email = freezed,
    Object? emailVerifiedAt = freezed,
    Object? phoneVerifiedAt = freezed,
    Object? phone = freezed,
    Object? country = freezed,
    Object? bio = freezed,
    Object? type = freezed,
    Object? role = freezed,
    Object? avatar = freezed,
    Object? lastLoginAt = freezed,
    Object? status = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? deletedAt = freezed,
    Object? balance = freezed,
    Object? isFeatured = freezed,
    Object? useLocation = freezed,
    Object? subscriptionStatus = freezed,
    Object? availability = freezed,
    Object? plan = freezed,
    Object? stylistProfile = freezed,
  }) {
    return _then(_User(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      firstName: freezed == firstName
          ? _self.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _self.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      emailVerifiedAt: freezed == emailVerifiedAt
          ? _self.emailVerifiedAt
          : emailVerifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      phoneVerifiedAt: freezed == phoneVerifiedAt
          ? _self.phoneVerifiedAt
          : phoneVerifiedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      country: freezed == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String?,
      bio: freezed == bio
          ? _self.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      type: freezed == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _self.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _self.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLoginAt: freezed == lastLoginAt
          ? _self.lastLoginAt
          : lastLoginAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: freezed == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedAt: freezed == deletedAt
          ? _self.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as dynamic,
      balance: freezed == balance
          ? _self.balance
          : balance // ignore: cast_nullable_to_non_nullable
              as int?,
      isFeatured: freezed == isFeatured
          ? _self.isFeatured
          : isFeatured // ignore: cast_nullable_to_non_nullable
              as bool?,
      useLocation: freezed == useLocation
          ? _self.useLocation
          : useLocation // ignore: cast_nullable_to_non_nullable
              as bool?,
      subscriptionStatus: freezed == subscriptionStatus
          ? _self.subscriptionStatus
          : subscriptionStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      availability: freezed == availability
          ? _self.availability
          : availability // ignore: cast_nullable_to_non_nullable
              as bool?,
      plan: freezed == plan
          ? _self.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as dynamic,
      stylistProfile: freezed == stylistProfile
          ? _self.stylistProfile
          : stylistProfile // ignore: cast_nullable_to_non_nullable
              as StylistProfile?,
    ));
  }

  /// Create a copy of User
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StylistProfileCopyWith<$Res>? get stylistProfile {
    if (_self.stylistProfile == null) {
      return null;
    }

    return $StylistProfileCopyWith<$Res>(_self.stylistProfile!, (value) {
      return _then(_self.copyWith(stylistProfile: value));
    });
  }
}

// dart format on
