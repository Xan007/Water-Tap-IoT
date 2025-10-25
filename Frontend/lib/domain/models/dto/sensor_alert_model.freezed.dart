// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sensor_alert_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SensorAlertModel {

 int? get id; int get sensorId; String get description; String get severity; bool get active;
/// Create a copy of SensorAlertModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SensorAlertModelCopyWith<SensorAlertModel> get copyWith => _$SensorAlertModelCopyWithImpl<SensorAlertModel>(this as SensorAlertModel, _$identity);

  /// Serializes this SensorAlertModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SensorAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sensorId,description,severity,active);

@override
String toString() {
  return 'SensorAlertModel(id: $id, sensorId: $sensorId, description: $description, severity: $severity, active: $active)';
}


}

/// @nodoc
abstract mixin class $SensorAlertModelCopyWith<$Res>  {
  factory $SensorAlertModelCopyWith(SensorAlertModel value, $Res Function(SensorAlertModel) _then) = _$SensorAlertModelCopyWithImpl;
@useResult
$Res call({
 int? id, int sensorId, String description, String severity, bool active
});




}
/// @nodoc
class _$SensorAlertModelCopyWithImpl<$Res>
    implements $SensorAlertModelCopyWith<$Res> {
  _$SensorAlertModelCopyWithImpl(this._self, this._then);

  final SensorAlertModel _self;
  final $Res Function(SensorAlertModel) _then;

/// Create a copy of SensorAlertModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? sensorId = null,Object? description = null,Object? severity = null,Object? active = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SensorAlertModel].
extension SensorAlertModelPatterns on SensorAlertModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SensorAlertModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SensorAlertModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SensorAlertModel value)  $default,){
final _that = this;
switch (_that) {
case _SensorAlertModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SensorAlertModel value)?  $default,){
final _that = this;
switch (_that) {
case _SensorAlertModel() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int sensorId,  String description,  String severity,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SensorAlertModel() when $default != null:
return $default(_that.id,_that.sensorId,_that.description,_that.severity,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int sensorId,  String description,  String severity,  bool active)  $default,) {final _that = this;
switch (_that) {
case _SensorAlertModel():
return $default(_that.id,_that.sensorId,_that.description,_that.severity,_that.active);case _:
  throw StateError('Unexpected subclass');

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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int sensorId,  String description,  String severity,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _SensorAlertModel() when $default != null:
return $default(_that.id,_that.sensorId,_that.description,_that.severity,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SensorAlertModel implements SensorAlertModel {
  const _SensorAlertModel({required this.id, required this.sensorId, required this.description, required this.severity, this.active = true});
  factory _SensorAlertModel.fromJson(Map<String, dynamic> json) => _$SensorAlertModelFromJson(json);

@override final  int? id;
@override final  int sensorId;
@override final  String description;
@override final  String severity;
@override@JsonKey() final  bool active;

/// Create a copy of SensorAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SensorAlertModelCopyWith<_SensorAlertModel> get copyWith => __$SensorAlertModelCopyWithImpl<_SensorAlertModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SensorAlertModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SensorAlertModel&&(identical(other.id, id) || other.id == id)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sensorId,description,severity,active);

@override
String toString() {
  return 'SensorAlertModel(id: $id, sensorId: $sensorId, description: $description, severity: $severity, active: $active)';
}


}

/// @nodoc
abstract mixin class _$SensorAlertModelCopyWith<$Res> implements $SensorAlertModelCopyWith<$Res> {
  factory _$SensorAlertModelCopyWith(_SensorAlertModel value, $Res Function(_SensorAlertModel) _then) = __$SensorAlertModelCopyWithImpl;
@override @useResult
$Res call({
 int? id, int sensorId, String description, String severity, bool active
});




}
/// @nodoc
class __$SensorAlertModelCopyWithImpl<$Res>
    implements _$SensorAlertModelCopyWith<$Res> {
  __$SensorAlertModelCopyWithImpl(this._self, this._then);

  final _SensorAlertModel _self;
  final $Res Function(_SensorAlertModel) _then;

/// Create a copy of SensorAlertModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? sensorId = null,Object? description = null,Object? severity = null,Object? active = null,}) {
  return _then(_SensorAlertModel(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
