// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SensorRecordModel _$SensorRecordModelFromJson(Map<String, dynamic> json) =>
    _SensorRecordModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      sensorId: (json['sensorId'] as num).toInt(),
      ph: (json['ph'] as num?)?.toDouble(),
      turbidity: (json['turbidity'] as num?)?.toDouble(),
      conductivity: (json['conductivity'] as num?)?.toDouble(),
      flowRate: (json['flowRate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SensorRecordModelToJson(_SensorRecordModel instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'sensorId': instance.sensorId,
      'ph': instance.ph,
      'turbidity': instance.turbidity,
      'conductivity': instance.conductivity,
      'flowRate': instance.flowRate,
    };

_SensorRawRecordModel _$SensorRawRecordModelFromJson(
  Map<String, dynamic> json,
) => _SensorRawRecordModel(
  timestamp: DateTime.parse(json['timestamp'] as String),
  sensorId: (json['sensorId'] as num).toInt(),
  metrics: (json['metrics'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
);

Map<String, dynamic> _$SensorRawRecordModelToJson(
  _SensorRawRecordModel instance,
) => <String, dynamic>{
  'timestamp': instance.timestamp.toIso8601String(),
  'sensorId': instance.sensorId,
  'metrics': instance.metrics,
};
