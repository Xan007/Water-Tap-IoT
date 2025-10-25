import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_alert_model.freezed.dart';
part 'sensor_alert_model.g.dart';

@freezed
abstract class SensorAlertModel with _$SensorAlertModel {
  const factory SensorAlertModel({
    required int? id,
    required int sensorId,
    required String description,
    required String severity,

    @Default(true)
    bool active,
  }) = _SensorAlertModel;

  factory SensorAlertModel.fromJson(Map<String, dynamic> json) =>
      _$SensorAlertModelFromJson(json);
}