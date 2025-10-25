// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_alert_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SensorAlertModel _$SensorAlertModelFromJson(Map<String, dynamic> json) =>
    _SensorAlertModel(
      id: (json['id'] as num?)?.toInt(),
      sensorId: (json['sensorId'] as num).toInt(),
      description: json['description'] as String,
      severity: json['severity'] as String,
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$SensorAlertModelToJson(_SensorAlertModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sensorId': instance.sensorId,
      'description': instance.description,
      'severity': instance.severity,
      'active': instance.active,
    };
