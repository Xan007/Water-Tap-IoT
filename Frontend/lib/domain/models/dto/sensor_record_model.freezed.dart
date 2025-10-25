// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sensor_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SensorRecordModel {

 DateTime get timestamp; int get sensorId; double? get ph; double? get turbidity; double? get conductivity; double? get flowRate;
/// Create a copy of SensorRecordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SensorRecordModelCopyWith<SensorRecordModel> get copyWith => _$SensorRecordModelCopyWithImpl<SensorRecordModel>(this as SensorRecordModel, _$identity);

  /// Serializes this SensorRecordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SensorRecordModel&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&(identical(other.ph, ph) || other.ph == ph)&&(identical(other.turbidity, turbidity) || other.turbidity == turbidity)&&(identical(other.conductivity, conductivity) || other.conductivity == conductivity)&&(identical(other.flowRate, flowRate) || other.flowRate == flowRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,sensorId,ph,turbidity,conductivity,flowRate);

@override
String toString() {
  return 'SensorRecordModel(timestamp: $timestamp, sensorId: $sensorId, ph: $ph, turbidity: $turbidity, conductivity: $conductivity, flowRate: $flowRate)';
}


}

/// @nodoc
abstract mixin class $SensorRecordModelCopyWith<$Res>  {
  factory $SensorRecordModelCopyWith(SensorRecordModel value, $Res Function(SensorRecordModel) _then) = _$SensorRecordModelCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, int sensorId, double? ph, double? turbidity, double? conductivity, double? flowRate
});




}
/// @nodoc
class _$SensorRecordModelCopyWithImpl<$Res>
    implements $SensorRecordModelCopyWith<$Res> {
  _$SensorRecordModelCopyWithImpl(this._self, this._then);

  final SensorRecordModel _self;
  final $Res Function(SensorRecordModel) _then;

/// Create a copy of SensorRecordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? sensorId = null,Object? ph = freezed,Object? turbidity = freezed,Object? conductivity = freezed,Object? flowRate = freezed,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,ph: freezed == ph ? _self.ph : ph // ignore: cast_nullable_to_non_nullable
as double?,turbidity: freezed == turbidity ? _self.turbidity : turbidity // ignore: cast_nullable_to_non_nullable
as double?,conductivity: freezed == conductivity ? _self.conductivity : conductivity // ignore: cast_nullable_to_non_nullable
as double?,flowRate: freezed == flowRate ? _self.flowRate : flowRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [SensorRecordModel].
extension SensorRecordModelPatterns on SensorRecordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SensorRecordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SensorRecordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SensorRecordModel value)  $default,){
final _that = this;
switch (_that) {
case _SensorRecordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SensorRecordModel value)?  $default,){
final _that = this;
switch (_that) {
case _SensorRecordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  int sensorId,  double? ph,  double? turbidity,  double? conductivity,  double? flowRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SensorRecordModel() when $default != null:
return $default(_that.timestamp,_that.sensorId,_that.ph,_that.turbidity,_that.conductivity,_that.flowRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  int sensorId,  double? ph,  double? turbidity,  double? conductivity,  double? flowRate)  $default,) {final _that = this;
switch (_that) {
case _SensorRecordModel():
return $default(_that.timestamp,_that.sensorId,_that.ph,_that.turbidity,_that.conductivity,_that.flowRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  int sensorId,  double? ph,  double? turbidity,  double? conductivity,  double? flowRate)?  $default,) {final _that = this;
switch (_that) {
case _SensorRecordModel() when $default != null:
return $default(_that.timestamp,_that.sensorId,_that.ph,_that.turbidity,_that.conductivity,_that.flowRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SensorRecordModel implements SensorRecordModel {
  const _SensorRecordModel({required this.timestamp, required this.sensorId, required this.ph, required this.turbidity, required this.conductivity, required this.flowRate});
  factory _SensorRecordModel.fromJson(Map<String, dynamic> json) => _$SensorRecordModelFromJson(json);

@override final  DateTime timestamp;
@override final  int sensorId;
@override final  double? ph;
@override final  double? turbidity;
@override final  double? conductivity;
@override final  double? flowRate;

/// Create a copy of SensorRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SensorRecordModelCopyWith<_SensorRecordModel> get copyWith => __$SensorRecordModelCopyWithImpl<_SensorRecordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SensorRecordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SensorRecordModel&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&(identical(other.ph, ph) || other.ph == ph)&&(identical(other.turbidity, turbidity) || other.turbidity == turbidity)&&(identical(other.conductivity, conductivity) || other.conductivity == conductivity)&&(identical(other.flowRate, flowRate) || other.flowRate == flowRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,sensorId,ph,turbidity,conductivity,flowRate);

@override
String toString() {
  return 'SensorRecordModel(timestamp: $timestamp, sensorId: $sensorId, ph: $ph, turbidity: $turbidity, conductivity: $conductivity, flowRate: $flowRate)';
}


}

/// @nodoc
abstract mixin class _$SensorRecordModelCopyWith<$Res> implements $SensorRecordModelCopyWith<$Res> {
  factory _$SensorRecordModelCopyWith(_SensorRecordModel value, $Res Function(_SensorRecordModel) _then) = __$SensorRecordModelCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, int sensorId, double? ph, double? turbidity, double? conductivity, double? flowRate
});




}
/// @nodoc
class __$SensorRecordModelCopyWithImpl<$Res>
    implements _$SensorRecordModelCopyWith<$Res> {
  __$SensorRecordModelCopyWithImpl(this._self, this._then);

  final _SensorRecordModel _self;
  final $Res Function(_SensorRecordModel) _then;

/// Create a copy of SensorRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? sensorId = null,Object? ph = freezed,Object? turbidity = freezed,Object? conductivity = freezed,Object? flowRate = freezed,}) {
  return _then(_SensorRecordModel(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,ph: freezed == ph ? _self.ph : ph // ignore: cast_nullable_to_non_nullable
as double?,turbidity: freezed == turbidity ? _self.turbidity : turbidity // ignore: cast_nullable_to_non_nullable
as double?,conductivity: freezed == conductivity ? _self.conductivity : conductivity // ignore: cast_nullable_to_non_nullable
as double?,flowRate: freezed == flowRate ? _self.flowRate : flowRate // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$SensorRawRecordModel {

 DateTime get timestamp; int get sensorId; Map<String, double> get metrics;
/// Create a copy of SensorRawRecordModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SensorRawRecordModelCopyWith<SensorRawRecordModel> get copyWith => _$SensorRawRecordModelCopyWithImpl<SensorRawRecordModel>(this as SensorRawRecordModel, _$identity);

  /// Serializes this SensorRawRecordModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SensorRawRecordModel&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&const DeepCollectionEquality().equals(other.metrics, metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,sensorId,const DeepCollectionEquality().hash(metrics));

@override
String toString() {
  return 'SensorRawRecordModel(timestamp: $timestamp, sensorId: $sensorId, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class $SensorRawRecordModelCopyWith<$Res>  {
  factory $SensorRawRecordModelCopyWith(SensorRawRecordModel value, $Res Function(SensorRawRecordModel) _then) = _$SensorRawRecordModelCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, int sensorId, Map<String, double> metrics
});




}
/// @nodoc
class _$SensorRawRecordModelCopyWithImpl<$Res>
    implements $SensorRawRecordModelCopyWith<$Res> {
  _$SensorRawRecordModelCopyWithImpl(this._self, this._then);

  final SensorRawRecordModel _self;
  final $Res Function(SensorRawRecordModel) _then;

/// Create a copy of SensorRawRecordModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? sensorId = null,Object? metrics = null,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [SensorRawRecordModel].
extension SensorRawRecordModelPatterns on SensorRawRecordModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SensorRawRecordModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SensorRawRecordModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SensorRawRecordModel value)  $default,){
final _that = this;
switch (_that) {
case _SensorRawRecordModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SensorRawRecordModel value)?  $default,){
final _that = this;
switch (_that) {
case _SensorRawRecordModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  int sensorId,  Map<String, double> metrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SensorRawRecordModel() when $default != null:
return $default(_that.timestamp,_that.sensorId,_that.metrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  int sensorId,  Map<String, double> metrics)  $default,) {final _that = this;
switch (_that) {
case _SensorRawRecordModel():
return $default(_that.timestamp,_that.sensorId,_that.metrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  int sensorId,  Map<String, double> metrics)?  $default,) {final _that = this;
switch (_that) {
case _SensorRawRecordModel() when $default != null:
return $default(_that.timestamp,_that.sensorId,_that.metrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SensorRawRecordModel implements SensorRawRecordModel {
  const _SensorRawRecordModel({required this.timestamp, required this.sensorId, required final  Map<String, double> metrics}): _metrics = metrics;
  factory _SensorRawRecordModel.fromJson(Map<String, dynamic> json) => _$SensorRawRecordModelFromJson(json);

@override final  DateTime timestamp;
@override final  int sensorId;
 final  Map<String, double> _metrics;
@override Map<String, double> get metrics {
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metrics);
}


/// Create a copy of SensorRawRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SensorRawRecordModelCopyWith<_SensorRawRecordModel> get copyWith => __$SensorRawRecordModelCopyWithImpl<_SensorRawRecordModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SensorRawRecordModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SensorRawRecordModel&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.sensorId, sensorId) || other.sensorId == sensorId)&&const DeepCollectionEquality().equals(other._metrics, _metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,sensorId,const DeepCollectionEquality().hash(_metrics));

@override
String toString() {
  return 'SensorRawRecordModel(timestamp: $timestamp, sensorId: $sensorId, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class _$SensorRawRecordModelCopyWith<$Res> implements $SensorRawRecordModelCopyWith<$Res> {
  factory _$SensorRawRecordModelCopyWith(_SensorRawRecordModel value, $Res Function(_SensorRawRecordModel) _then) = __$SensorRawRecordModelCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, int sensorId, Map<String, double> metrics
});




}
/// @nodoc
class __$SensorRawRecordModelCopyWithImpl<$Res>
    implements _$SensorRawRecordModelCopyWith<$Res> {
  __$SensorRawRecordModelCopyWithImpl(this._self, this._then);

  final _SensorRawRecordModel _self;
  final $Res Function(_SensorRawRecordModel) _then;

/// Create a copy of SensorRawRecordModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? sensorId = null,Object? metrics = null,}) {
  return _then(_SensorRawRecordModel(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,sensorId: null == sensorId ? _self.sensorId : sensorId // ignore: cast_nullable_to_non_nullable
as int,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}

// dart format on
